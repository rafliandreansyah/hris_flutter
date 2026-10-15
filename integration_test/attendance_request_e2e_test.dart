import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_request_detail_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_requests_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('ATTREQ-01/03/04: daftar, tab, detail, dan filter absen luar', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Absen Luar', screen: AttendanceRequestsScreen);

    await verifyRequestModule(
      $,
      screen: AttendanceRequestsScreen,
      screenTitle: 'Presensi Luar Kantor',
      card: AttendanceRequestCard,
      detailScreens: const [AttendanceRequestDetailScreen],
    );

    await goBackToDashboard($);
  });

  patrolTest('ATTREQ-02: FAB menampilkan pilihan metode Live & Schedule', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Absen Luar', screen: AttendanceRequestsScreen);

    await $.tester.tap(find.byKey(const ValueKey('add_attendance_request_fab')));
    await $.pump();
    await waitFor(
      $,
      find.text('Pilih Metode Presensi Luar'),
      reason: 'bottom sheet pilihan metode presensi luar',
    );
    expect(find.text('Live Attendance (Real-Time)'), findsOneWidget);
    expect(find.text('Schedule Attendance (Terencana)'), findsOneWidget);

    // Tutup sheet dengan menekan area di luar sheet (barrier).
    await $.tester.tapAt(const Offset(10, 60));
    await $.pump();
    await waitGone(
      $,
      find.text('Pilih Metode Presensi Luar'),
      reason: 'bottom sheet tertutup',
      timeout: const Duration(seconds: 5),
    );
    expect(find.byType(AttendanceRequestsScreen), findsOneWidget);

    await goBackToDashboard($);
  });
}
