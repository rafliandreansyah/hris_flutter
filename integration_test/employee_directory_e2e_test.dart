import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('EMP-01/02: direktori pegawai, pencarian, dan filter', ($) async {
    await launchAndLogin($);
    await openMenu($, 'Pegawai', screen: EmployeeDirectoryScreen);

    expect(find.text('Employee Directory'), findsOneWidget);
    final hasData = await waitForListLoaded($, card: EmployeeCard);
    expectNoErrorState();
    expect(hasData, isTrue, reason: 'Direktori pegawai tidak boleh kosong');

    // Pencarian memunculkan hasil / empty state tanpa error.
    expect(find.byType(AppSearchBar), findsOneWidget);
    await $.tester.enterText(find.byType(AppSearchBar), 'a');
    await $.pump();
    await pumpFor($, const Duration(seconds: 2));
    await waitForListLoaded($, card: EmployeeCard);
    expectNoErrorState();
    expect(find.byType(EmployeeDirectoryScreen), findsOneWidget);

    await openAndCancelFilterSheet($);

    await goBackToDashboard($);
  });

  patrolTest('EMP-03: membuka detail pegawai dari kartu direktori', ($) async {
    await launchAndLogin($);
    await openMenu($, 'Pegawai', screen: EmployeeDirectoryScreen);

    final hasData = await waitForListLoaded($, card: EmployeeCard);
    expect(hasData, isTrue, reason: 'Direktori pegawai tidak boleh kosong');

    final target = find.byType(EmployeeCard).hitTestable();
    await $.tester.tap(target.first);
    await $.pump();
    await waitFor(
      $,
      find.byType(EmployeeDetailScreen),
      reason: 'EmployeeDetailScreen',
    );
    await pumpFor($, const Duration(seconds: 2));
    expectNoErrorState();

    await goBack($);
    await waitFor(
      $,
      find.byType(EmployeeDirectoryScreen),
      reason: 'kembali ke direktori',
    );
    await goBackToDashboard($);
  });
}
