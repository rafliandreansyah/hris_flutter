import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/schedule/presentation/pages/work_schedule_screen.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('SCHED-01: menu Jadwal Kerja menampilkan jadwal tanpa error', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Jadwal Kerja', screen: WorkScheduleScreen);

    expect(find.text('Jadwal Kerja Saya'), findsOneWidget);

    // Tunggu shimmer selesai.
    await pumpFor($, const Duration(seconds: 4));
    var elapsed = Duration.zero;
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
        elapsed < const Duration(seconds: 20)) {
      await $.pump(const Duration(milliseconds: 250));
      elapsed += const Duration(milliseconds: 250);
    }

    expect(
      find.text('Gagal Memuat Jadwal'),
      findsNothing,
      reason: 'Jadwal kerja menampilkan state error',
    );
    expect(find.byType(WorkScheduleScreen), findsOneWidget);

    await goBackToDashboard($);
  });

  patrolTest('SCHED-02: tombol jadwal di header Dashboard membuka jadwal', (
    $,
  ) async {
    await launchAndLogin($);

    await $.tester.tap(find.byKey(const ValueKey('dashboard_work_schedule_btn')));
    await $.pump();
    await waitFor($, find.byType(WorkScheduleScreen), reason: 'WorkScheduleScreen');
    expect(find.text('Jadwal Kerja Saya'), findsOneWidget);

    await goBackToDashboard($);
  });
}
