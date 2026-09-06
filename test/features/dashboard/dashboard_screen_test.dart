import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/dashboard_shimmer_loading.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/leave_balance_preview_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/updates_feed_card.dart';
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
            body: QuickAccessGrid(menus: sampleMenus),
          ),
        ),
      );

      expect(find.text('Quick Access'), findsOneWidget);

      // Verify that available menus are displayed
      expect(find.text('Employee'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);

      // Verify that unavailable menus are hidden
      expect(find.text('Payroll'), findsNothing);
      expect(find.text('Overtime'), findsNothing);
      expect(find.text('Leave'), findsNothing);
      expect(find.text('Helpdesk'), findsNothing);
      expect(find.text('Activity'), findsNothing);
      expect(find.text('Schedule'), findsNothing);

      // Helper check
      expect(
        QuickAccessGrid.isMenuAvailable('employee', 'Employee', sampleMenus),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable('payroll', 'Payroll', sampleMenus),
        isFalse,
      );
    });

    testWidgets('QuickAccessGrid renders all 8 items when menus is null (offline/fallback)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickAccessGrid(menus: null),
          ),
        ),
      );

      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Employee'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Helpdesk'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Overtime'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
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
              body: QuickAccessGrid(menus: null),
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

      await tester.tap(find.text('Employee'));
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
  });
}
