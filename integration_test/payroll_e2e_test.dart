import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/payroll/presentation/pages/payroll_detail_screen.dart';
import 'package:hris_flutter/features/payroll/presentation/pages/payroll_screen.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_employee_card.dart';
import 'package:hris_flutter/features/payroll/presentation/widgets/payroll_slip_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('PAY-01/02/03: slip gaji saya, detail, dan filter', ($) async {
    await launchAndLogin($);
    await openMenu($, 'Slip Gaji', screen: PayrollScreen);

    expect(find.text('Slip Gaji'), findsWidgets);
    expect(find.text('Slip Saya'), findsOneWidget);

    final hasData = await waitForListLoaded($, card: PayrollSlipCard);
    expectNoErrorState();

    if (hasData) {
      final target = find.byType(PayrollSlipCard).hitTestable();
      await $.tester.ensureVisible(target.first);
      await $.pump(const Duration(milliseconds: 300));
      await $.tester.tap(target.first);
      await $.pump();
      await waitFor($, find.byType(PayrollDetailScreen), reason: 'PayrollDetailScreen');
      await pumpFor($, const Duration(seconds: 2));
      expectNoErrorState();
      await goBack($);
      await waitFor($, find.byType(PayrollScreen), reason: 'kembali ke slip gaji');
    }

    await openAndCancelFilterSheet($);
    await goBackToDashboard($);
  });

  patrolTest('PAY-04: tab Semua Pegawai (khusus HR) termuat tanpa error', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Slip Gaji', screen: PayrollScreen);

    if (!isShown(find.text('Semua Pegawai'))) {
      // Akun tanpa izin payroll tim: tab memang tidak ditampilkan.
      await goBackToDashboard($);
      return;
    }

    await tapTab($, 'Semua Pegawai');
    await waitForListLoaded($, card: PayrollEmployeeCard);
    expectNoErrorState();

    await tapTab($, 'Slip Saya');
    await goBackToDashboard($);
  });
}
