import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/announcement_detail_screen.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/announcement_list_screen.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('ANN-01/02: See All membuka daftar pengumuman, detail, dan filter', (
    $,
  ) async {
    await launchAndLogin($);

    final seeAll = find.text('See All').hitTestable();
    expect(
      seeAll,
      findsOneWidget,
      reason: 'Tombol "See All" pada feed update tidak tampil untuk akun E2E',
    );
    await $.tester.ensureVisible(seeAll);
    await $.pump(const Duration(milliseconds: 300));
    await $.tester.tap(seeAll);
    await $.pump();
    await waitFor(
      $,
      find.byType(AnnouncementListScreen),
      reason: 'AnnouncementListScreen',
    );
    expect(find.text('Pengumuman'), findsWidgets);

    final hasData = await waitForListLoaded($, card: AnnouncementCard);
    expectNoErrorState();
    if (hasData) {
      final target = find.byType(AnnouncementCard).hitTestable();
      await $.tester.tap(target.first);
      await $.pump();
      await waitFor(
        $,
        find.byType(AnnouncementDetailScreen),
        reason: 'AnnouncementDetailScreen',
      );
      await pumpFor($, const Duration(seconds: 2));
      expectNoErrorState();
      await goBack($);
      await waitFor(
        $,
        find.byType(AnnouncementListScreen),
        reason: 'kembali ke daftar pengumuman',
      );
    }

    await openAndCancelFilterSheet($);
    await goBackToDashboard($);
  });
}
