import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/warning_letter/presentation/pages/warning_letter_detail_screen.dart';
import 'package:hris_flutter/features/warning_letter/presentation/pages/warning_letter_screen.dart';
import 'package:hris_flutter/features/warning_letter/presentation/widgets/warning_letter_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('SP-01/02/03: daftar, tab, detail, dan filter surat peringatan', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Surat Peringatan', screen: WarningLetterScreen);

    expect(find.text('Surat Peringatan'), findsWidgets);
    expect(find.text('Surat Diterima'), findsOneWidget);
    expect(find.text('Diterbitkan'), findsOneWidget);

    // Tab Surat Diterima
    var hasData = await waitForListLoaded($, card: WarningLetterCard);
    expectNoErrorState();
    if (hasData) {
      await _openFirstLetter($);
    }

    // Tab Diterbitkan
    await tapTab($, 'Diterbitkan');
    hasData = await waitForListLoaded($, card: WarningLetterCard);
    expectNoErrorState();
    if (hasData) {
      await _openFirstLetter($);
    }

    await tapTab($, 'Surat Diterima');
    await openAndCancelFilterSheet($);

    await goBackToDashboard($);
  });
}

Future<void> _openFirstLetter(PatrolIntegrationTester $) async {
  final target = find.byType(WarningLetterCard).hitTestable();
  await $.tester.ensureVisible(target.first);
  await $.pump(const Duration(milliseconds: 300));
  await $.tester.tap(target.first);
  await $.pump();
  await waitFor(
    $,
    find.byType(WarningLetterDetailScreen),
    reason: 'WarningLetterDetailScreen',
  );
  await pumpFor($, const Duration(seconds: 1));
  expectNoErrorState();
  await goBack($);
  await waitFor($, find.byType(WarningLetterScreen), reason: 'kembali ke daftar');
}
