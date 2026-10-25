import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_logs_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_log_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/attendance_hero_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('ATTN-01: tombol clock di hero card membuka AttendanceScreen', (
    $,
  ) async {
    await launchAndLogin($);

    final clockButton = find.descendant(
      of: find.byType(AttendanceHeroCard),
      matching: find.byType(ElevatedButton),
    );
    expect(clockButton, findsOneWidget, reason: 'Hero card harus punya tombol clock');

    final button = $.tester.widget<ElevatedButton>(clockButton);
    if (button.onPressed == null) {
      // Hari libur / tanpa jadwal: tombol nonaktif adalah perilaku yang benar.
      return;
    }

    await $.tester.tap(clockButton);
    await $.pump();
    await waitFor(
      $,
      find.byType(AttendanceScreen),
      reason: 'AttendanceScreen setelah menekan tombol clock',
    );
    // Izin lokasi/kamera mungkin diminta saat layar presensi dibuka.
    await grantPermissionIfVisible($);
    await pumpFor($, const Duration(seconds: 2));
    expect(find.byType(AttendanceScreen), findsOneWidget);

    // Sengaja TIDAK clock-in/out: aksi itu mengubah data nyata pada backend.
    await goBackToDashboard($);
  });

  patrolTest('ATTN-02: menu Presensi menampilkan log, tab Saya & Tim Saya', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Presensi', screen: AttendanceLogsScreen);

    expect(find.text('Attendance Logs'), findsOneWidget);
    expect(find.text('Saya'), findsWidgets);
    expect(find.text('Tim Saya'), findsOneWidget);

    // Tab Saya
    await waitForListLoaded($, card: AttendanceLogCard);
    expectNoErrorState();
    expect(
      find.byKey(const ValueKey('attendance_logs_month_chip_current')),
      findsOneWidget,
    );

    // Ganti ke bulan lalu & kembali
    await $.tester.tap(
      find.byKey(const ValueKey('attendance_logs_month_chip_last')),
    );
    await $.pump();
    await pumpFor($, const Duration(seconds: 2));
    await waitForListLoaded($, card: AttendanceLogCard);
    expectNoErrorState();
    await $.tester.tap(
      find.byKey(const ValueKey('attendance_logs_month_chip_current')),
    );
    await $.pump();
    await pumpFor($, const Duration(seconds: 2));

    // Tab Tim Saya
    await tapTab($, 'Tim Saya');
    await waitForListLoaded($, card: EmployeeCard);
    expectNoErrorState();

    await tapTab($, 'Saya');
    await goBackToDashboard($);
  });

  patrolTest('ATTN-03: filter log presensi terbuka & tertutup', ($) async {
    await launchAndLogin($);
    await openMenu($, 'Presensi', screen: AttendanceLogsScreen);

    await $.tester.tap(
      find.byKey(const ValueKey('attendance_logs_filter_button')),
    );
    await $.pump();
    await waitFor(
      $,
      find.text('Terapkan Filter'),
      reason: 'filter log presensi terbuka',
      timeout: const Duration(seconds: 10),
    );

    await $.tester.tapAt(const Offset(10, 60));
    await $.pump();
    await waitGone(
      $,
      find.text('Terapkan Filter'),
      reason: 'filter log presensi tertutup',
      timeout: const Duration(seconds: 5),
    );

    await goBackToDashboard($);
  });
}
