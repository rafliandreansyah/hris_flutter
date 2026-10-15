import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/resignation/presentation/pages/create_resignation_screen.dart';
import 'package:hris_flutter/features/resignation/presentation/pages/resignation_screen.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_empty_state_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('RESIGN-01: layar pengunduran diri termuat tanpa error', ($) async {
    await launchAndLogin($);
    await openMenu($, 'Resign', screen: ResignationScreen);

    expect(find.text('Pengajuan Resign'), findsOneWidget);
    await pumpFor($, const Duration(seconds: 4));
    expectNoErrorState();

    // Tab approver hanya ada untuk atasan; bila ada harus bisa dibuka.
    if (isShown(find.text('Persetujuan Tim'))) {
      expect(find.text('Pengajuan Saya'), findsOneWidget);
      await tapTab($, 'Persetujuan Tim');
      await pumpFor($, const Duration(seconds: 3));
      expectNoErrorState();
      await tapTab($, 'Pengajuan Saya');
    }

    await goBackToDashboard($);
  });

  patrolTest('RESIGN-02: karyawan tanpa pengajuan bisa membuka form resign', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Resign', screen: ResignationScreen);
    await pumpFor($, const Duration(seconds: 4));

    final empty = find.byType(ResignationEmptyStateCard);
    if (empty.evaluate().isEmpty) {
      // Akun sudah punya pengajuan aktif: form baru memang tidak ditawarkan.
      return;
    }

    await $.tester.tap(find.text('Ajukan Pengunduran Diri'));
    await $.pump();
    await waitFor(
      $,
      find.byType(CreateResignationScreen),
      reason: 'CreateResignationScreen',
    );
    await pumpFor($, const Duration(seconds: 2));
    expect(find.text('Kirim Pengajuan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    await $.tester.ensureVisible(find.text('Batal'));
    await $.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.text('Batal'));
    await $.pump();
    await waitFor($, find.byType(ResignationScreen), reason: 'kembali ke resign');
    await goBackToDashboard($);
  });
}
