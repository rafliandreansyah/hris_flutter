import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/filter/app_filter_sheet_frame.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('AppFilterSheetFrame', () {
    testWidgets('header berisi judul + close, footer Reset & Terapkan Filter',
        (tester) async {
      var resetCount = 0;
      var applyCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFilterSheetFrame(
              title: 'Filter Uji',
              onReset: () => resetCount++,
              onApply: () => applyCount++,
              child: const Text('Konten Filter'),
            ),
          ),
        ),
      );

      expect(find.text('Filter Uji'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsNothing);
      expect(find.text('Batal'), findsNothing);
      expect(find.text('Konten Filter'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.tap(find.text('Terapkan Filter'));
      expect(resetCount, 1);
      expect(applyCount, 1);
    });

    testWidgets('tombol close menutup bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AppFilterSheetFrame(
                    title: 'Filter Uji',
                    onReset: () {},
                    onApply: () {},
                    child: const SizedBox(height: 40),
                  ),
                ),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(find.text('Filter Uji'), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.text('Filter Uji'), findsNothing);
    });
  });
}
