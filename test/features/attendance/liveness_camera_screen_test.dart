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
      expect(find.text('Posisikan wajah Anda di dalam bingkai oval'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders custom title when provided', (tester) async {
      await tester.pumpWidget(buildTestableWidget(title: 'Selfie Check-In Lapangan'));
      await tester.pump();

      expect(find.text('Selfie Check-In Lapangan'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });
  });
}
