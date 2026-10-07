import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/services/location/location_local_storage.dart';
import 'package:hris_flutter/core/services/location/location_tracking_service.dart';
import 'package:hris_flutter/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';
import 'package:hris_flutter/features/tracking/domain/repositories/tracking_repository.dart';

class MockTrackingRepository implements TrackingRepository {
  final List<TrackingBatchPayload> uploadedBatches = [];
  bool shouldThrowNetworkError = false;
  SessionClosedException? sessionClosedExceptionToThrow;

  @override
  Future<void> uploadBatch(TrackingBatchPayload payload) async {
    if (sessionClosedExceptionToThrow != null) {
      throw sessionClosedExceptionToThrow!;
    }
    if (shouldThrowNetworkError) {
      throw Exception('Simulated Network Error');
    }
    uploadedBatches.add(payload);
  }

  @override
  Future<TrackingConfigModel> getTrackingConfig() async {
    return const TrackingConfigModel(
      hasAccess: true,
      isTrackingEnabled: true,
      attendance: TrackingSessionPolicy(enabled: true, intervalMinutes: 10),
      activity: TrackingSessionPolicy(enabled: true, intervalMinutes: 3),
    );
  }

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
  late LocationTrackingService trackingService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tracking_service_test_');
    tempFile = File('${tempDir.path}/test_buffer.json');

    localStorage = LocationLocalStorage.instance;
    localStorage.customStoragePath = tempFile.path;

    mockRepo = MockTrackingRepository();
    trackingService = LocationTrackingService.withDependencies(
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
}
