import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/core/services/location/location_local_storage.dart';
import 'package:hris_flutter/core/services/location/location_service.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
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
  })  : _locationService = locationService ?? LocationService(),
        _localStorage = localStorage ?? LocationLocalStorage.instance,
        _trackingRepository = trackingRepository ?? TrackingRepositoryImpl();

  LocationTrackingService.withDependencies({
    LocationService? locationService,
    LocationLocalStorage? localStorage,
    TrackingRepository? trackingRepository,
  })  : _locationService = locationService ?? LocationService(),
        _localStorage = localStorage ?? LocationLocalStorage.instance,
        _trackingRepository = trackingRepository ?? TrackingRepositoryImpl();

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

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Timer? _flushTimer;

  Position? _lastRecordedPosition;
  DateTime? _lastRecordedTime;
  Future<void>? _activeFlushFuture;

  /// Memulai pemantauan presensi harian setelah Clock-In berhasil
  void startAttendanceTracking({
    required String attendanceId,
    int? intervalMinutes,
  }) {
    _activeAttendanceId = attendanceId;
    if (intervalMinutes != null && intervalMinutes > 0) {
      _attendanceIntervalMinutes = intervalMinutes;
    }

    _transitionTo(TrackingState.inAttendance);
  }

  /// Eskalasi ke pelacakan dinas lapangan (Prioritas 1: 1-3 menit)
  void elevateToActivityTracking({
    required String activityId,
    required String activityTitle,
    int? intervalMinutes,
  }) {
    _activeActivityId = activityId;
    _activeActivityTitle = activityTitle;
    if (intervalMinutes != null && intervalMinutes > 0) {
      _activityIntervalMinutes = intervalMinutes;
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

  /// Mengelola perpindahan State Machine dan restart stream GPS sesuai konfigurasi
  void _transitionTo(TrackingState newState) {
    _state = newState;
    debugPrint('📍 [LocationTrackingService] State changed to: $_state');

    _cancelSubscriptions();

    if (_state == TrackingState.idle) {
      _flushTimer?.cancel();
      _flushTimer = null;
      return;
    }

    _startLocationUpdates();
    _startGpsStatusListener();
    _startPeriodicFlush();

    // Segera ambil dan kirim koordinat awal tanpa menunggu interval stream pasif
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

    final isActivity = _state == TrackingState.onActivity;
    final intervalMinutes =
        isActivity ? _activityIntervalMinutes : _attendanceIntervalMinutes;

    final String notificationText = isActivity
        ? 'HRIS memantau rute dinas: ${_activeActivityTitle ?? 'Tugas Lapangan'}'
        : 'HRIS memantau lokasi kerja aktif Anda';

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: isActivity ? LocationAccuracy.high : LocationAccuracy.medium,
        distanceFilter: 10,
        intervalDuration: Duration(minutes: intervalMinutes),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Pelacakan Lokasi Kerja Aktif',
          notificationText: notificationText,
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: isActivity ? LocationAccuracy.high : LocationAccuracy.medium,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        distanceFilter: 10,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
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
    } catch (e) {
      debugPrint('⚠️ [LocationTrackingService] Gagal memulai stream lokasi: $e');
    }
  }

  /// Handler setiap kali sensor GPS mendeteksi titik koordinat baru
  Future<void> _onPositionReceived(Position position, {bool force = false}) async {
    if (_state == TrackingState.idle) return;

    // Evaluasi sensor throttling saat karyawan diam di meja kerja (dilewati jika force: true)
    if (!force) {
      final throttled = _locationService.shouldThrottle(
        current: position,
        previous: _lastRecordedPosition,
        previousTime: _lastRecordedTime,
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
      heading: position.heading,
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
      final battery = await _locationService.getBatteryLevel();

      final point = TrackingLocationPoint(
        id: 'gps_off_${DateTime.now().millisecondsSinceEpoch}',
        latitude: lastPos?.latitude ?? 0.0,
        longitude: lastPos?.longitude ?? 0.0,
        accuracy: lastPos?.accuracy,
        speed: 0.0,
        heading: lastPos?.heading,
        altitude: lastPos?.altitude,
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
      final battery = await _locationService.getBatteryLevel();

      final point = TrackingLocationPoint(
        id: 'gps_on_${DateTime.now().millisecondsSinceEpoch}',
        latitude: currentPos?.latitude ?? _lastRecordedPosition?.latitude ?? 0.0,
        longitude: currentPos?.longitude ?? _lastRecordedPosition?.longitude ?? 0.0,
        accuracy: currentPos?.accuracy ?? _lastRecordedPosition?.accuracy,
        speed: currentPos?.speed ?? 0.0,
        heading: currentPos?.heading,
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
    _flushTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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
      final batches = await _localStorage.getBatchesForUpload(limit: 50);
      if (batches.isEmpty) {
        return;
      }

      for (final payload in batches) {
        try {
          await _trackingRepository.uploadBatch(payload);

          // Hapus titik yang sukses diterima oleh server (201 Created)
          final successIds = payload.locations.map((e) => e.id).toList();
          await _localStorage.removePoints(successIds);
        } on SessionClosedException catch (e) {
          debugPrint('🚨 [LocationTrackingService] SessionClosedException: ${e.message}');
          // Protokol penanganan sesi ditutup di server
          await _localStorage.purgeQueueForReference(e.referenceId);

          if (e.sourceType == 'attendance') {
            stopAllTracking();
          } else if (e.sourceType == 'activity') {
            fallbackToAttendanceTracking();
          }
        } catch (e) {
          debugPrint('⚠️ [LocationTrackingService.flushPendingQueue] Upload gagal, ditahan di lokal: $e');
          // Jangan hapus data lokal, tunggu flushing berikutnya
          break;
        }
      }
    } finally {
      _activeFlushFuture = null;
    }
  }

  /// Sinkronisasi dengan konfigurasi dan sesi aktif di server (GET /tracking/config)
  /// Dipanggil saat aplikasi dibuka kembali atau selesai login untuk memulihkan sesi
  Future<void> syncWithServerConfig() async {
    if (!_isServicesBindingInitialized) {
      return;
    }
    try {
      final token = await SecureStorageService.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final config = await _trackingRepository.getTrackingConfig();

      if (!config.hasAccess || !config.isTrackingEnabled) {
        debugPrint('ℹ️ [LocationTrackingService] Pelacakan dinonaktifkan oleh perusahaan/tenant.');
        if (_state != TrackingState.idle) {
          stopAllTracking();
        }
        return;
      }

      _attendanceIntervalMinutes = config.attendance.intervalMinutes;
      _activityIntervalMinutes = config.activity.intervalMinutes;

      final activeAttId = config.attendance.activeSessionId;
      final activeActId = config.activity.activeSessionId;

      if (activeActId != null && activeActId.isNotEmpty) {
        _activeAttendanceId = activeAttId;
        elevateToActivityTracking(
          activityId: activeActId,
          activityTitle: 'Tugas Lapangan Aktif',
          intervalMinutes: _activityIntervalMinutes,
        );
      } else if (activeAttId != null && activeAttId.isNotEmpty) {
        startAttendanceTracking(
          attendanceId: activeAttId,
          intervalMinutes: _attendanceIntervalMinutes,
        );
      } else if (_state != TrackingState.idle) {
        stopAllTracking();
      }
    } catch (e) {
      debugPrint('ℹ️ [LocationTrackingService.syncWithServerConfig] $e');
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
