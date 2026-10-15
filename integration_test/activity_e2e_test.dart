import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_detail_screen.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_screen.dart';
import 'package:hris_flutter/features/activity/presentation/pages/create_activity_screen.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('ACT-01/03/04: daftar, tab Saya/Tim, detail, dan filter aktivitas', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Aktivitas', screen: ActivityScreen);

    expect(find.text('Activity Reports'), findsOneWidget);
    expect(find.text('Saya'), findsWidgets);
    expect(find.text('Tim Saya'), findsOneWidget);

    var hasData = await waitForListLoaded($, card: ActivityCard);
    expectNoErrorState();
    if (hasData) {
      await _openFirstActivity($);
    }

    await tapTab($, 'Tim Saya');
    hasData = await waitForListLoaded($, card: ActivityCard);
    expectNoErrorState();
    if (hasData) {
      await _openFirstActivity($);
    }

    await tapTab($, 'Saya');
    await openAndCancelFilterSheet($);

    await goBackToDashboard($);
  });

  patrolTest('ACT-02: FAB membuka form buat aktivitas (langsung / via pilihan)', (
    $,
  ) async {
    await launchAndLogin($);
    await openMenu($, 'Aktivitas', screen: ActivityScreen);

    await $.tester.tap(find.byKey(const ValueKey('add_activity_fab')));
    await $.pump();

    // Akun dengan izin activity.manage melihat sheet pilihan target dulu.
    var elapsed = Duration.zero;
    while (!isShown(find.byType(CreateActivityScreen)) &&
        !isShown(find.text('Buat Aktivitas'))) {
      if (elapsed >= const Duration(seconds: 15)) {
        fail('Tidak ada form/sheet pembuatan aktivitas setelah menekan FAB');
      }
      await $.pump(const Duration(milliseconds: 250));
      elapsed += const Duration(milliseconds: 250);
    }
    if (isShown(find.text('Buat Aktivitas'))) {
      expect(
        find.byKey(const ValueKey('create_self_activity_option')),
        findsOneWidget,
      );
      await $.tester.tap(find.byKey(const ValueKey('create_self_activity_option')));
      await $.pump();
    }
    await waitFor(
      $,
      find.byType(CreateActivityScreen),
      reason: 'CreateActivityScreen',
    );

    await goBack($);
    await waitFor($, find.byType(ActivityScreen), reason: 'kembali ke aktivitas');
    await goBackToDashboard($);
  });
}

Future<void> _openFirstActivity(PatrolIntegrationTester $) async {
  final target = find.byType(ActivityCard).hitTestable();
  await $.tester.ensureVisible(target.first);
  await $.pump(const Duration(milliseconds: 300));
  await $.tester.tap(target.first);
  await $.pump();
  await waitFor(
    $,
    find.byType(ActivityDetailScreen),
    reason: 'ActivityDetailScreen',
  );
  expect(find.text('Activity Detail'), findsOneWidget);
  await goBack($);
  await waitFor($, find.byType(ActivityScreen), reason: 'kembali ke daftar');
}
