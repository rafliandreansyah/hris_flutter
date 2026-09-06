import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_state.dart';

class MockSuccessDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData() async {
    return const DashboardData(
      id: 'emp-1',
      firstName: 'Sarah',
      lastName: 'Jenkins',
      email: 'sarah@example.com',
      timeServer: '2026-09-06T08:15:30.000Z',
      latestAnnouncement: [
        AnnouncementItem(
          id: 'ann-1',
          title: 'Upcoming Public Holiday',
          createdAt: '2026-09-06T00:00:00.000Z',
        ),
      ],
      attendanceSummary: AttendanceSummaryInfo(
        todayAttendance: TodayAttendanceInfo(inTime: '08:30'),
        quotaLeaveBalanceThisYear: QuotaLeaveBalance(
          totalQuota: 14,
          totalUsed: 2,
        ),
      ),
    );
  }

  @override
  Future<List<MenuItemModel>> getMenus() async {
    return const [
      MenuItemModel(id: '1', name: 'Employee', code: 'employee'),
      MenuItemModel(id: '2', name: 'Attendance', code: 'attendance'),
    ];
  }
}

class MockFailureDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData() async {
    throw ApiException(message: 'Network connection failed', statusCode: 500);
  }

  @override
  Future<List<MenuItemModel>> getMenus() async {
    throw ApiException(message: 'Network connection failed', statusCode: 500);
  }
}

void main() {
  group('DashboardBloc Tests', () {
    test('initial state is DashboardInitial', () {
      final bloc = DashboardBloc(
        dashboardRepository: MockSuccessDashboardRepository(),
      );
      expect(bloc.state, equals(const DashboardInitial()));
      bloc.close();
    });

    test('emits [DashboardLoading, DashboardLoaded] on successful fetch', () async {
      final bloc = DashboardBloc(
        dashboardRepository: MockSuccessDashboardRepository(),
      );

      final expectedStates = [
        const DashboardLoading(),
        isA<DashboardLoaded>()
            .having((s) => s.dashboardData.firstName, 'firstName', 'Sarah')
            .having((s) => s.menus.length, 'menus count', 2),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const DashboardFetchRequested());
      await Future.delayed(const Duration(milliseconds: 100));
      await bloc.close();
    });

    test('emits [DashboardLoading, DashboardError] on repository failure', () async {
      final bloc = DashboardBloc(
        dashboardRepository: MockFailureDashboardRepository(),
      );

      final expectedStates = [
        const DashboardLoading(),
        isA<DashboardError>().having(
          (s) => s.message,
          'message',
          'Network connection failed',
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const DashboardFetchRequested());
      await Future.delayed(const Duration(milliseconds: 100));
      await bloc.close();
    });

    test('timer tick updates currentServerTime without altering data', () async {
      final bloc = DashboardBloc(
        dashboardRepository: MockSuccessDashboardRepository(),
      );

      bloc.add(const DashboardFetchRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<DashboardLoaded>());
      final initialTime = (bloc.state as DashboardLoaded).currentServerTime;

      final newTime = initialTime.add(const Duration(seconds: 1));
      bloc.add(DashboardTimerTicked(newTime));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<DashboardLoaded>());
      expect((bloc.state as DashboardLoaded).currentServerTime, equals(newTime));

      await bloc.close();
    });
  });
}
