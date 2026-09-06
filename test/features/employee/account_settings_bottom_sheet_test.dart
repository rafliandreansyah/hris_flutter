import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/account_settings_bottom_sheet.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: AccountSettingsBottomSheet(avatarUrl: ''),
      ),
    );
  }

  testWidgets('AccountSettingsBottomSheet renders profile, menu, and version footer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Account Settings'), findsOneWidget);

    // Verify Profile Info
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Senior Frontend Engineer'), findsOneWidget);
    expect(find.text('EMP-2024-019'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // Verify Settings Section
    expect(find.text('PENGATURAN & PREFERENSI'), findsOneWidget);
    expect(find.text('Ganti Password'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Bahasa (Language)'), findsOneWidget);
    expect(find.text('ID (Bahasa)'), findsOneWidget);

    // Verify Logout card
    expect(find.text('Keluar dari Akun (Logout)'), findsOneWidget);

    // Verify Version Component is rendered
    expect(find.byType(AppNameVersionText), findsOneWidget);
  });

  testWidgets('Tapping Logout shows confirmation dialog', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap Logout button
    await tester.tap(find.text('Keluar dari Akun (Logout)'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Konfirmasi Logout'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin keluar dari sesi akun ini?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // Tap Batal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Logout'), findsNothing);
  });
}
