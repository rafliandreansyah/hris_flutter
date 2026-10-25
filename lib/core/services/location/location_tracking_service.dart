import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/core/services/location/location_local_storage.dart';
import 'package:hris_flutter/core/services/location/location_service.dart';
import 'package:hris_flutter/core/services/location/tracking_session_store.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:hris_flutter/features/tracking/domain/repositories/tracking_repository.dart';

/// State Machine Layanan Pelacakan Lokasi (Mobile Tracking State)
enum TrackingState {
  /// Belum Clock-In atau sudah Clock-Out. Service mati.
  idle,

  /// Presensi aktif: interval normal 10 menit, notifikasi jam kerja reguler.
  inAttendance,

  /// Tugas dinas lapangan: eskalasi ke presisi tinggi (1-3 menit).
  onActivity,

  /// Fallback: tugas dinas selesai/batal, otomatis kembali ke presensi reguler.
  fallback,
}

/// Koordinator Tunggal Pelacakan Lokasi Mobile (Single Unified Tracking Coordinator).
/// Mengelola Android Foreground Service dengan notifikasi persisten di status bar,
/// iOS CoreLocation background mode, buffering antrean offline, dan prioritas ganda.
class LocationTrackingService {
  static LocationTrackingService _instance =
      LocationTrackingService._internal();
  static LocationTrackingService get instance => _instance;

  @visibleForTesting
  static void setMockInstance(LocationTrackingService mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = LocationTrackingService._internal();
  }

  @visibleForTesting
  static bool enableNativeStream =
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  LocationTrackingService._internal({
    LocationService? locationService,
    LocationLocalStorage? localStorage,
    TrackingRepository? trackingRepository,
    TrackingSessionStore? sessionStore,
  })  : _locationService = locationService ?? LocationService(),
        _localStorage = localStorage ?? LocationLocalStorage.instance,
        _trackingRepository = trackingRepository ?? TrackingRepositoryImpl(),
        _sessionStore = sessionStore ?? TrackingSessionStore();

  LocationTrackingService.withDependencies({
    LocationService? locationService,
    LocationLocalStorage? localStorage,
    TrackingRepository? trackingRepository,
    TrackingSessionStore? sessionStore,
  })  : _locationService = locationService ?? LocationService(),
        _localStorage = localStorage ?? LocationLocalStorage.instance,
        _trackingRepository = trackingRepository ?? TrackingRepositoryImpl(),
        _sessionStore = sessionStore ?? TrackingSessionStore();

  factory LocationTrackingService({
    LocationService? locationService,
    LocationLocalStorage? localStorage,
    TrackingRepository? trackingRepository,
  }) {
    return _instance;
  }

  final LocationService _locationService;
  final LocationLocalStorage _localStorage;
  final TrackingRepository _trackingRepository;
  final TrackingSessionStore _sessionStore;

  TrackingState _state = TrackingState.idle;
  TrackingState get state => _state;

  String? _activeAttendanceId;
  String? get activeAttendanceId => _activeAttendanceId;

  String? _activeActivityId;
  String? get activeActivityId => _activeActivityId;

  String? _activeActivityTitle;
  String? get activeActivityTitle => _activeActivityTitle;

  int _attendanceIntervalMinutes = 10;
  int _activityIntervalMinutes = 3;
  int _attendanceIntervalSeconds = 600;
  int _activityIntervalSeconds = 180;

  int get activeIntervalSeconds => _state == TrackingState.onActivity
      ? _activityIntervalSeconds
      : _attendanceIntervalSeconds;

  /// Kebijakan terakhir dari server (GET /tracking/config). Null = belum disinkronkan,
  /// dalam kondisi itu pelacakan tetap diizinkan (perilaku lama) sampai config diterima.
  bool? _trackingAllowed;
  bool? _attendancePolicyEnabled;
  bool? _activityPolicyEnabled;

  static const int _minIntervalSeconds = 10;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Timer? _flushTimer;
  Timer? _fastIntervalTimer;

  Position? _lastRecordedPosition;
  DateTime? _lastRecordedTime;
  Future<void>? _activeFlushFuture;

  /// Memulai pemantauan presensi harian setelah Clock-In berhasil
  void startAttendanceTracking({
    required String attendanceId,
    int? intervalMinutes,
    int? intervalSeconds,
  }) {
    if (_trackingAllowed == false || _attendancePolicyEnabled == false) {
      debugPrint('ℹ️ [LocationTrackingService] Pelacakan presensi dinonaktifkan perusahaan, tidak dimulai.');
      return;
    }
    _activeAttendanceId = attendanceId;
    if (intervalMinutes != null && intervalMinutes > 0) {
      _attendanceIntervalMinutes = intervalMinutes;
      _attendanceIntervalSeconds = intervalMinutes * 60;
    }
    if (intervalSeconds != null && intervalSeconds > 0) {
      _attendanceIntervalSeconds = intervalSeconds;
      _attendanceIntervalMinutes = (intervalSeconds / 60).ceil().clamp(1, 1440);
    }

    _transitionTo(TrackingState.inAttendance);
  }

  /// Eskalasi ke pelacakan dinas lapangan (Prioritas 1: 1-3 menit)
  void elevateToActivityTracking({
    required String activityId,
    required String activityTitle,
    int? intervalMinutes,
    int? intervalSeconds,
  }) {
    if (_trackingAllowed == false || _activityPolicyEnabled == false) {
      debugPrint('ℹ️ [LocationTrackingService] Pelacakan aktivitas dinonaktifkan perusahaan, tidak dimulai.');
      return;
    }
    _activeActivityId = activityId;
    _activeActivityTitle = activityTitle;
    if (intervalMinutes != null && intervalMinutes > 0) {
      _activityIntervalMinutes = intervalMinutes;
      _activityIntervalSeconds = intervalMinutes * 60;
    }
    if (intervalSeconds != null && intervalSeconds > 0) {
      _activityIntervalSeconds = intervalSeconds;
      _activityIntervalMinutes = (intervalSeconds / 60).ceil().clamp(1, 1440);
    }

    _transitionTo(TrackingState.onActivity);
  }

  /// De-eskalasi otomatis saat tugas dinas selesai atau dibatalkan (Graceful Fallback)
  void fallbackToAttendanceTracking() {
    _activeActivityId = null;
    _activeActivityTitle = null;

    if (_activeAttendanceId != null && _activeAttendanceId!.isNotEmpty) {
      _transitionTo(TrackingState.inAttendance);
    } else {
      stopAllTracking();
    }
  }

  /// Penghentian total pelacakan (Full Stop saat Clock-Out)
  void stopAllTracking() {
    _activeAttendanceId = null;
    _activeActivityId = null;
    _activeActivityTitle = null;
    _lastRecordedPosition = null;
    _lastRecordedTime = null;

    _transitionTo(TrackingState.idle);
  }

  /// Dipanggil saat logout / sesi kedaluwarsa: hentikan pelacakan dan buang antrean lokal
  /// agar titik milik pengguna lama tidak terunggah memakai token pengguna berikutnya.
  Future<void> stopAndClearQueue() async {
    stopAllTracking();
    _trackingAllowed = null;
    _attendancePolicyEnabled = null;
    _activityPolicyEnabled = null;
    try {
      await _localStorage.clearAll();
    } catch (e) {
      debugPrint('⚠️ [LocationTrackingService.stopAndClearQueue] $e');
    }
  }

  /// Mengelola perpindahan State Machine dan restart stream GPS sesuai konfigurasi
  void _transitionTo(TrackingState newState) {
    _state = newState;
    debugPrint('📍 [LocationTrackingService] State changed to: $_state');

    _cancelSubscriptions();

    if (_state == TrackingState.idle) {
      _flushTimer?.cancel();
      _flushTimer = null;
      unawaited(_sessionStore.clear());
      return;
    }

    unawaited(_sessionStore.save(TrackingSessionSnapshot(
      onActivity: _state == TrackingState.onActivity,
      attendanceId: _activeAttendanceId,
      activityId: _activeActivityId,
      activityTitle: _activeActivityTitle,
      attendanceIntervalSeconds: _attendanceIntervalSeconds,
      activityIntervalSeconds: _activityIntervalSeconds,
    )));

    _startLocationUpdates();
    _startGpsStatusListener();
    _startPeriodicFlush();

    unawaited(_recordInitialPosition());
  }

  /// Mengambil dan merekam titik lokasi awal secara instan begitu sesi presensi/aktivitas dimulai
  Future<void> _recordInitialPosition({bool bypassNativeCheck = false}) async {
    if ((!enableNativeStream && !bypassNativeCheck) ||
        !_isServicesBindingInitialized) {
      return;
    }

    try {
      final currentReferenceId = _state == TrackingState.onActivity
          ? _activeActivityId
          : _activeAttendanceId;

      if (currentReferenceId == null || currentReferenceId.isEmpty) {
        return;
      }

      final isActivity = _state == TrackingState.onActivity;
      final position = await _locationService.getCurrentPosition(
            accuracy:
                isActivity ? LocationAccuracy.high : LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          ) ??
          _lastRecordedPosition ??
          await _locationService.getLastKnownPosition();

      if (position != null && _state != TrackingState.idle) {
        await _onPositionReceived(position, force: true);
      }
    } catch (e) {
      debugPrint(
          'ℹ️ [LocationTrackingService._recordInitialPosition] Gagal mengambil koordinat awal: $e');
    }
  }

  void _cancelSubscriptions() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    _fastIntervalTimer?.cancel();
    _fastIntervalTimer = null;
  }

  bool get _isServicesBindingInitialized {
    try {
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Menyalakan Foreground Service & listener sensor GPS
  void _startLocationUpdates() {
    if (!enableNativeStream || !_isServicesBindingInitialized) {
      debugPrint('ℹ️ [LocationTrackingService] Native location stream bypassed.');
      return;
    }

    // Batalkan listener lama agar restart (mis. GPS dimatikan lalu dinyalakan) tidak
    // menyisakan subscription yatim yang menduplikasi titik dan menahan foreground service.
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _fastIntervalTimer?.cancel();
    _fastIntervalTimer = null;

    final isActivity = _state == TrackingState.onActivity;
    final intervalSecs = activeIntervalSeconds;
    final isFastTestingInterval = intervalSecs < 60;

    final String notificationText = isActivity
        ? 'Oasish merekam rute dinas: ${_activeActivityTitle ?? 'Tugas Lapangan'}'
        : 'Oasish merekam lokasi kerja selama Anda clock-in';

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: (isActivity || isFastTestingInterval)
            ? LocationAccuracy.high
            : LocationAccuracy.medium,
        distanceFilter: isFastTestingInterval ? 0 : 10,
        intervalDuration: Duration(seconds: intervalSecs),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Pelacakan Lokasi Kerja Aktif',
          notificationText: notificationText,
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: (isActivity || isFastTestingInterval)
            ? LocationAccuracy.high
            : LocationAccuracy.medium,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        distanceFilter: isFastTestingInterval ? 0 : 10,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: isFastTestingInterval ? 0 : 10,
      );
    }

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionReceived,
        onError: (error) {
          debugPrint('⚠️ [LocationTrackingService.getPositionStream] $error');
        },
      );

      _fastIntervalTimer?.cancel();
      if (isFastTestingInterval) {
        _fastIntervalTimer = Timer.periodic(
          Duration(seconds: intervalSecs),
          (_) {
            if (_state != TrackingState.idle) {
              unawaited(_recordInitialPosition());
            }
          },
        );
      } else {
        // Heartbeat: distanceFilter 10 m membuat karyawan yang diam tidak mengirim titik sama
        // sekali sehingga terlihat offline. Rekam titik bila sudah melewati satu interval tanpa titik baru.
        _fastIntervalTimer = Timer.periodic(
          Duration(seconds: intervalSecs),
          (_) {
            if (_state == TrackingState.idle) return;
            final last = _lastRecordedTime;
            final dueAfter = Duration(seconds: (intervalSecs * 0.9).floor());
            if (last == null || DateTime.now().difference(last) >= dueAfter) {
              unawaited(_recordInitialPosition());
            }
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ [LocationTrackingService] Gagal memulai stream lokasi: $e');
    }
  }

  /// Handler setiap kali sensor GPS mendeteksi titik koordinat baru
  Future<void> _onPositionReceived(Position position, {bool force = false}) async {
    if (_state == TrackingState.idle) return;

    if (!force) {
      final throttled = _locationService.shouldThrottle(
        current: position,
        previous: _lastRecordedPosition,
        previousTime: _lastRecordedTime,
        minIntervalSeconds: activeIntervalSeconds,
      );

      if (throttled) {
        debugPrint('ℹ️ [LocationTrackingService] Titik di-throttle (karyawan diam).');
        return;
      }
    }

    final currentSourceType =
        _state == TrackingState.onActivity ? 'activity' : 'attendance';
    final currentReferenceId = _state == TrackingState.onActivity
        ? _activeActivityId
        : _activeAttendanceId;

    if (currentReferenceId == null || currentReferenceId.isEmpty) {
      return;
    }

    final battery = await _locationService.getBatteryLevel();
    final pointId =
        '${DateTime.now().millisecondsSinceEpoch}_${position.latitude.toStringAsFixed(4)}';

    final point = TrackingLocationPoint(
      id: pointId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading >= 0 ? position.heading : null,
      altitude: position.altitude,
      batteryLevel: battery,
      isMock: _locationService.isMockLocation(position),
      isGpsOff: false,
      recordedAt: position.timestamp,
    );

    _lastRecordedPosition = position;
    _lastRecordedTime = DateTime.now();

    // 1. Simpan ke buffer lokal (Store-then-Forward)
    await _localStorage.enqueuePoint(
      point: point,
      sourceType: currentSourceType,
      referenceId: currentReferenceId,
    );

    // 2. Picu pengiriman jika koneksi siap
    unawaited(flushPendingQueue());
  }

  /// Listener jika pengguna mematikan atau menyalakan switch GPS (Location Services) di ponsel
  void _startGpsStatusListener() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;

    if (!enableNativeStream || !_isServicesBindingInitialized) {
      return;
    }

    try {
      _serviceStatusSubscription =
          Geolocator.getServiceStatusStream().listen((ServiceStatus status) async {
        await handleGpsStatusChange(status);
      });
    } catch (e) {
      debugPrint('⚠️ [LocationTrackingService.getServiceStatusStream] $e');
    }
  }

  /// Memproses perubahan status GPS (disabled / enabled)
  @visibleForTesting
  Future<void> handleGpsStatusChange(ServiceStatus status) async {
    if (_state == TrackingState.idle) return;

    final currentSourceType =
        _state == TrackingState.onActivity ? 'activity' : 'attendance';
    final currentReferenceId = _state == TrackingState.onActivity
        ? _activeActivityId
        : _activeAttendanceId;

    if (currentReferenceId == null || currentReferenceId.isEmpty) return;

    if (status == ServiceStatus.disabled) {
      debugPrint('⚠️ [LocationTrackingService] Sensor GPS dimatikan oleh pengguna!');

      final lastPos = _lastRecordedPosition ??
          await _locationService.getLastKnownPosition();
      // Tanpa koordinat yang diketahui, titik "GPS mati" tidak dikirim (server menolak (0,0)
      // sebagai lokasi palsu); status akan terlihat dari tidak adanya titik baru.
      if (lastPos == null) return;
      final battery = await _locationService.getBatteryLevel();

      final point = TrackingLocationPoint(
        id: 'gps_off_${DateTime.now().millisecondsSinceEpoch}',
        latitude: lastPos.latitude,
        longitude: lastPos.longitude,
        accuracy: lastPos.accuracy,
        speed: 0.0,
        heading: lastPos.heading >= 0 ? lastPos.heading : null,
        altitude: lastPos.altitude,
        batteryLevel: battery,
        isMock: false,
        isGpsOff: true,
        recordedAt: DateTime.now(),
      );

      await _localStorage.enqueuePoint(
        point: point,
        sourceType: currentSourceType,
        referenceId: currentReferenceId,
      );

      unawaited(flushPendingQueue());
    } else if (status == ServiceStatus.enabled) {
      debugPrint('✅ [LocationTrackingService] Sensor GPS dinyalakan kembali oleh pengguna!');

      // 1. Re-initialize stream lokasi agar aktif kembali setelah sebelumnya terputus
      _startLocationUpdates();

      // 2. Ambil lokasi terbaru segera setelah GPS aktif
      final currentPos = await _locationService.getCurrentPosition(
            timeLimit: const Duration(seconds: 10),
          ) ??
          _lastRecordedPosition ??
          await _locationService.getLastKnownPosition();
      if (currentPos == null && _lastRecordedPosition == null) return;
      final battery = await _locationService.getBatteryLevel();

      final point = TrackingLocationPoint(
        id: 'gps_on_${DateTime.now().millisecondsSinceEpoch}',
        latitude: currentPos?.latitude ?? _lastRecordedPosition?.latitude ?? 0.0,
        longitude: currentPos?.longitude ?? _lastRecordedPosition?.longitude ?? 0.0,
        accuracy: currentPos?.accuracy ?? _lastRecordedPosition?.accuracy,
        speed: currentPos?.speed ?? 0.0,
        heading: (currentPos?.heading ?? -1) >= 0 ? currentPos?.heading : null,
        altitude: currentPos?.altitude,
        batteryLevel: battery,
        isMock: currentPos != null ? _locationService.isMockLocation(currentPos) : false,
        isGpsOff: false,
        recordedAt: DateTime.now(),
      );

      if (currentPos != null) {
        _lastRecordedPosition = currentPos;
        _lastRecordedTime = DateTime.now();
      }

      await _localStorage.enqueuePoint(
        point: point,
        sourceType: currentSourceType,
        referenceId: currentReferenceId,
      );

      unawaited(flushPendingQueue());
    }
  }

  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (!enableNativeStream) return;
    final flushSecs = activeIntervalSeconds < 60 ? activeIntervalSeconds : 60;
    _flushTimer = Timer.periodic(Duration(seconds: flushSecs), (_) {
      flushPendingQueue();
    });
  }

  /// Mengunggah kumpulan titik dari antrean lokal ke API POST /tracking/batch
  Future<void> flushPendingQueue() {
    if (_activeFlushFuture != null) {
      return _activeFlushFuture!;
    }
    final future = _performFlush();
    _activeFlushFuture = future;
    return future;
  }

  Future<void> _performFlush() async {
    try {
      // Ulangi sampai antrean habis (tiap putaran maksimal 50 titik) dengan batas pengaman.
      for (var round = 0; round < 20; round++) {
        final batches = await _localStorage.getBatchesForUpload(limit: 50);
        if (batches.isEmpty) return;

        var transientFailure = false;
        for (final payload in batches) {
          try {
            await _trackingRepository.uploadBatch(payload);

            final successIds = payload.locations.map((e) => e.id).toList();
            await _localStorage.removePoints(successIds);
          } on SessionClosedException catch (e) {
            debugPrint('🚨 [LocationTrackingService] SessionClosedException: ${e.message}');
            await _localStorage.purgeQueueForReference(e.referenceId);

            // Titik sisa dari sesi lama tidak boleh menghentikan sesi yang sedang berjalan.
            if (e.sourceType == 'attendance' && e.referenceId == _activeAttendanceId) {
              stopAllTracking();
            } else if (e.sourceType == 'activity' && e.referenceId == _activeActivityId) {
              fallbackToAttendanceTracking();
            }
          } catch (e) {
            if (_isPermanentUploadFailure(e)) {
              // Ditolak server secara permanen (mis. dinonaktifkan, sesi tidak ada, validasi):
              // buang batch ini agar tidak memblokir antrean di belakangnya.
              debugPrint('🗑️ [LocationTrackingService] Batch ditolak permanen, dibuang: $e');
              await _localStorage.removePoints(payload.locations.map((p) => p.id).toList());
              if (e is ApiException && (e.code == 'TRACKING_DISABLED' || e.code == 'NO_SUBSCRIPTION')) {
                stopAllTracking();
              }
            } else {
              debugPrint('⚠️ [LocationTrackingService.flushPendingQueue] Upload gagal, ditahan di lokal: $e');
              transientFailure = true;
              break;
            }
          }
        }
        if (transientFailure) return;
      }
    } finally {
      _activeFlushFuture = null;
    }
  }

  /// 4xx selain 401 (token) / 408 (timeout) / 429 (rate limit) berarti server tidak akan
  /// pernah menerima batch tersebut; 5xx dan kegagalan jaringan layak dicoba ulang.
  bool _isPermanentUploadFailure(Object error) {
    if (error is! ApiException) return false;
    final status = error.statusCode;
    if (status == null) return false;
    if (status == 401 || status == 408 || status == 429) return false;
    return status >= 400 && status < 500;
  }

  /// Dipanggil saat app dibuka (termasuk dibangunkan iOS di background atau dari notifikasi
  /// "ketuk untuk melanjutkan" setelah reboot): lanjutkan sesi tersimpan, lalu cocokkan dengan server.
  Future<void> restoreOnAppStart() async {
    try {
      final token = await SecureStorageService.instance.getAccessToken();
      if (token == null || token.isEmpty) return;
      await restoreFromLocal();
    } catch (e) {
      debugPrint('ℹ️ [LocationTrackingService.restoreOnAppStart] $e');
    }
    await syncWithServerConfig();
  }

  /// Memulai ulang stream GPS untuk sesi yang sedang aktif, mis. setelah izin lokasi yang
  /// hilang (reinstall / dicabut di Pengaturan) diberikan kembali.
  void restartActiveSession() {
    if (_state == TrackingState.idle) return;
    _transitionTo(_state);
  }

  /// Melanjutkan sesi terakhir dari penyimpanan lokal tanpa menunggu server (mis. offline).
  /// Server tetap sumber kebenaran: [syncWithServerConfig] menghentikan sesi yang sudah selesai.
  @visibleForTesting
  Future<void> restoreFromLocal() async {
    if (_state != TrackingState.idle) return;
    final snapshot = await _sessionStore.load();
    if (snapshot == null) return;

    final activityId = snapshot.activityId;
    final attendanceId = snapshot.attendanceId;
    if (snapshot.onActivity && activityId != null && activityId.isNotEmpty) {
      _activeAttendanceId = attendanceId;
      _attendanceIntervalSeconds = snapshot.attendanceIntervalSeconds;
      _attendanceIntervalMinutes =
          (_attendanceIntervalSeconds / 60).ceil().clamp(1, 1440);
      elevateToActivityTracking(
        activityId: activityId,
        activityTitle: snapshot.activityTitle ?? 'Tugas Lapangan Aktif',
        intervalSeconds: snapshot.activityIntervalSeconds,
      );
    } else if (attendanceId != null && attendanceId.isNotEmpty) {
      _activityIntervalSeconds = snapshot.activityIntervalSeconds;
      _activityIntervalMinutes =
          (_activityIntervalSeconds / 60).ceil().clamp(1, 1440);
      startAttendanceTracking(
        attendanceId: attendanceId,
        intervalSeconds: snapshot.attendanceIntervalSeconds,
      );
    } else {
      await _sessionStore.clear();
    }
  }

  /// Sinkronisasi dengan konfigurasi dan sesi aktif di server (GET /tracking/config)
  /// Dipanggil saat aplikasi dibuka kembali atau selesai login untuk memulihkan sesi
  Future<void> syncWithServerConfig() {
    // Satu sinkronisasi pada satu waktu; pemanggilan bersamaan (dashboard reload + resume) digabung.
    return _activeSyncFuture ??= _performSync().whenComplete(() => _activeSyncFuture = null);
  }

  Future<void>? _activeSyncFuture;

  Future<void> _performSync() async {
    if (!_isServicesBindingInitialized) {
      return;
    }
    try {
      final token = await SecureStorageService.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final config = await _trackingRepository.getTrackingConfig();
      applyTrackingConfig(config);
    } catch (e) {
      debugPrint('ℹ️ [LocationTrackingService.syncWithServerConfig] $e');
    }
  }

  /// Menerapkan konfigurasi dari server ke state machine (dipisah dari fetch agar bisa diuji).
  @visibleForTesting
  void applyTrackingConfig(TrackingConfigModel config) {
    _trackingAllowed = config.hasAccess && config.isTrackingEnabled;
    _attendancePolicyEnabled = config.attendance.enabled;
    _activityPolicyEnabled = config.activity.enabled;

    if (!config.hasAccess || !config.isTrackingEnabled) {
      debugPrint('ℹ️ [LocationTrackingService] Pelacakan dinonaktifkan oleh perusahaan/tenant.');
      if (_state != TrackingState.idle) {
        stopAllTracking();
      }
      return;
    }

    final prevAttendanceSeconds = _attendanceIntervalSeconds;
    final prevActivitySeconds = _activityIntervalSeconds;

    // Interval 0 dari server membuat Timer.periodic berputar tanpa jeda; beri batas bawah.
    _attendanceIntervalSeconds =
        config.attendance.intervalSeconds < _minIntervalSeconds
            ? _minIntervalSeconds
            : config.attendance.intervalSeconds;
    _activityIntervalSeconds =
        config.activity.intervalSeconds < _minIntervalSeconds
            ? _minIntervalSeconds
            : config.activity.intervalSeconds;
    _attendanceIntervalMinutes = (_attendanceIntervalSeconds / 60).ceil().clamp(1, 1440);
    _activityIntervalMinutes = (_activityIntervalSeconds / 60).ceil().clamp(1, 1440);

    final activeAttId = config.attendance.activeSessionId;
    final activeActId = config.activity.activeSessionId;

    // Idempoten: sesi, id, dan interval yang sama tidak perlu me-restart stream GPS
    // (restart menutup foreground service, merekam titik ekstra, dan mereset judul aktivitas).
    if (activeActId != null && activeActId.isNotEmpty) {
      if (_state == TrackingState.onActivity &&
          _activeActivityId == activeActId &&
          _activeAttendanceId == activeAttId &&
          prevActivitySeconds == _activityIntervalSeconds) {
        return;
      }
    } else if (activeAttId != null && activeAttId.isNotEmpty) {
      if (_state == TrackingState.inAttendance &&
          _activeAttendanceId == activeAttId &&
          prevAttendanceSeconds == _attendanceIntervalSeconds) {
        return;
      }
    }

    if (activeActId != null && activeActId.isNotEmpty) {
      _activeAttendanceId = activeAttId;
      elevateToActivityTracking(
        activityId: activeActId,
        activityTitle: 'Tugas Lapangan Aktif',
        intervalMinutes: _activityIntervalMinutes,
        intervalSeconds: _activityIntervalSeconds,
      );
    } else if (activeAttId != null && activeAttId.isNotEmpty) {
      startAttendanceTracking(
        attendanceId: activeAttId,
        intervalMinutes: _attendanceIntervalMinutes,
        intervalSeconds: _attendanceIntervalSeconds,
      );
    } else if (_state != TrackingState.idle) {
      stopAllTracking();
    }
  }

  /// Setter helper untuk testing
  @visibleForTesting
  void setSessionForTest({
    required TrackingState state,
    String? attendanceId,
    String? activityId,
    String? activityTitle,
  }) {
    _state = state;
    _activeAttendanceId = attendanceId;
    _activeActivityId = activityId;
    _activeActivityTitle = activityTitle;
  }

  /// Helper pengujian untuk memicu pengambilan koordinat awal
  @visibleForTesting
  Future<void> recordInitialPositionForTest() =>
      _recordInitialPosition(bypassNativeCheck: true);

  /// Helper pengujian untuk menyuntikkan titik koordinat
  @visibleForTesting
  Future<void> onPositionReceivedForTest(Position position, {bool force = false}) =>
      _onPositionReceived(position, force: force);
}
