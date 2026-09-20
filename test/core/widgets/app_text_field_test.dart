import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';

void main() {
  group('AppTextField Widget Tests', () {
    testWidgets('renders label and hintText correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Nama Lengkap',
              hintText: 'Masukkan nama Anda...',
            ),
          ),
        ),
      );

      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Masukkan nama Anda...'), findsOneWidget);
    });

    testWidgets('unfocuses keyboard when tapping outside', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(
                  key: const ValueKey('outside_area'),
                  color: Colors.blue,
                  height: 100,
                  width: double.infinity,
                ),
                AppTextField(
                  focusNode: focusNode,
                  hintText: 'Ketik sesuatu...',
                ),
              ],
            ),
          ),
        ),
      );

      // Focus the text field
      await tester.tap(find.byType(AppTextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Tap outside the text field
      await tester.tap(find.byKey(const ValueKey('outside_area')));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('supports custom onTapOutside callback', (tester) async {
      bool customCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(
                  key: const ValueKey('outside_area'),
                  color: Colors.blue,
                  height: 100,
                  width: double.infinity,
                ),
                AppTextField(
                  hintText: 'Ketik sesuatu...',
                  onTapOutside: (event) {
                    customCalled = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppTextField));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('outside_area')));
      await tester.pump();

      expect(customCalled, isTrue);
    });
  });
}
