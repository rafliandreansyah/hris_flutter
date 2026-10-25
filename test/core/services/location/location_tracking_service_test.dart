import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/services/location/location_local_storage.dart';
import 'package:hris_flutter/core/services/location/location_service.dart';
import 'package:hris_flutter/core/services/location/location_tracking_service.dart';
import 'package:hris_flutter/core/services/location/tracking_session_store.dart';
import 'package:hris_flutter/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';
import 'package:hris_flutter/features/tracking/domain/repositories/tracking_repository.dart';

class FakeLocationService extends LocationService {
  Position? mockPosition;
  int? mockBattery = 85;

  @override
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    return mockPosition;
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    return mockPosition;
  }

  @override
  Future<int?> getBatteryLevel() async {
    return mockBattery;
  }

  @override
  bool shouldThrottle({
    required Position current,
    Position? previous,
    DateTime? previousTime,
    int minIntervalSeconds = 600,
  }) {
    return false;
  }
}

Position createTestPosition({
  double latitude = -6.2,
  double longitude = 106.8,
  double accuracy = 5.0,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026, 10, 8, 12, 0, 0),
    accuracy: accuracy,
    altitude: 10.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

class FakeTrackingSessionStore extends TrackingSessionStore {
  TrackingSessionSnapshot? saved;
  int clearCalls = 0;

  @override
  Future<void> save(TrackingSessionSnapshot snapshot) async => saved = snapshot;

  @override
  Future<TrackingSessionSnapshot?> load() async => saved;

  @override
  Future<void> clear() async {
    clearCalls++;
    saved = null;
  }
}

class MockTrackingRepository implements TrackingRepository {
  final List<TrackingBatchPayload> uploadedBatches = [];
  bool shouldThrowNetworkError = false;
  SessionClosedException? sessionClosedExceptionToThrow;
  /// Error per referenceId (mis. ApiException 403) agar batch lain tetap bisa sukses.
  final Map<String, Object> errorByReference = {};
  TrackingConfigModel config = const TrackingConfigModel(
    hasAccess: true,
    isTrackingEnabled: true,
    attendance: TrackingSessionPolicy(enabled: true, intervalMinutes: 10),
    activity: TrackingSessionPolicy(enabled: true, intervalMinutes: 3),
  );

  @override
  Future<void> uploadBatch(TrackingBatchPayload payload) async {
    if (sessionClosedExceptionToThrow != null) {
      throw sessionClosedExceptionToThrow!;
    }
    final scoped = errorByReference[payload.referenceId];
    if (scoped != null) throw scoped;
    if (shouldThrowNetworkError) {
      throw Exception('Simulated Network Error');
    }
    uploadedBatches.add(payload);
  }

  @override
  Future<TrackingConfigModel> getTrackingConfig() async => config;

  @override
  Future<List<TrackingLogItem>> getTrackingLogs({
    required String sourceType,
    required String referenceId,
    String? employeeId,
    int? limit,
  }) async {
    return [];
  }

  @override
  Future<LiveTrackingResponse> getLiveTracking({
    String? companyId,
    String? departmentId,
    String? status,
    bool activeOnly = true,
    String? search,
  }) async {
    return LiveTrackingResponse.empty();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  LocationTrackingService.enableNativeStream = false;

  late Directory tempDir;
  late File tempFile;
  late LocationLocalStorage localStorage;
  late MockTrackingRepository mockRepo;
  late FakeLocationService fakeLocationService;
  late LocationTrackingService trackingService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tracking_service_test_');
    tempFile = File('${tempDir.path}/test_buffer.json');

    localStorage = LocationLocalStorage.instance;
    localStorage.customStoragePath = tempFile.path;

    mockRepo = MockTrackingRepository();
    fakeLocationService = FakeLocationService();
    trackingService = LocationTrackingService.withDependencies(
      locationService: fakeLocationService,
      localStorage: localStorage,
      trackingRepository: mockRepo,
    );
    LocationTrackingService.setMockInstance(trackingService);
  });

  tearDown(() {
    trackingService.stopAllTracking();
    LocationTrackingService.resetInstance();
    localStorage.customStoragePath = null;
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('LocationTrackingService State Machine Tests', () {
    test('initial state is idle', () {
      expect(trackingService.state, equals(TrackingState.idle));
      expect(trackingService.activeAttendanceId, isNull);
      expect(trackingService.activeActivityId, isNull);
    });

    test('startAttendanceTracking transitions to inAttendance state', () {
      trackingService.startAttendanceTracking(
        attendanceId: 'att-101',
        intervalMinutes: 10,
      );

      expect(trackingService.state, equals(TrackingState.inAttendance));
      expect(trackingService.activeAttendanceId, equals('att-101'));
      expect(trackingService.activeActivityId, isNull);
    });

    test('elevateToActivityTracking transitions to onActivity state preserving attendanceId', () {
      trackingService.startAttendanceTracking(attendanceId: 'att-101');
      trackingService.elevateToActivityTracking(
        activityId: 'act-202',
        activityTitle: 'Client Meeting',
        intervalMinutes: 3,
      );

      expect(trackingService.state, equals(TrackingState.onActivity));
      expect(trackingService.activeAttendanceId, equals('att-101'));
      expect(trackingService.activeActivityId, equals('act-202'));
      expect(trackingService.activeActivityTitle, equals('Client Meeting'));
    });

    test('fallbackToAttendanceTracking returns to inAttendance if attendance session is present', () {
      trackingService.startAttendanceTracking(attendanceId: 'att-101');
      trackingService.elevateToActivityTracking(
        activityId: 'act-202',
        activityTitle: 'Client Meeting',
      );

      trackingService.fallbackToAttendanceTracking();

      expect(trackingService.state, equals(TrackingState.inAttendance));
      expect(trackingService.activeAttendanceId, equals('att-101'));
      expect(trackingService.activeActivityId, isNull);
    });

    test('fallbackToAttendanceTracking stops tracking if no attendance session is present', () {
      trackingService.elevateToActivityTracking(
        activityId: 'act-isolated',
        activityTitle: 'Direct Activity',
      );

      trackingService.fallbackToAttendanceTracking();

      expect(trackingService.state, equals(TrackingState.idle));
      expect(trackingService.activeActivityId, isNull);
    });

    test('stopAllTracking stops all tracking and clears references', () {
      trackingService.startAttendanceTracking(attendanceId: 'att-101');
      trackingService.elevateToActivityTracking(
        activityId: 'act-202',
        activityTitle: 'Meeting',
      );

      trackingService.stopAllTracking();

      expect(trackingService.state, equals(TrackingState.idle));
      expect(trackingService.activeAttendanceId, isNull);
      expect(trackingService.activeActivityId, isNull);
    });
  });

  group('LocationTrackingService Flush & Offline Buffer Tests', () {
    test('flushPendingQueue uploads points and removes them on success', () async {
      final point1 = TrackingLocationPoint(
        id: 'p1',
        latitude: -6.2,
        longitude: 106.8,
        recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
      );
      final point2 = TrackingLocationPoint(
        id: 'p2',
        latitude: -6.21,
        longitude: 106.81,
        recordedAt: DateTime.utc(2026, 10, 7, 8, 5, 0),
      );

      await localStorage.enqueuePoint(
        point: point1,
        sourceType: 'attendance',
        referenceId: 'att-101',
      );
      await localStorage.enqueuePoint(
        point: point2,
        sourceType: 'attendance',
        referenceId: 'att-101',
      );

      expect(await localStorage.getQueueCount(), equals(2));

      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches.length, equals(1));
      expect(mockRepo.uploadedBatches.first.locations.length, equals(2));
      expect(await localStorage.getQueueCount(), equals(0));
    });

    test('flushPendingQueue keeps points in local buffer on network failure', () async {
      mockRepo.shouldThrowNetworkError = true;

      await localStorage.enqueuePoint(
        point: TrackingLocationPoint(
          id: 'p1',
          latitude: -6.2,
          longitude: 106.8,
          recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
        ),
        sourceType: 'attendance',
        referenceId: 'att-101',
      );

      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches, isEmpty);
      // Data remains in local queue for next flush attempt
      expect(await localStorage.getQueueCount(), equals(1));
    });

    test('flushPendingQueue on SessionClosedException purges queue and transitions state', () async {
      mockRepo.sessionClosedExceptionToThrow = const SessionClosedException(
        message: 'Shift attendance already closed',
        sourceType: 'attendance',
        referenceId: 'att-closed',
      );

      trackingService.startAttendanceTracking(attendanceId: 'att-closed');

      await localStorage.enqueuePoint(
        point: TrackingLocationPoint(
          id: 'p-orphan',
          latitude: -6.2,
          longitude: 106.8,
          recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
        ),
        sourceType: 'attendance',
        referenceId: 'att-closed',
      );

      expect(await localStorage.getQueueCount(), equals(1));

      await trackingService.flushPendingQueue();

      // Buffer purged for closed session
      expect(await localStorage.getQueueCount(), equals(0));
      // Attendance session terminated
      expect(trackingService.state, equals(TrackingState.idle));
    });
  });

  group('LocationTrackingService Hardening Tests', () {
    Future<void> enqueue(String id, String ref, {String source = 'attendance'}) {
      return localStorage.enqueuePoint(
        point: TrackingLocationPoint(
          id: id,
          latitude: -6.2,
          longitude: 106.8,
          recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
        ),
        sourceType: source,
        referenceId: ref,
      );
    }

    test('batch yang ditolak permanen (403) dibuang dan tidak memblokir batch di belakangnya', () async {
      mockRepo.errorByReference['ref-bad'] = const ApiException(
        message: 'Pelacakan dinonaktifkan',
        statusCode: 403,
      );
      await enqueue('p-bad', 'ref-bad');
      await enqueue('p-good', 'ref-good');

      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches.length, equals(1));
      expect(mockRepo.uploadedBatches.first.referenceId, equals('ref-good'));
      expect(await localStorage.getQueueCount(), equals(0));
    });

    test('kegagalan sementara (500) menahan titik di antrean untuk dicoba ulang', () async {
      mockRepo.errorByReference['ref-1'] = const ApiException(
        message: 'Server error',
        statusCode: 500,
      );
      await enqueue('p1', 'ref-1');

      await trackingService.flushPendingQueue();

      expect(await localStorage.getQueueCount(), equals(1));
    });

    test('401 tidak membuang titik (token akan di-refresh)', () async {
      mockRepo.errorByReference['ref-1'] = const ApiException(
        message: 'Unauthorized',
        statusCode: 401,
      );
      await enqueue('p1', 'ref-1');

      await trackingService.flushPendingQueue();

      expect(await localStorage.getQueueCount(), equals(1));
    });

    test('TRACKING_DISABLED menghentikan pelacakan setelah batch dibuang', () async {
      trackingService.startAttendanceTracking(attendanceId: 'att-1');
      mockRepo.errorByReference['att-1'] = const ApiException(
        message: 'dinonaktifkan',
        statusCode: 400,
        code: 'TRACKING_DISABLED',
      );
      await enqueue('p1', 'att-1');

      await trackingService.flushPendingQueue();

      expect(await localStorage.getQueueCount(), equals(0));
      expect(trackingService.state, equals(TrackingState.idle));
    });

    test('SESSION_CLOSED dari sesi lama tidak menghentikan sesi presensi yang sedang berjalan', () async {
      trackingService.startAttendanceTracking(attendanceId: 'att-today');
      mockRepo.sessionClosedExceptionToThrow = const SessionClosedException(
        message: 'closed',
        sourceType: 'attendance',
        referenceId: 'att-yesterday',
      );
      await enqueue('p-old', 'att-yesterday');

      await trackingService.flushPendingQueue();

      expect(await localStorage.getQueueCount(), equals(0));
      expect(trackingService.state, equals(TrackingState.inAttendance));
      expect(trackingService.activeAttendanceId, equals('att-today'));
    });

    test('stopAndClearQueue menghentikan pelacakan dan membuang antrean (logout)', () async {
      trackingService.startAttendanceTracking(attendanceId: 'att-1');
      await enqueue('p1', 'att-1');

      await trackingService.stopAndClearQueue();

      expect(trackingService.state, equals(TrackingState.idle));
      expect(await localStorage.getQueueCount(), equals(0));
    });

    test('perusahaan menonaktifkan pelacakan: sinkronisasi menghentikan dan start berikutnya ditolak', () async {
      mockRepo.config = const TrackingConfigModel(
        hasAccess: true,
        isTrackingEnabled: false,
        attendance: TrackingSessionPolicy(enabled: false, intervalMinutes: 10),
        activity: TrackingSessionPolicy(enabled: false, intervalMinutes: 3),
      );
      trackingService.startAttendanceTracking(attendanceId: 'att-1');

      trackingService.applyTrackingConfig(mockRepo.config);
      expect(trackingService.state, equals(TrackingState.idle));

      trackingService.startAttendanceTracking(attendanceId: 'att-2');
      expect(trackingService.state, equals(TrackingState.idle));
      expect(trackingService.activeAttendanceId, isNull);
    });

    test('applyTrackingConfig idempoten: sesi sama tidak me-restart, interval berubah memulai ulang', () {
      TrackingConfigModel cfg(int attMin) => TrackingConfigModel(
            hasAccess: true,
            isTrackingEnabled: true,
            attendance: TrackingSessionPolicy(
              enabled: true,
              intervalMinutes: attMin,
              activeSessionId: 'att-1',
            ),
            activity: const TrackingSessionPolicy(enabled: true, intervalMinutes: 3),
          );

      trackingService.applyTrackingConfig(cfg(10));
      expect(trackingService.state, equals(TrackingState.inAttendance));
      expect(trackingService.activeIntervalSeconds, equals(600));

      // Sama persis: tidak ada perubahan state / interval
      trackingService.applyTrackingConfig(cfg(10));
      expect(trackingService.state, equals(TrackingState.inAttendance));
      expect(trackingService.activeIntervalSeconds, equals(600));

      // Interval berubah: diterapkan
      trackingService.applyTrackingConfig(cfg(5));
      expect(trackingService.activeIntervalSeconds, equals(300));
    });

    test('interval 0 dari server dijepit ke batas bawah 10 detik', () {
      trackingService.applyTrackingConfig(const TrackingConfigModel(
        hasAccess: true,
        isTrackingEnabled: true,
        attendance: TrackingSessionPolicy(
          enabled: true,
          intervalMinutes: 0,
          intervalSeconds: 0,
          activeSessionId: 'att-1',
        ),
        activity: TrackingSessionPolicy(enabled: true, intervalMinutes: 3),
      ));
      expect(trackingService.activeIntervalSeconds, equals(10));
    });

    test('heading -1 (iOS) tidak dikirim ke API', () {
      final point = TrackingLocationPoint(
        id: 'p',
        latitude: -6.2,
        longitude: 106.8,
        heading: -1,
        recordedAt: DateTime.utc(2026, 10, 7),
      );
      final json = point.toApiJson();
      expect(json.containsKey('heading'), isFalse);
      expect(json['clientPointId'], equals('p'));
    });

    test('antrean dibatasi ke maxQueuedPoints dengan membuang titik tertua', () async {
      for (var i = 0; i < LocationLocalStorage.maxQueuedPoints + 3; i++) {
        await enqueue('p$i', 'ref-cap');
      }
      expect(await localStorage.getQueueCount(), equals(LocationLocalStorage.maxQueuedPoints));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('LocationTrackingService GPS Status Change Tests', () {
    test('handleGpsStatusChange(ServiceStatus.disabled) records point with isGpsOff: true and flushes', () async {
      trackingService.setSessionForTest(
        state: TrackingState.onActivity,
        activityId: 'act-gps-test',
        attendanceId: 'att-gps-test',
      );
      fakeLocationService.mockPosition = createTestPosition();

      await trackingService.handleGpsStatusChange(ServiceStatus.disabled);
      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches.length, equals(1));
      final uploaded = mockRepo.uploadedBatches.first;
      expect(uploaded.sourceType, equals('activity'));
      expect(uploaded.referenceId, equals('act-gps-test'));
      expect(uploaded.locations.length, equals(1));

      final point = uploaded.locations.first;
      expect(point.isGpsOff, isTrue);
      expect(point.id.startsWith('gps_off_'), isTrue);
    });

    test('handleGpsStatusChange(ServiceStatus.enabled) captures current position with isGpsOff: false and flushes', () async {
      trackingService.setSessionForTest(
        state: TrackingState.onActivity,
        activityId: 'act-gps-test',
        attendanceId: 'att-gps-test',
      );

      fakeLocationService.mockPosition = createTestPosition(
        latitude: -6.1754,
        longitude: 106.8272,
      );

      await trackingService.handleGpsStatusChange(ServiceStatus.enabled);
      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches.length, equals(1));
      final uploaded = mockRepo.uploadedBatches.first;
      expect(uploaded.sourceType, equals('activity'));
      expect(uploaded.referenceId, equals('act-gps-test'));
      expect(uploaded.locations.length, equals(1));

      final point = uploaded.locations.first;
      expect(point.isGpsOff, isFalse);
      expect(point.id.startsWith('gps_on_'), isTrue);
      expect(point.latitude, equals(-6.1754));
      expect(point.longitude, equals(106.8272));
    });

    test('GPS mati tanpa koordinat yang diketahui tidak mengantrekan titik (0,0)', () async {
      trackingService.setSessionForTest(
        state: TrackingState.inAttendance,
        attendanceId: 'att-gps-none',
      );
      fakeLocationService.mockPosition = null;

      await trackingService.handleGpsStatusChange(ServiceStatus.disabled);
      await trackingService.handleGpsStatusChange(ServiceStatus.enabled);

      expect(await localStorage.getQueueCount(), equals(0));
    });

    test('handleGpsStatusChange is ignored when state is idle', () async {
      expect(trackingService.state, equals(TrackingState.idle));

      await trackingService.handleGpsStatusChange(ServiceStatus.disabled);
      await trackingService.handleGpsStatusChange(ServiceStatus.enabled);
      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches, isEmpty);
      expect(await localStorage.getQueueCount(), equals(0));
    });
  });

  group('LocationTrackingService Initial Position Tests', () {
    test('recordInitialPosition immediately records and uploads first position', () async {
      trackingService.setSessionForTest(
        state: TrackingState.onActivity,
        activityId: 'act-init-1',
        attendanceId: 'att-init-1',
      );

      fakeLocationService.mockPosition = createTestPosition(
        latitude: -6.2222,
        longitude: 106.8888,
      );

      await trackingService.recordInitialPositionForTest();
      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches.length, equals(1));
      final uploaded = mockRepo.uploadedBatches.first;
      expect(uploaded.sourceType, equals('activity'));
      expect(uploaded.referenceId, equals('act-init-1'));
      expect(uploaded.locations.length, equals(1));

      final point = uploaded.locations.first;
      expect(point.isGpsOff, isFalse);
      expect(point.latitude, equals(-6.2222));
      expect(point.longitude, equals(106.8888));
    });

    test('onPositionReceived with force: true records position regardless of throttling', () async {
      trackingService.setSessionForTest(
        state: TrackingState.inAttendance,
        attendanceId: 'att-force-test',
      );

      final pos = createTestPosition(latitude: -6.3333, longitude: 106.7777);
      await trackingService.onPositionReceivedForTest(pos, force: true);
      await trackingService.flushPendingQueue();

      expect(mockRepo.uploadedBatches.length, equals(1));
      final uploaded = mockRepo.uploadedBatches.first;
      expect(uploaded.sourceType, equals('attendance'));
      expect(uploaded.referenceId, equals('att-force-test'));
      expect(uploaded.locations.length, equals(1));
      expect(uploaded.locations.first.latitude, equals(-6.3333));
      expect(uploaded.locations.first.longitude, equals(106.7777));
    });
  });

  group('Pemulihan sesi lokal (reboot / app dibuka ulang)', () {
    late FakeTrackingSessionStore store;
    late LocationTrackingService service;

    setUp(() {
      store = FakeTrackingSessionStore();
      service = LocationTrackingService.withDependencies(
        locationService: FakeLocationService(),
        localStorage: LocationLocalStorage.instance,
        trackingRepository: MockTrackingRepository(),
        sessionStore: store,
      );
    });

    tearDown(() => service.stopAllTracking());

    test('clock-in menyimpan snapshot, clock-out menghapusnya', () async {
      service.startAttendanceTracking(attendanceId: 'att-1', intervalSeconds: 300);
      await Future<void>.delayed(Duration.zero);

      expect(store.saved, const TrackingSessionSnapshot(
        onActivity: false,
        attendanceId: 'att-1',
        attendanceIntervalSeconds: 300,
        activityIntervalSeconds: 180,
      ));

      service.stopAllTracking();
      await Future<void>.delayed(Duration.zero);

      expect(store.saved, isNull);
      expect(store.clearCalls, 1);
    });

    test('restoreFromLocal melanjutkan sesi presensi tersimpan', () async {
      store.saved = const TrackingSessionSnapshot(
        onActivity: false,
        attendanceId: 'att-restore',
        attendanceIntervalSeconds: 120,
        activityIntervalSeconds: 60,
      );

      await service.restoreFromLocal();

      expect(service.state, TrackingState.inAttendance);
      expect(service.activeAttendanceId, 'att-restore');
      expect(service.activeIntervalSeconds, 120);
    });

    test('restoreFromLocal melanjutkan aktivitas lapangan beserta presensinya', () async {
      store.saved = const TrackingSessionSnapshot(
        onActivity: true,
        attendanceId: 'att-2',
        activityId: 'act-2',
        activityTitle: 'Kunjungan Klien',
        attendanceIntervalSeconds: 600,
        activityIntervalSeconds: 90,
      );

      await service.restoreFromLocal();

      expect(service.state, TrackingState.onActivity);
      expect(service.activeActivityId, 'act-2');
      expect(service.activeActivityTitle, 'Kunjungan Klien');
      expect(service.activeIntervalSeconds, 90);

      service.fallbackToAttendanceTracking();
      expect(service.state, TrackingState.inAttendance);
      expect(service.activeAttendanceId, 'att-2');
      expect(service.activeIntervalSeconds, 600);
    });

    test('server menyatakan sesi sudah selesai -> pelacakan berhenti & snapshot dihapus', () async {
      store.saved = const TrackingSessionSnapshot(
        onActivity: false,
        attendanceId: 'att-old',
        attendanceIntervalSeconds: 600,
        activityIntervalSeconds: 180,
      );
      await service.restoreFromLocal();
      expect(service.state, TrackingState.inAttendance);

      service.applyTrackingConfig(const TrackingConfigModel(
        hasAccess: true,
        isTrackingEnabled: true,
        attendance: TrackingSessionPolicy(enabled: true, intervalMinutes: 10),
        activity: TrackingSessionPolicy(enabled: true, intervalMinutes: 3),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(service.state, TrackingState.idle);
      expect(store.saved, isNull);
    });

    test('tanpa snapshot -> tetap idle', () async {
      await service.restoreFromLocal();
      expect(service.state, TrackingState.idle);
    });
  });
}
