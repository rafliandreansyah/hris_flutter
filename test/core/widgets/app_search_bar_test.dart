import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
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

  group('AppSearchBar Widget Tests', () {
    testWidgets('renders default hint and search icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AppSearchBar(),
        ),
      );

      expect(find.text('Cari...'), findsOneWidget);
      expect(find.byIcon(LucideIcons.search), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsNothing);
    });

    testWidgets('renders custom hintText', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const AppSearchBar(hintText: 'Cari nama pegawai...'),
        ),
      );

      expect(find.text('Cari nama pegawai...'), findsOneWidget);
    });

    testWidgets('typing invokes onChanged and shows clear button', (tester) async {
      String changedText = '';

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSearchBar(
            onChanged: (val) {
              changedText = val;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Budi');
      await tester.pump();

      expect(changedText, 'Budi');
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('tapping clear button clears text and fires callbacks', (tester) async {
      final controller = TextEditingController(text: 'Initial Query');
      bool clearCalled = false;
      String changedText = 'Initial Query';

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSearchBar(
            controller: controller,
            onChanged: (val) => changedText = val,
            onClear: () => clearCalled = true,
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changedText, isEmpty);
      expect(clearCalled, isTrue);
      expect(find.byIcon(LucideIcons.x), findsNothing);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSearchBar(
            trailing: IconButton(
              icon: const Icon(LucideIcons.filter),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.filter), findsOneWidget);
    });

    testWidgets('adapts to dark mode styling', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          themeMode: ThemeMode.dark,
          child: const AppSearchBar(),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('handles external controller updates dynamically', (tester) async {
      final controller = TextEditingController(text: 'Initial');

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSearchBar(controller: controller),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);

      controller.text = 'Updated';
      await tester.pump();

      expect(find.text('Updated'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });
  });
}
