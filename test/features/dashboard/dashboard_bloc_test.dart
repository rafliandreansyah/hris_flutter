import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_state.dart';

class MockAuthRepository implements AuthRepository {
  final bool shouldFail;
  final String language;

  MockAuthRepository({this.shouldFail = false, this.language = 'id'});

  @override
  Future<UserProfileData> getProfile() async {
    if (shouldFail) {
      throw const ApiException(message: 'Failed to fetch profile', statusCode: 500);
    }
    return UserProfileData(
      user: UserModel(id: 'u1', email: 'test@example.com', language: language),
      dataScope: 'ALL',
      permissions: const ['all'],
    );
  }

  @override
  Future<String> updateLanguage(String lang) async => lang;

  @override
  Future<LoginResponseData> login(LoginRequestModel request) =>
      throw UnimplementedError();

  @override
  Future<String?> getSavedToken() async => 'mock_token';

  @override
  Future<bool> hasActiveSession() async => true;

  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

class MockSuccessDashboardRepository implements DashboardRepository {
  final EmployeeDeviceInfo? employeeDevice;

  MockSuccessDashboardRepository({
    this.employeeDevice = const EmployeeDeviceInfo(
      id: 'dev-1',
      deviceId: 'test_device_id',
      deviceName: 'iPhone',
    ),
  });

  @override
  Future<DashboardData> getDashboardData() async {
    return DashboardData(
      id: 'emp-1',
      firstName: 'Sarah',
      lastName: 'Jenkins',
      email: 'sarah@example.com',
      timeServer: '2026-09-06T08:15:30.000Z',
      employeeDevice: employeeDevice,
      latestAnnouncement: const [
        AnnouncementItem(
          id: 'ann-1',
          title: 'Upcoming Public Holiday',
          createdAt: '2026-09-06T00:00:00.000Z',
        ),
      ],
      attendanceSummary: const AttendanceSummaryInfo(
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
    throw const ApiException(message: 'Network connection failed', statusCode: 500);
  }

  @override
  Future<List<MenuItemModel>> getMenus() async {
    throw const ApiException(message: 'Network connection failed', statusCode: 500);
  }
}

void main() {
  group('DashboardBloc Tests', () {
    test('initial state is DashboardInitial', () {
      final bloc = DashboardBloc(
        dashboardRepository: MockSuccessDashboardRepository(),
        authRepository: MockAuthRepository(),
      );
      expect(bloc.state, equals(const DashboardInitial()));
      bloc.close();
    });

    test(
      'emits [DashboardLoading, DashboardLoaded] on successful fetch with matching device',
      () async {
        final bloc = DashboardBloc(
          dashboardRepository: MockSuccessDashboardRepository(),
          authRepository: MockAuthRepository(language: 'en'),
          getDeviceId: () async => 'test_device_id',
        );

        final expectedStates = [
          const DashboardLoading(),
          isA<DashboardLoaded>()
              .having((s) => s.dashboardData.firstName, 'firstName', 'Sarah')
              .having((s) => s.menus.length, 'menus count', 2)
              .having((s) => s.userProfile?.user.language, 'language', 'en'),
        ];

        expectLater(bloc.stream, emitsInOrder(expectedStates));

        bloc.add(const DashboardFetchRequested());
        await Future.delayed(const Duration(milliseconds: 100));
        await bloc.close();
      },
    );

    test(
      'emits [DashboardLoading, DashboardDeviceMismatch] and calls logout when deviceId does not match',
      () async {
        final authRepo = MockAuthRepository();
        final bloc = DashboardBloc(
          dashboardRepository: MockSuccessDashboardRepository(
            employeeDevice: const EmployeeDeviceInfo(
              id: 'dev-1',
              deviceId: 'registered_device_xyz',
            ),
          ),
          authRepository: authRepo,
          getDeviceId: () async => 'current_phone_abc',
        );

        final expectedStates = [
          const DashboardLoading(),
          isA<DashboardDeviceMismatch>()
              .having((s) => s.registeredDeviceId, 'registeredDeviceId', 'registered_device_xyz')
              .having((s) => s.currentDeviceId, 'currentDeviceId', 'current_phone_abc'),
        ];

        expectLater(bloc.stream, emitsInOrder(expectedStates));

        bloc.add(const DashboardFetchRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(authRepo.logoutCalled, isTrue);
        await bloc.close();
      },
    );

    test(
      'emits [DashboardLoading, DashboardDeviceMismatch] and calls logout when employeeDevice is null (unregistered/empty)',
      () async {
        final authRepo = MockAuthRepository();
        final bloc = DashboardBloc(
          dashboardRepository: MockSuccessDashboardRepository(
            employeeDevice: null,
          ),
          authRepository: authRepo,
          getDeviceId: () async => 'current_phone_abc',
        );

        final expectedStates = [
          const DashboardLoading(),
          isA<DashboardDeviceMismatch>()
              .having((s) => s.registeredDeviceId, 'registeredDeviceId', '')
              .having((s) => s.currentDeviceId, 'currentDeviceId', 'current_phone_abc'),
        ];

        expectLater(bloc.stream, emitsInOrder(expectedStates));

        bloc.add(const DashboardFetchRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(authRepo.logoutCalled, isTrue);
        await bloc.close();
      },
    );

    test(
      'emits [DashboardLoading, DashboardDeviceMismatch] and calls logout when employeeDevice.deviceId is empty',
      () async {
        final authRepo = MockAuthRepository();
        final bloc = DashboardBloc(
          dashboardRepository: MockSuccessDashboardRepository(
            employeeDevice: const EmployeeDeviceInfo(
              id: 'dev-1',
              deviceId: '   ',
            ),
          ),
          authRepository: authRepo,
          getDeviceId: () async => 'current_phone_abc',
        );

        final expectedStates = [
          const DashboardLoading(),
          isA<DashboardDeviceMismatch>()
              .having((s) => s.registeredDeviceId, 'registeredDeviceId', '')
              .having((s) => s.currentDeviceId, 'currentDeviceId', 'current_phone_abc'),
        ];

        expectLater(bloc.stream, emitsInOrder(expectedStates));

        bloc.add(const DashboardFetchRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(authRepo.logoutCalled, isTrue);
        await bloc.close();
      },
    );

    test(
      'emits [DashboardLoading, DashboardError] on repository failure',
      () async {
        final bloc = DashboardBloc(
          dashboardRepository: MockFailureDashboardRepository(),
          authRepository: MockAuthRepository(),
          getDeviceId: () async => 'test_device_id',
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
      },
    );

    test(
      'timer tick updates currentServerTime without altering data',
      () async {
        final bloc = DashboardBloc(
          dashboardRepository: MockSuccessDashboardRepository(),
          authRepository: MockAuthRepository(),
          getDeviceId: () async => 'test_device_id',
        );

        bloc.add(const DashboardFetchRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(bloc.state, isA<DashboardLoaded>());
        final initialTime = (bloc.state as DashboardLoaded).currentServerTime;

        final newTime = initialTime.add(const Duration(seconds: 1));
        bloc.add(DashboardTimerTicked(newTime));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state, isA<DashboardLoaded>());
        expect(
          (bloc.state as DashboardLoaded).currentServerTime,
          equals(newTime),
        );

        await bloc.close();
      },
    );
  });
}
