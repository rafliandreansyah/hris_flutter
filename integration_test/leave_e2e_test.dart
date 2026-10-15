import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/leave/presentation/pages/create_leave_screen.dart';
import 'package:hris_flutter/features/leave/presentation/pages/leave_detail_screen.dart';
import 'package:hris_flutter/features/leave/presentation/pages/leave_screen.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_request_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('LEAVE-01/03/04: daftar, tab, detail, dan filter pengajuan cuti', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Izin & Cuti', screen: LeaveScreen);

    await verifyRequestModule(
      $,
      screen: LeaveScreen,
      screenTitle: 'Leave & Time Off',
      card: LeaveRequestCard,
      detailScreens: const [LeaveDetailScreen],
    );

    await goBackToDashboard($);
  });

  patrolTest('LEAVE-02: form pengajuan cuti terbuka & validasi submit kosong', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Izin & Cuti', screen: LeaveScreen);

    await waitFor(
      $,
      find.byKey(const ValueKey('add_leave_fab')),
      reason: 'FAB tambah cuti',
    );
    await $.tester.tap(find.byKey(const ValueKey('add_leave_fab')));
    await $.pump();
    await waitFor($, find.byType(CreateLeaveScreen), reason: 'CreateLeaveScreen');
    expect(find.text('Ajukan Cuti / Izin'), findsOneWidget);

    final submit = find.byKey(const ValueKey('submit_leave_btn'));
    await $.tester.ensureVisible(submit);
    expect(submit, findsOneWidget);

    // Submit tanpa mengisi apa pun TIDAK boleh menutup form (validasi gagal).
    await $.tester.tap(submit);
    await $.pump();
    await pumpFor($, const Duration(seconds: 1));
    expect(
      find.byType(CreateLeaveScreen),
      findsOneWidget,
      reason: 'Form tidak boleh tertutup saat input belum valid',
    );
    expect(
      find.byType(SnackBar),
      findsOneWidget,
      reason: 'Peringatan validasi harus tampil saat submit kosong',
    );
    await pumpFor($, const Duration(seconds: 5)); // tunggu snackbar hilang

    await goBack($);
    await waitFor($, find.byType(LeaveScreen), reason: 'kembali ke daftar cuti');
    await goBackToDashboard($);
  });
}
