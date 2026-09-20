import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/attendance_hero_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/dashboard_shimmer_loading.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/leave_balance_preview_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/updates_feed_card.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_count/notification_count_bloc.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_count/notification_count_event.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  group('Dashboard Widgets Tests', () {
    testWidgets('DashboardShimmerLoading renders Shimmer elements properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardShimmerLoading(),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets(
        'QuickAccessGrid shows only menus available in API response and hides unavailable ones', (
      WidgetTester tester,
    ) async {
      // Only Employee and Attendance are present in API response
      const sampleMenus = [
        MenuItemModel(id: '1', name: 'Employee', code: 'employee'),
        MenuItemModel(id: '2', name: 'Attendance', code: 'attendance'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessGrid(menus: sampleMenus),
            ),
          ),
        ),
      );

      expect(find.text('Quick Access'), findsOneWidget);

      // Verify that available menus are displayed (in Indonesian as per current standard)
      expect(find.text('Pegawai'), findsOneWidget);
      expect(find.text('Presensi'), findsOneWidget);

      // Verify that unavailable menus are hidden
      expect(find.text('Slip Gaji'), findsNothing);
      expect(find.text('Lembur'), findsNothing);
      expect(find.text('Izin & Cuti'), findsNothing);
      expect(find.text('Aktivitas'), findsNothing);
      expect(find.text('Jadwal Kerja'), findsNothing);

      // Helper check
      expect(
        QuickAccessGrid.isMenuAvailable('mobile_employee', 'Pegawai', sampleMenus),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable('mobile_payroll', 'Slip Gaji', sampleMenus),
        isFalse,
      );
    });

    testWidgets('QuickAccessGrid renders all 9 items when menus is null (offline/fallback)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessGrid(menus: null),
            ),
          ),
        ),
      );

      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Pegawai'), findsOneWidget);
      expect(find.text('Slip Gaji'), findsOneWidget);
      expect(find.text('Presensi'), findsOneWidget);
      expect(find.text('Lembur'), findsOneWidget);
      expect(find.text('Izin & Cuti'), findsOneWidget);
      expect(find.text('Absen Luar'), findsOneWidget);
      expect(find.text('Surat Peringatan'), findsOneWidget);
      expect(find.text('Jadwal Kerja'), findsOneWidget);
    });

    testWidgets(
        'Tapping Employee menu in QuickAccessGrid navigates to Employee Directory', (
      WidgetTester tester,
    ) async {
      final testRouter = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: QuickAccessGrid(menus: null),
              ),
            ),
          ),
          GoRoute(
            path: Routes.EMPLOYEE_DIRECTORY,
            builder: (context, state) => const Scaffold(
              body: Text('Employee Directory Destination'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pegawai'));
      await tester.pumpAndSettle();

      expect(find.text('Employee Directory Destination'), findsOneWidget);
    });

    testWidgets(
        'LeaveBalancePreviewCard shows info message when hasQuota is false or 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaveBalancePreviewCard(
              hasQuota: false,
              annualLeaveTotal: 0,
              annualLeaveRemaining: 0,
            ),
          ),
        ),
      );

      expect(find.text('Leave Balance'), findsOneWidget);
      expect(find.text('Tidak memiliki kuota cuti tahun ini'), findsOneWidget);
      expect(find.text('Annual'), findsNothing);
    });

    testWidgets(
        'LeaveBalancePreviewCard shows progress bars when hasQuota is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaveBalancePreviewCard(
              hasQuota: true,
              annualLeaveTotal: 14,
              annualLeaveRemaining: 11,
              sickLeaveTotal: 14,
              sickLeaveRemaining: 8,
            ),
          ),
        ),
      );

      expect(find.text('Leave Balance'), findsOneWidget);
      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('11 Days'), findsOneWidget);
      expect(find.text('8 Days'), findsOneWidget);
      expect(find.text('Tidak memiliki kuota cuti tahun ini'), findsNothing);
    });

    testWidgets(
        'UpdatesFeedCard shows info message when hasAnnouncement is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdatesFeedCard(
              hasAnnouncement: false,
              title: null,
            ),
          ),
        ),
      );

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Tidak ada pengumuman'), findsOneWidget);
      expect(
        find.text('Saat ini belum ada pengumuman terbaru dari perusahaan'),
        findsOneWidget,
      );
    });

    testWidgets(
        'UpdatesFeedCard shows announcement title when hasAnnouncement is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdatesFeedCard(
              hasAnnouncement: true,
              title: 'Townhall Meeting Scheduled',
              timeAndCategory: 'Hari ini · Pengumuman',
            ),
          ),
        ),
      );

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Townhall Meeting Scheduled'), findsOneWidget);
      expect(find.text('Hari ini · Pengumuman'), findsOneWidget);
      expect(find.text('Tidak ada pengumuman'), findsNothing);
    });

    testWidgets(
        'UpdatesFeedCard renders multiple announcements up to 5 items', (
      WidgetTester tester,
    ) async {
      final announcements = List.generate(
        5,
        (i) => AnnouncementItem(
          id: 'ann-$i',
          title: 'Pengumuman Penting #$i',
          createdAt: '2026-09-18T10:00:00.000Z',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UpdatesFeedCard(
                announcements: announcements,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      for (int i = 0; i < 5; i++) {
        expect(find.text('Pengumuman Penting #$i'), findsOneWidget);
      }
      expect(find.text('Tidak ada pengumuman'), findsNothing);
    });

    testWidgets(
        'UpdatesFeedCard invokes onAnnouncementTap with correct item when tapped', (
      WidgetTester tester,
    ) async {
      AnnouncementItem? tappedItem;
      final announcements = [
        const AnnouncementItem(
          id: 'ann-123',
          title: 'Perubahan Jam Kerja Ramadhan',
          createdAt: '2026-09-18T10:00:00.000Z',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdatesFeedCard(
              announcements: announcements,
              onAnnouncementTap: (item) {
                tappedItem = item;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Perubahan Jam Kerja Ramadhan'));
      await tester.pumpAndSettle();

      expect(tappedItem, isNotNull);
      expect(tappedItem?.id, equals('ann-123'));
      expect(tappedItem?.title, equals('Perubahan Jam Kerja Ramadhan'));
    });

    testWidgets(
        'Tapping announcement item on Dashboard navigates to Announcement Detail', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testData = DashboardData(
        id: 'emp-101',
        firstName: 'John',
        email: 'john@example.com',
        latestAnnouncement: [
          AnnouncementItem(
            id: 'ann-target-99',
            title: 'Pengumuman Libur Nasional',
            createdAt: '2026-09-18T10:00:00.000Z',
          ),
        ],
      );

      final repo = MockSuccessDashboardRepository(data: testData);
      String? capturedExtraId;

      final testRouter = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => DashboardScreen(
              repository: repo,
              authRepository: MockAuthRepository(),
              getDeviceId: () async => 'unknown_device_id',
            ),
          ),
          GoRoute(
            path: Routes.ANNOUNCEMENT_DETAIL,
            builder: (context, state) {
              capturedExtraId = state.extra as String?;
              return const Scaffold(
                body: Text('Announcement Detail Screen Destination'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pengumuman Libur Nasional'), findsOneWidget);

      await tester.tap(find.text('Pengumuman Libur Nasional'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Announcement Detail Screen Destination'),
        findsOneWidget,
      );
      expect(capturedExtraId, equals('ann-target-99'));
    });

    testWidgets(
        'DashboardScreen displays error state and error dialog on repository error with English message', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockFailureDashboardRepository(
        message: 'Server connection timeout. Please try again.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(repository: repo),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Verifies error UI on screen displays API message directly
      expect(find.text('Server connection timeout. Please try again.'), findsAtLeast(1));
      expect(find.text('Coba Lagi'), findsAtLeast(1));

      // Dismiss dialog by tapping Coba Lagi to clean up dialog animation timers
      await tester.tap(find.text('Coba Lagi').last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets(
        'DashboardScreen displays error state and error dialog on repository error in Indonesian', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockFailureDashboardRepository(
        message: 'Gagal memuat data dari server backend.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(repository: repo),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Verifies error UI on screen
      expect(find.text('Gagal memuat data dari server backend.'), findsAtLeast(1));
      expect(find.text('Coba Lagi'), findsAtLeast(1));

      await tester.tap(find.text('Coba Lagi').last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Dashboard renders notification bell with unread count badge', (
      WidgetTester tester,
    ) async {
      final notifBloc = NotificationCountBloc()
        ..add(const NotificationCountUpdated(7));

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            repository: MockFailureDashboardRepository(),
            notificationCountBloc: notifBloc,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('dashboard_notification_btn')), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi').last, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Dashboard renders Libur Kerja and calendarOff icon when isDayOff is true', (
      WidgetTester tester,
    ) async {
      const dayOffData = DashboardData(
        id: 'emp-101',
        firstName: 'John',
        email: 'john@example.com',
        todaySchedule: TodayScheduleInfo(
          id: 'sch-101',
          isDayOff: true,
          shift: null,
        ),
      );

      final repo = MockSuccessDashboardRepository(data: dayOffData);
      final authRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            repository: repo,
            authRepository: authRepo,
            getDeviceId: () async => 'unknown_device_id',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Libur Kerja'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AttendanceHeroCard),
          matching: find.byIcon(LucideIcons.calendarOff),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Dashboard renders Tidak Ada Jadwal Kerja when todaySchedule is null', (
      WidgetTester tester,
    ) async {
      const noScheduleData = DashboardData(
        id: 'emp-102',
        firstName: 'Jane',
        email: 'jane@example.com',
        todaySchedule: null,
      );

      final repo = MockSuccessDashboardRepository(data: noScheduleData);
      final authRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            repository: repo,
            authRepository: authRepo,
            getDeviceId: () async => 'unknown_device_id',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Tidak Ada Jadwal Kerja'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AttendanceHeroCard),
          matching: find.byIcon(LucideIcons.calendarX),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'DashboardScreen displays error dialog on DashboardDeviceMismatch', (
      WidgetTester tester,
    ) async {
      const testData = DashboardData(
        id: 'emp-101',
        firstName: 'John',
        email: 'john@example.com',
        employeeDevice: EmployeeDeviceInfo(
          id: 'dev-1',
          deviceId: 'registered_device_abc',
        ),
      );

      final repo = MockSuccessDashboardRepository(data: testData);
      final authRepo = MockAuthRepository();
      final notifBloc = NotificationCountBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            repository: repo,
            authRepository: authRepo,
            notificationCountBloc: notifBloc,
            getDeviceId: () async => 'different_current_phone',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Perangkat Tidak Sesuai'), findsOneWidget);
      expect(find.text('Kembali ke Login'), findsOneWidget);
      expect(authRepo.logoutCalled, isTrue);
    });
  });
}

class MockAuthRepository implements AuthRepository {
  bool logoutCalled = false;

  @override
  Future<UserProfileData> getProfile() async {
    return const UserProfileData(
      user: UserModel(id: 'u1', email: 'test@example.com', language: 'id'),
      dataScope: 'ALL',
      permissions: ['all'],
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

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

class MockSuccessDashboardRepository implements DashboardRepository {
  final DashboardData data;
  final List<MenuItemModel> menus;

  MockSuccessDashboardRepository({
    required this.data,
    this.menus = const [],
  });

  @override
  Future<DashboardData> getDashboardData() async => data.employeeDevice != null
      ? data
      : data.copyWith(
          employeeDevice: const EmployeeDeviceInfo(
            id: 'dev-mock',
            deviceId: 'unknown_device_id',
          ),
        );

  @override
  Future<List<MenuItemModel>> getMenus() async => menus;
}

class MockFailureDashboardRepository implements DashboardRepository {
  final String message;
  final int? statusCode;

  MockFailureDashboardRepository({
    this.message = 'Network connection failed',
    this.statusCode = 500,
  });

  @override
  Future<DashboardData> getDashboardData() async {
    throw ApiException(message: message, statusCode: statusCode);
  }

  @override
  Future<List<MenuItemModel>> getMenus() async {
    throw ApiException(message: message, statusCode: statusCode);
  }
}
