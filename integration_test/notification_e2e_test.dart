import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/notification/presentation/pages/notification_screen.dart';
import 'package:hris_flutter/features/notification/presentation/widgets/notification_item_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('NOTIF-01: tombol bell membuka daftar notifikasi tanpa error', (
    $,
  ) async {
    await launchAndLogin($);

    await $.tester.tap(find.byKey(const ValueKey('dashboard_notification_btn')));
    await $.pump();
    await waitFor($, find.byType(NotificationScreen), reason: 'NotificationScreen');
    expect(find.text('Notifikasi'), findsOneWidget);

    await waitForListLoaded($, card: NotificationItemCard);
    expect(find.text('Gagal Memuat Notifikasi'), findsNothing);

    // Tombol "Tandai Dibaca" hanya muncul bila ada notifikasi belum dibaca;
    // aksinya sengaja tidak dijalankan karena mengubah data nyata.
    await goBack($);
    await waitGone(
      $,
      find.byType(NotificationScreen),
      reason: 'keluar dari NotificationScreen',
      timeout: const Duration(seconds: 10),
    );
  });
}
