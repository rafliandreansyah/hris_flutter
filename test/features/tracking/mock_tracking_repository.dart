import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';
import 'package:hris_flutter/features/tracking/domain/repositories/tracking_repository.dart';

class MockTrackingRepository implements TrackingRepository {
  bool shouldThrow = false;
  String errorMessage = 'Failed to load tracking data';
  LiveTrackingResponse? customLiveResponse;
  List<TrackingLogItem>? customRouteLogs;

  @override
  Future<LiveTrackingResponse> getLiveTracking({
    String? companyId,
    String? departmentId,
    String? status,
    bool activeOnly = true,
    String? search,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage);
    }
    return customLiveResponse ??
        LiveTrackingResponse(
          summary: const LiveTrackingSummary(
            totalTracked: 2,
            attendanceCount: 1,
            activityCount: 1,
            onlineCount: 2,
            gpsOffCount: 0,
          ),
          employees: [
            LiveEmployeeLocation(
              employeeId: 'emp-1',
              name: 'Ahmad Dahlan',
              employeeNumber: 'EMP-001',
              latitude: -6.2088,
              longitude: 106.8456,
              status: 'attendance',
              recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
              isOnline: true,
              minutesSinceLastPing: 2,
            ),
            LiveEmployeeLocation(
              employeeId: 'emp-2',
              name: 'Budi Santoso',
              employeeNumber: 'EMP-002',
              latitude: -6.2188,
              longitude: 106.8556,
              status: 'activity',
              recordedAt: DateTime.utc(2026, 10, 7, 8, 5, 0),
              isOnline: true,
              minutesSinceLastPing: 3,
            ),
          ],
        );
  }

  @override
  Future<List<TrackingLogItem>> getTrackingLogs({
    required String sourceType,
    required String referenceId,
    String? employeeId,
    int? limit,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage);
    }
    return customRouteLogs ??
        [
          TrackingLogItem(
            id: 'log-1',
            employeeId: 'emp-1',
            sourceType: sourceType,
            latitude: -6.2088,
            longitude: 106.8456,
            recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
          ),
        ];
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
  Future<void> uploadBatch(TrackingBatchPayload payload) async {}
}
