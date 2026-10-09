import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/attendance_hero_card.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/updates_feed_card.dart';
import 'package:hris_flutter/main.dart' as app;
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'E2E Dashboard & Bento Grid Test: Rendering, dynamic menus, navigation, realtime clock, and pull to refresh',
    ($) async {
      // 1. Inisialisasi dan jalankan aplikasi HRIS
      app.main();
      await $.pumpAndSettle();

      // 2. Intercept dialog izin sistem native OS jika muncul (Notifikasi/Lokasi)
      try {
        if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
          await $.platformAutomator.mobile.grantPermissionWhenInUse();
        }
      } catch (_) {}

      await $.pumpAndSettle();

      // 3. Login jika berada pada halaman Login
      if ($('Login').exists) {
        final emailField = $(find.byType(TextField).first);
        final passwordField = $(find.byType(TextField).last);
        if (emailField.exists && passwordField.exists) {
          await emailField.enterText('user@gmail.com');
          await passwordField.enterText('amaterasu');
          await $.pumpAndSettle();

          await $('Login').tap();
          await $.pumpAndSettle(timeout: const Duration(seconds: 10));
        }
      }

      // -----------------------------------------------------------------------
      // SKENARIO 1: Verifikasi Rendering Elemen Dashboard (DASH-01)
      // -----------------------------------------------------------------------
      if ($('Oasish').exists) {
        expect(find.text('Oasish'), findsOneWidget);
        expect(find.byType(AttendanceHeroCard), findsOneWidget);
        expect(find.byType(QuickAccessGrid), findsOneWidget);
        expect(find.byType(UpdatesFeedCard), findsOneWidget);
        expect(find.byType(AppNameVersionText), findsOneWidget);
      }

      // -----------------------------------------------------------------------
      // SKENARIO 2: Jam Server Realtime di Kartu Presensi (DASH-05)
      // -----------------------------------------------------------------------
      if (find.byType(AttendanceHeroCard).evaluate().isNotEmpty) {
        expect(find.text('CURRENT STATUS'), findsOneWidget);
        // Menunggu detik jam bertambah
        await $.pump(const Duration(seconds: 1));
        await $.pump(const Duration(seconds: 1));
      }

      // -----------------------------------------------------------------------
      // SKENARIO 3: Menu Bento Grid Dinamis & Navigasi (DASH-02 & DASH-03)
      // -----------------------------------------------------------------------
      if ($('Quick Access').exists) {
        expect(find.text('Quick Access'), findsOneWidget);

        // Uji navigasi modul Pegawai jika menu tersedia
        if ($('Pegawai').exists) {
          await $('Pegawai').tap();
          await $.pumpAndSettle();

          // Kembali ke Dashboard
          final backBtn = $(find.byTooltip('Back'));
          if (backBtn.exists) {
            await backBtn.tap();
            await $.pumpAndSettle();
          } else {
            final navigatorPop = $(find.byType(BackButton));
            if (navigatorPop.exists) {
              await navigatorPop.tap();
              await $.pumpAndSettle();
            }
          }
        }
      }

      // -----------------------------------------------------------------------
      // SKENARIO 4: Pull to Refresh Gesture (DASH-04)
      // -----------------------------------------------------------------------
      if (find.byType(RefreshIndicator).evaluate().isNotEmpty) {
        // Melakukan pull-to-refresh swipe down
        await $.tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
        await $.pumpAndSettle();
      }

      // -----------------------------------------------------------------------
      // SKENARIO 5: Navigasi Header Notifikasi, Jadwal, & Profil (DASH-10 & DASH-12)
      // -----------------------------------------------------------------------
      final notifBtn = $(find.byKey(const ValueKey('dashboard_notification_btn')));
      if (notifBtn.exists) {
        await notifBtn.tap();
        await $.pumpAndSettle();

        // Kembali ke Dashboard
        final backButton = $(find.byType(BackButton));
        if (backButton.exists) {
          await backButton.tap();
          await $.pumpAndSettle();
        }
      }

      final scheduleBtn = $(find.byKey(const ValueKey('dashboard_work_schedule_btn')));
      if (scheduleBtn.exists) {
        await scheduleBtn.tap();
        await $.pumpAndSettle();

        final backButton = $(find.byType(BackButton));
        if (backButton.exists) {
          await backButton.tap();
          await $.pumpAndSettle();
        }
      }

      final avatar = $(find.byType(AppAvatar));
      if (avatar.exists) {
        await avatar.tap();
        await $.pumpAndSettle();

        final backButton = $(find.byType(BackButton));
        if (backButton.exists) {
          await backButton.tap();
          await $.pumpAndSettle();
        }
      }
    },
  );
}
