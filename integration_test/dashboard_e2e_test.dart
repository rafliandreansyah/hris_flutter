import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/attendance_hero_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/updates_feed_card.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';
import 'package:hris_flutter/features/notification/presentation/pages/notification_screen.dart';
import 'package:hris_flutter/features/schedule/presentation/pages/work_schedule_screen.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('DASH-01: elemen utama Dashboard ter-render setelah login', (
    $,
  ) async {
    await launchAndLogin($);

    expect(find.text('Oasish'), findsOneWidget);
    expect(find.byType(AttendanceHeroCard), findsOneWidget);
    expect(find.text('CURRENT STATUS'), findsOneWidget);
    expect(find.byType(QuickAccessGrid), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.byType(UpdatesFeedCard), findsOneWidget);
  });

  patrolTest('DASH-02/03: menu Pegawai di grid membuka direktori & kembali', (
    $,
  ) async {
    await launchAndLogin($);

    await openMenu($, 'Pegawai', screen: EmployeeDirectoryScreen);
    expect(find.text('Employee Directory'), findsOneWidget);

    await goBackToDashboard($);
    expect(find.byType(QuickAccessGrid), findsOneWidget);
  });

  patrolTest('DASH-04: pull-to-refresh memuat ulang Dashboard tanpa error', (
    $,
  ) async {
    await launchAndLogin($);

    await $.tester.drag(
      find.byType(RefreshIndicator).first,
      const Offset(0, 400),
    );
    await $.pump();
    await pumpFor($, const Duration(seconds: 2));

    await waitFor(
      $,
      find.byType(QuickAccessGrid),
      reason: 'grid kembali tampil setelah refresh',
    );
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(AttendanceHeroCard), findsOneWidget);
  });

  patrolTest('DASH-10: tombol notifikasi di header membuka NotificationScreen', (
    $,
  ) async {
    await launchAndLogin($);

    await $.tester.tap(find.byKey(const ValueKey('dashboard_notification_btn')));
    await $.pump();
    await waitFor($, find.byType(NotificationScreen), reason: 'NotificationScreen');

    await goBackToDashboard($);
  });

  patrolTest('DASH-11: tombol jadwal kerja di header membuka WorkScheduleScreen', (
    $,
  ) async {
    await launchAndLogin($);

    await $.tester.tap(find.byKey(const ValueKey('dashboard_work_schedule_btn')));
    await $.pump();
    await waitFor($, find.byType(WorkScheduleScreen), reason: 'WorkScheduleScreen');

    await goBackToDashboard($);
  });

  patrolTest('DASH-12: avatar header membuka profil karyawan', ($) async {
    await launchAndLogin($);

    final avatar = find.byType(AppAvatar).hitTestable();
    expect(avatar, findsWidgets, reason: 'Avatar header harus tampil');
    await $.tester.tap(avatar.first);
    await $.pump();
    await pumpFor($, const Duration(seconds: 2));

    expect(
      find.byType(DashboardScreen).hitTestable(),
      findsNothing,
      reason: 'Layar profil harus menutupi Dashboard',
    );
    await goBackToDashboard($);
  });
}
