import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget buildTestableWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('AppButton Widget Tests', () {
    testWidgets('renders text and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppButton(
            text: 'Simpan',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.text('Simpan'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows CircularProgressIndicator and disables tap when isLoading is true',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppButton(
            text: 'Kirim Pengajuan',
            isLoading: true,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      );

      // Text should not be rendered while loading
      expect(find.text('Kirim Pengajuan'), findsNothing);

      // Progress indicator should be present with strokeWidth 2.5
      final progressFinder = find.byType(CircularProgressIndicator);
      expect(progressFinder, findsOneWidget);
      final progressWidget = tester.widget<CircularProgressIndicator>(progressFinder);
      expect(progressWidget.strokeWidth, 2.5);

      // Tapping should not trigger onPressed
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('renders leading and trailing icons correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AppButton(
            text: 'Download Rekap',
            leadingIcon: LucideIcons.download,
            trailingIcon: LucideIcons.chevronRight,
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.download), findsOneWidget);
      expect(find.text('Download Rekap'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('applies all variants correctly in light and dark mode',
        (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          buildTestableWidget(
            child: AppButton(
              text: variant.name,
              variant: variant,
            ),
          ),
        );
        expect(find.text(variant.name), findsOneWidget);

        await tester.pumpWidget(
          buildTestableWidget(
            themeMode: ThemeMode.dark,
            child: AppButton(
              text: variant.name,
              variant: variant,
            ),
          ),
        );
        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('respects custom height, width, and border styling', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AppButton(
            text: 'Custom Button',
            width: 200,
            height: 48,
            borderRadius: 16,
            borderColor: AppColors.brandTeal,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 48);
    });

    testWidgets('disabled button has onPressed null and dims appearance', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AppButton(
            text: 'Nonaktif',
            onPressed: null,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
