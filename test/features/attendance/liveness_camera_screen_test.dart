import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/liveness_camera_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget buildTestableWidget({String title = 'Verifikasi Wajah Liveness AI'}) {
    return MaterialApp(
      home: LivenessCameraScreen(title: title),
    );
  }

  group('LivenessCameraScreen Widget Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('renders title, close button, instruction text, and loading progress', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Verifikasi Wajah Liveness AI'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.text('Posisikan wajah Anda di dalam lingkaran'), findsOneWidget);
      expect(find.text('Belum Pas'), findsOneWidget);
      expect(find.text('Wajah terdeteksi'), findsOneWidget);
      expect(find.text('Jarak pas'), findsOneWidget);
      expect(find.text('Di tengah & lurus'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders custom title when provided', (tester) async {
      await tester.pumpWidget(buildTestableWidget(title: 'Selfie Check-In Lapangan'));
      await tester.pump();

      expect(find.text('Selfie Check-In Lapangan'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('close button has accessible tooltip and instruction is a live region', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byTooltip('Tutup'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Posisikan wajah Anda di dalam lingkaran'),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.liveRegion ?? false),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('lays out on a small phone with large text without overflow', (tester) async {
      final view = tester.view;
      view.physicalSize = const Size(375, 667);
      view.devicePixelRatio = 1.0;
      view.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(view.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Di tengah & lurus'), findsOneWidget);
    });
  });
}
