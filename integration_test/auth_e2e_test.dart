import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest('AUTH-03: login dengan form kosong menampilkan error validasi', (
    $,
  ) async {
    await launchApp($);
    expect(
      find.byType(LoginScreen),
      findsOneWidget,
      reason: 'Test auth harus mulai tanpa sesi (data app dibersihkan).',
    );

    await $.tester.tap(find.text('Login'));
    await $.pump();
    await pumpFor($, const Duration(milliseconds: 500));

    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    expect(find.text('Password tidak boleh kosong'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  patrolTest('AUTH-05: ikon mata mengganti visibilitas password', ($) async {
    await launchApp($);
    expect(find.byType(LoginScreen), findsOneWidget);

    await $.tester.enterText(find.byType(TextField).last, 'secretpassword');
    await $.pump();

    expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    await $.tester.tap(find.byIcon(LucideIcons.eye));
    await $.pump();
    expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
    expect(find.byIcon(LucideIcons.eye), findsNothing);

    await $.tester.tap(find.byIcon(LucideIcons.eyeOff));
    await $.pump();
    expect(find.byIcon(LucideIcons.eye), findsOneWidget);
  });

  patrolTest('AUTH-06: navigasi Lupa Password lalu kembali ke Login', (
    $,
  ) async {
    await launchApp($);
    expect(find.byType(LoginScreen), findsOneWidget);

    await $.tester.tap(find.text('Forgot Password?'));
    await $.pump();
    await waitFor($, find.text('Back to Login'), reason: 'layar Reset Password');
    expect(find.text('Reset Password'), findsWidgets);

    await $.tester.tap(find.text('Back to Login'));
    await $.pump();
    await waitFor($, find.text('Welcome Back'), reason: 'kembali ke Login');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  patrolTest('AUTH-04: kredensial salah menampilkan dialog "Login Gagal"', (
    $,
  ) async {
    await launchApp($);
    expect(find.byType(LoginScreen), findsOneWidget);
    E2EConfig.ensureCredentials();

    await $.tester.enterText(find.byType(TextField).first, E2EConfig.email);
    await $.tester.enterText(
      find.byType(TextField).last,
      '${E2EConfig.password}-SALAH-!',
    );
    await $.pump();
    await $.tester.tap(find.text('Login'));
    await $.pump();

    await waitFor($, find.text('Login Gagal'), reason: 'dialog error login');
    expect(find.byType(DashboardScreen), findsNothing);

    await $.tester.tap(find.text('Tutup'));
    await $.pump();
    await waitGone(
      $,
      find.text('Login Gagal'),
      reason: 'dialog tertutup',
      timeout: const Duration(seconds: 5),
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  patrolTest('AUTH-01: login valid mengarah ke Dashboard', ($) async {
    await launchApp($);
    expect(find.byType(LoginScreen), findsOneWidget);

    await loginIfNeeded($);

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
