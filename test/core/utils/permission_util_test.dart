import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionUtil Unit Tests', () {
    test('hasCameraPermission returns true in test environment', () async {
      final result = await PermissionUtil.hasCameraPermission();
      expect(result, isTrue);
    });

    test('requestCameraPermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestCameraPermission();
      expect(result.isGranted, isTrue);
      expect(result.isDenied, isFalse);
    });

    test('hasGalleryPermission returns true in test environment', () async {
      final result = await PermissionUtil.hasGalleryPermission();
      expect(result, isTrue);
    });

    test('requestGalleryPermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestGalleryPermission();
      expect(result.isGranted, isTrue);
    });

    test('hasDocumentStoragePermission returns true in test environment', () async {
      final result = await PermissionUtil.hasDocumentStoragePermission();
      expect(result, isTrue);
    });

    test('requestDocumentStoragePermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestDocumentStoragePermission();
      expect(result.isGranted, isTrue);
    });

    test('hasLocationPermission returns true in test environment', () async {
      final result = await PermissionUtil.hasLocationPermission();
      expect(result, isTrue);
    });

    test('requestLocationPermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestLocationPermission();
      expect(result.isGranted, isTrue);
    });

    test('requestBackgroundLocationPermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestBackgroundLocationPermission();
      expect(result.isGranted, isTrue);
    });

    test('hasNotificationPermission returns true in test environment', () async {
      final result = await PermissionUtil.hasNotificationPermission();
      expect(result, isTrue);
    });

    test('requestNotificationPermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestNotificationPermission();
      expect(result.isGranted, isTrue);
    });

    test('requestExactAlarmPermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestExactAlarmPermission();
      expect(result.isGranted, isTrue);
    });

    test('requestMicrophonePermission returns granted in test environment', () async {
      final result = await PermissionUtil.requestMicrophonePermission();
      expect(result.isGranted, isTrue);
    });

    test('openSettings executes cleanly in test environment', () async {
      final result = await PermissionUtil.openSettings();
      expect(result, isTrue);
    });
  });

  group('PermissionUtil Widget & Dialog Tests', () {
    testWidgets('shows and dismisses showPermissionDeniedDialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    PermissionUtil.showPermissionDeniedDialog(
                      context: context,
                      type: HrisPermissionType.camera,
                      title: 'Izin Kamera Diperlukan',
                      description: 'Silakan aktifkan izin kamera di Pengaturan.',
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check dialog elements
      expect(find.text('Izin Kamera Diperlukan'), findsOneWidget);
      expect(find.text('Silakan aktifkan izin kamera di Pengaturan.'), findsOneWidget);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
      expect(find.byIcon(LucideIcons.camera), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Nanti Saja'));
      await tester.pumpAndSettle();

      expect(find.text('Izin Kamera Diperlukan'), findsNothing);
    });

    testWidgets('requestAttendancePermissions runs successfully in widget tree', (
      WidgetTester tester,
    ) async {
      bool? granted;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    granted = await PermissionUtil.requestAttendancePermissions(
                      context: context,
                    );
                  },
                  child: const Text('Check In'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check In'));
      await tester.pumpAndSettle();

      expect(granted, isTrue);
    });

    testWidgets('requestActivityProofPermissions runs successfully in widget tree', (
      WidgetTester tester,
    ) async {
      bool? granted;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    granted = await PermissionUtil.requestActivityProofPermissions(
                      context: context,
                    );
                  },
                  child: const Text('Log Activity'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Log Activity'));
      await tester.pumpAndSettle();

      expect(granted, isTrue);
    });
  });
}
