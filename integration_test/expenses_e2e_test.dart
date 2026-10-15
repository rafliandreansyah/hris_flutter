import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/cash_advance_detail_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/create_cash_advance_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/create_reimbursement_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/expenses_list_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/reimbursement_detail_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/expense_request_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('EXP-01/03/04: daftar, tab, detail, dan filter klaim & kasbon', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Klaim & Kasbon', screen: ExpensesListScreen);

    await verifyRequestModule(
      $,
      screen: ExpensesListScreen,
      screenTitle: 'Klaim & Kasbon',
      card: ExpenseRequestCard,
      detailScreens: const [ReimbursementDetailScreen, CashAdvanceDetailScreen],
    );

    await goBackToDashboard($);
  });

  patrolTest('EXP-02: chip filter tipe Semua/Reimbursement/Kasbon bisa dipilih', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Klaim & Kasbon', screen: ExpensesListScreen);

    for (final chip in ['Reimbursement', 'Kasbon', 'Semua']) {
      final target = find.text(chip).hitTestable();
      expect(target, findsWidgets, reason: 'Chip "$chip" harus tampil');
      await $.tester.tap(target.first);
      await $.pump();
      await pumpFor($, const Duration(seconds: 1));
      await waitForListLoaded($, card: ExpenseRequestCard);
      expectNoErrorState();
    }

    await goBackToDashboard($);
  });

  patrolTest('EXP-05: FAB "Ajukan" membuka form Reimbursement & Kasbon', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Klaim & Kasbon', screen: ExpensesListScreen);

    // Reimbursement
    await $.tester.tap(find.byKey(const ValueKey('add_reimbursement_fab')));
    await $.pump();
    await waitFor($, find.text('Buat Pengajuan Baru'), reason: 'sheet aksi');
    expect(find.text('Ajukan Kasbon (Cash Advance)'), findsOneWidget);
    await $.tester.tap(find.text('Ajukan Reimbursement'));
    await $.pump();
    await waitFor(
      $,
      find.byType(CreateReimbursementScreen),
      reason: 'CreateReimbursementScreen',
    );
    await goBack($);
    await waitFor($, find.byType(ExpensesListScreen), reason: 'kembali ke daftar');

    // Kasbon
    await $.tester.tap(find.byKey(const ValueKey('add_reimbursement_fab')));
    await $.pump();
    await waitFor($, find.text('Buat Pengajuan Baru'), reason: 'sheet aksi');
    await $.tester.tap(find.text('Ajukan Kasbon (Cash Advance)'));
    await $.pump();
    await waitFor(
      $,
      find.byType(CreateCashAdvanceScreen),
      reason: 'CreateCashAdvanceScreen',
    );
    await goBack($);
    await waitFor($, find.byType(ExpensesListScreen), reason: 'kembali ke daftar');

    await goBackToDashboard($);
  });
}
