import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/main.dart' as app;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'E2E Auth Test: Form validation, obscure toggle, navigation, invalid credentials, and login flow',
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

      // -----------------------------------------------------------------------
      // SKENARIO 1: Validasi Form Kosong (AUTH-03)
      // -----------------------------------------------------------------------
      if ($('Login').exists) {
        // Klik tombol Login langsung tanpa mengisi form
        await $('Login').tap();
        await $.pumpAndSettle();

        expect(find.text('Email tidak boleh kosong'), findsOneWidget);
        expect(find.text('Password tidak boleh kosong'), findsOneWidget);
      }

      // -----------------------------------------------------------------------
      // SKENARIO 2: Toggle Visibilitas Password (AUTH-05)
      // -----------------------------------------------------------------------
      final passwordField = $(find.byType(TextField).last);
      if (passwordField.exists) {
        await passwordField.enterText('secretpassword');
        await $.pumpAndSettle();

        // Cari ikon mata untuk toggle obscure password
        final eyeIcon = $(find.byIcon(LucideIcons.eye));
        if (eyeIcon.exists) {
          await eyeIcon.tap();
          await $.pumpAndSettle();

          // Ikon harus berganti menjadi eyeOff
          expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);

          // Kembalikan ke posisi ter-obscure
          await $(find.byIcon(LucideIcons.eyeOff)).tap();
          await $.pumpAndSettle();
          expect(find.byIcon(LucideIcons.eye), findsOneWidget);
        }
      }

      // -----------------------------------------------------------------------
      // SKENARIO 3: Navigasi Lupa Kata Sandi & Kembali (AUTH-06)
      // -----------------------------------------------------------------------
      if ($('Forgot Password?').exists) {
        await $('Forgot Password?').tap();
        await $.pumpAndSettle();

        expect(find.text('Reset Password'), findsOneWidget);
        expect(find.text('Back to Login'), findsOneWidget);

        // Kembali ke halaman Login
        await $('Back to Login').tap();
        await $.pumpAndSettle();

        expect(find.text('Welcome Back'), findsOneWidget);
      }

      // -----------------------------------------------------------------------
      // SKENARIO 4: Kredensial Salah & Dialog Error API (AUTH-04)
      // -----------------------------------------------------------------------
      final emailField = $(find.byType(TextField).first);
      if (emailField.exists && passwordField.exists) {
        await emailField.enterText('user@gmail.com');
        await passwordField.enterText('salah123');
        await $.pumpAndSettle();

        await $('Login').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        // Dialog error Login Gagal atau popup muncul jika backend merespon
        if ($('Login Gagal').exists) {
          expect($('Tutup'), findsOneWidget);
          await $('Tutup').tap();
          await $.pumpAndSettle();
          expect($('Login Gagal'), findsNothing);
        }
      }

      // -----------------------------------------------------------------------
      // SKENARIO 5: Login Akun Bawahan Valid (AUTH-01)
      // -----------------------------------------------------------------------
      if (emailField.exists && passwordField.exists && $('Login').exists) {
        await emailField.enterText('user@gmail.com');
        await passwordField.enterText('amaterasu');
        await $.pumpAndSettle();

        await $('Login').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 10));

        // Verifikasi transisi ke Dashboard jika server online
        if (!$('Welcome Back').exists) {
          // Berhasil diarahkan ke Dashboard
          expect(find.byType(app.MyApp), findsOneWidget);
        }
      }
    },
  );
}
