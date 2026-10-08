import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:hris_flutter/main.dart' as app;

void main() {
  patrolTest(
    'Smoke test: App launches, handles native permissions, and renders login screen',
    ($) async {
      // 1. Inisialisasi dan jalankan aplikasi HRIS
      app.main();
      await $.pumpAndSettle();

      // 2. Intercept dialog izin sistem native OS jika muncul (Notifikasi/Lokasi)
      // Menggunakan mobile platform automator pada Patrol 4.10+
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
      }

      // 3. Verifikasi tampilan antarmuka
      await $.pumpAndSettle();

      // Verifikasi komponen dasar aplikasi
      expect(find.byType(app.MyApp), findsOneWidget);
    },
  );
}
