import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Check dialog elements
      expect(find.text('Izin Kamera Diperlukan'), findsOneWidget);
      expect(find.text('Silakan aktifkan izin kamera di Pengaturan.'), findsOneWidget);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
      expect(find.byIcon(LucideIcons.camera), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Nanti Saja'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

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

  group('PermissionUtil Rationale Dialog Flow Tests', () {
    tearDown(() {
      PermissionUtil.bypassInTest = true;
      PermissionUtil.testPermissionStatusHandler = null;
      PermissionUtil.testPermissionRequestHandler = null;
    });

    testWidgets('shows rationale dialog for camera permission and handles deny', (
      WidgetTester tester,
    ) async {
      PermissionUtil.bypassInTest = false;
      PermissionUtil.testPermissionStatusHandler = (perm) async => false;

      HrisPermissionResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await PermissionUtil.requestCameraPermission(
                    context: context,
                    showRationale: true,
                  );
                },
                child: const Text('Request Camera'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Request Camera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Izin Kamera Diperlukan'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('permission_dialog_allow_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('permission_dialog_deny_button')),
        findsOneWidget,
      );

      // Tap Deny
      await tester.tap(
        find.byKey(const ValueKey('permission_dialog_deny_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.isGranted, isFalse);
      expect(find.text('Izin Kamera Diperlukan'), findsNothing);
    });

    testWidgets(
      'shows composite rationale dialog for attendance (location + camera) and allows',
      (WidgetTester tester) async {
        PermissionUtil.bypassInTest = false;
        PermissionUtil.testPermissionStatusHandler = (perm) async => false;
        PermissionUtil.testPermissionRequestHandler =
            (perm) async => PermissionStatus.granted;

        bool? granted;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    granted =
                        await PermissionUtil.requestAttendancePermissions(
                      context: context,
                      showRationale: true,
                    );
                  },
                  child: const Text('Start Attendance'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Start Attendance'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Izin Presensi Kehadiran'), findsOneWidget);
        expect(find.text('Lokasi & GPS'), findsOneWidget);
        expect(find.text('Kamera'), findsOneWidget);
        expect(find.text('Izinkan Semua'), findsOneWidget);

        // Tap Allow All
        await tester.tap(
          find.byKey(const ValueKey('permission_dialog_allow_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(granted, isTrue);
        expect(find.text('Izin Presensi Kehadiran'), findsNothing);
      },
    );
  });
}

