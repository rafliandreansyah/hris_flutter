import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/create_overtime_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/overtime_detail_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/overtime_requests_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_request_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('OVT-01/03/04: daftar, tab, detail, dan filter pengajuan lembur', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Lembur', screen: OvertimeRequestsScreen);

    await verifyRequestModule(
      $,
      screen: OvertimeRequestsScreen,
      screenTitle: 'Overtime Requests',
      card: OvertimeRequestCard,
      detailScreens: const [OvertimeDetailScreen],
    );

    await goBackToDashboard($);
  });

  patrolTest('OVT-02: form lembur terbuka & submit kosong ditolak validasi', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Lembur', screen: OvertimeRequestsScreen);

    await $.tester.tap(find.byKey(const ValueKey('add_overtime_fab')));
    await $.pump();
    await waitFor(
      $,
      find.byType(CreateOvertimeScreen),
      reason: 'CreateOvertimeScreen',
    );

    final submit = find.byKey(const ValueKey('submit_overtime_btn'));
    await $.tester.ensureVisible(submit);
    await $.pump(const Duration(milliseconds: 300));
    await $.tester.tap(submit);
    await $.pump();
    await pumpFor($, const Duration(seconds: 1));

    expect(find.byType(CreateOvertimeScreen), findsOneWidget);
    expect(
      find.byType(SnackBar),
      findsOneWidget,
      reason: 'Peringatan validasi harus tampil saat submit kosong',
    );
    await pumpFor($, const Duration(seconds: 5));

    await goBack($);
    await waitFor(
      $,
      find.byType(OvertimeRequestsScreen),
      reason: 'kembali ke daftar lembur',
    );
    await goBackToDashboard($);
  });
}
