import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';
import 'package:hris_flutter/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_event.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_state.dart';

class MockTrackingRepo implements TrackingRepository {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTrackingRepo repo;

  setUp(() {
    repo = MockTrackingRepo();
  });

  group('LiveTrackingBloc Tests', () {
    test('initial state has initial status', () {
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      expect(bloc.state.status, equals(LiveTrackingStatus.initial));
      expect(bloc.state.data, isNull);
      expect(bloc.state.filteredEmployees, isEmpty);
      bloc.close();
    });

    test('LiveTrackingStarted emits [loading, loaded] on success', () async {
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      final states = <LiveTrackingState>[];
      bloc.stream.listen(states.add);

      bloc.add(const LiveTrackingStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(2));
      expect(states[0].status, equals(LiveTrackingStatus.loading));
      expect(states[1].status, equals(LiveTrackingStatus.loaded));
      expect(states[1].data?.employees.length, equals(2));
      expect(states[1].filteredEmployees.length, equals(2));

      await bloc.close();
    });

    test('LiveTrackingStarted emits [loading, failure] on error', () async {
      repo.shouldThrow = true;
      repo.errorMessage = 'Akses live tracking ditolak';
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      final states = <LiveTrackingState>[];
      bloc.stream.listen(states.add);

      bloc.add(const LiveTrackingStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(2));
      expect(states[0].status, equals(LiveTrackingStatus.loading));
      expect(states[1].status, equals(LiveTrackingStatus.failure));
      expect(states[1].errorMessage, equals('Akses live tracking ditolak'));

      await bloc.close();
    });

    test('searchQuery filters employee list correctly', () async {
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      final states = <LiveTrackingState>[];
      bloc.stream.listen(states.add);

      bloc.add(const LiveTrackingStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const LiveTrackingSearchQueryChanged('Ahmad'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.searchQuery, equals('Ahmad'));
      expect(bloc.state.filteredEmployees.length, equals(1));
      expect(bloc.state.filteredEmployees.first.name, equals('Ahmad Dahlan'));

      await bloc.close();
    });

    test('LiveTrackingEmployeeSelected updates selectedEmployee', () async {
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      final states = <LiveTrackingState>[];
      bloc.stream.listen(states.add);

      final emp = LiveEmployeeLocation(
        employeeId: 'emp-99',
        name: 'Selected Test',
        employeeNumber: 'EMP-099',
        latitude: -6.1,
        longitude: 106.8,
        status: 'attendance',
        recordedAt: DateTime.utc(2026, 10, 7),
        isOnline: true,
        minutesSinceLastPing: 1,
      );

      bloc.add(LiveTrackingEmployeeSelected(emp));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(1));
      expect(states.first.selectedEmployee?.employeeId, equals('emp-99'));
      expect(states.first.selectedRouteLogs, isEmpty);

      await bloc.close();
    });

    test('LiveTrackingRouteRequested fetches route logs', () async {
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      final states = <LiveTrackingState>[];
      bloc.stream.listen(states.add);

      bloc.add(const LiveTrackingRouteRequested(
        sourceType: 'attendance',
        referenceId: 'att-100',
        employeeId: 'emp-1',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(2));
      expect(states[0].isLoadingRoute, isTrue);
      expect(states[1].isLoadingRoute, isFalse);
      expect(states[1].selectedRouteLogs.length, equals(1));
      expect(states[1].selectedRouteLogs.first.id, equals('log-1'));

      await bloc.close();
    });

    test('LiveTrackingRefreshed with isSilent=true updates without emitting loading', () async {
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      final states = <LiveTrackingState>[];
      bloc.stream.listen(states.add);

      bloc.add(const LiveTrackingRefreshed(isSilent: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(1));
      expect(states[0].status, equals(LiveTrackingStatus.loaded));
      expect(states[0].data != null, isTrue);

      await bloc.close();
    });

    test('LiveTrackingFilterChanged updates filters and fetches data', () async {
      final bloc = LiveTrackingBloc(repository: repo, enableAutoPolling: false);
      final states = <LiveTrackingState>[];
      bloc.stream.listen(states.add);

      bloc.add(const LiveTrackingFilterChanged(
        companyId: 'comp-10',
        departmentId: 'dept-20',
        status: 'activity',
        activeOnly: false,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, equals(2));
      expect(states[0].status, equals(LiveTrackingStatus.loading));
      expect(states[0].selectedCompanyId, equals('comp-10'));
      expect(states[0].selectedDepartmentId, equals('dept-20'));
      expect(states[0].selectedStatus, equals('activity'));
      expect(states[0].activeOnly, isFalse);
      expect(states[1].status, equals(LiveTrackingStatus.loaded));

      await bloc.close();
    });
  });
}
