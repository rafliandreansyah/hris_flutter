import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:patrol/patrol.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  patrolTest(
    'Smoke: aplikasi terbuka, izin native ditangani, lalu Login/Dashboard tampil',
    ($) async {
      await launchApp($);

      expect(
        find.byType(LoginScreen).evaluate().isNotEmpty ||
            find.byType(DashboardScreen).evaluate().isNotEmpty,
        isTrue,
        reason: 'Layar awal harus LoginScreen atau DashboardScreen',
      );
    },
  );
}
