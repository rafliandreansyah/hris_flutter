import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';
import 'package:hris_flutter/features/tracking/data/repositories/tracking_repository_impl.dart';

class _MockTrackingRemoteDataSource implements TrackingRemoteDataSource {
  int getTrackingConfigCallCount = 0;
  int uploadBatchCallCount = 0;
  int getTrackingLogsCallCount = 0;
  int getLiveTrackingCallCount = 0;

  dynamic mockConfigResponse;
  dynamic mockLogsResponse;
  dynamic mockLiveResponse;

  @override
  Future<TrackingConfigModel> getTrackingConfig() async {
    getTrackingConfigCallCount++;
    return mockConfigResponse as TrackingConfigModel;
  }

  @override
  Future<void> uploadBatch(TrackingBatchPayload payload) async {
    uploadBatchCallCount++;
  }

  @override
  Future<List<TrackingLogItem>> getTrackingLogs({
    required String sourceType,
    required String referenceId,
    String? employeeId,
    int? limit,
  }) async {
    getTrackingLogsCallCount++;
    return mockLogsResponse as List<TrackingLogItem>;
  }

  @override
  Future<LiveTrackingResponse> getLiveTracking({
    String? companyId,
    String? departmentId,
    String? status,
    bool activeOnly = true,
    String? search,
  }) async {
    getLiveTrackingCallCount++;
    return mockLiveResponse as LiveTrackingResponse;
  }
}

void main() {
  group('TrackingRepositoryImpl Tests', () {
    late _MockTrackingRemoteDataSource mockRemoteDataSource;
    late TrackingRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockTrackingRemoteDataSource();
      repository = TrackingRepositoryImpl(remoteDataSource: mockRemoteDataSource);
    });

    test('getTrackingConfig delegates to remote data source', () async {
      mockRemoteDataSource.mockConfigResponse = const TrackingConfigModel(
        hasAccess: true,
        isTrackingEnabled: true,
        attendance: TrackingSessionPolicy(enabled: true, intervalMinutes: 10),
        activity: TrackingSessionPolicy(enabled: true, intervalMinutes: 15),
      );

      final result = await repository.getTrackingConfig();

      expect(mockRemoteDataSource.getTrackingConfigCallCount, equals(1));
      expect(result.hasAccess, isTrue);
      expect(result.isTrackingEnabled, isTrue);
      expect(result.attendance.intervalMinutes, equals(10));
    });

    test('uploadBatch delegates to remote data source', () async {
      final payload = TrackingBatchPayload(
        sourceType: 'attendance',
        referenceId: 'att-1',
        locations: [
          TrackingLocationPoint(
            id: 'loc-1',
            latitude: -6.2,
            longitude: 106.8,
            recordedAt: DateTime.utc(2026, 10, 14, 8, 0, 0),
          ),
        ],
      );

      await repository.uploadBatch(payload);

      expect(mockRemoteDataSource.uploadBatchCallCount, equals(1));
    });

    test('getTrackingLogs delegates to remote data source', () async {
      mockRemoteDataSource.mockLogsResponse = [
        TrackingLogItem(
          id: 'log-1',
          employeeId: 'emp-1',
          sourceType: 'attendance',
          latitude: -6.2088,
          longitude: 106.8456,
          recordedAt: DateTime.utc(2026, 10, 14, 8, 30, 0),
        ),
      ];

      final logs = await repository.getTrackingLogs(
        sourceType: 'attendance',
        referenceId: 'att-1',
        employeeId: 'emp-1',
        limit: 25,
      );

      expect(mockRemoteDataSource.getTrackingLogsCallCount, equals(1));
      expect(logs.length, equals(1));
      expect(logs.first.id, equals('log-1'));
    });

    test('getLiveTracking delegates to remote data source', () async {
      mockRemoteDataSource.mockLiveResponse = LiveTrackingResponse(
        summary: const LiveTrackingSummary(
          totalTracked: 1,
          attendanceCount: 1,
          activityCount: 0,
          onlineCount: 1,
          gpsOffCount: 0,
        ),
        employees: [
          LiveEmployeeLocation(
            employeeId: 'emp-1',
            name: 'Jane Doe',
            employeeNumber: 'EMP-001',
            status: 'attendance',
            latitude: -6.2,
            longitude: 106.8,
            recordedAt: DateTime(2026, 10, 14, 8, 0),
            isOnline: true,
            minutesSinceLastPing: 2,
          ),
        ],
      );

      final response = await repository.getLiveTracking(
        companyId: 'comp-1',
        departmentId: 'dept-1',
        status: 'online',
        activeOnly: true,
        search: 'Jane',
      );

      expect(mockRemoteDataSource.getLiveTrackingCallCount, equals(1));
      expect(response.summary.totalTracked, equals(1));
      expect(response.employees.first.name, equals('Jane Doe'));
    });
  });
}
