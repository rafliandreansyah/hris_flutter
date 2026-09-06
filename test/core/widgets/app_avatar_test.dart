import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';

void main() {
  group('AppAvatar Unit Tests', () {
    test('extractInitials extracts initials accurately', () {
      expect(AppAvatar.extractInitials('Sarah Jenkins'), equals('SJ'));
      expect(AppAvatar.extractInitials('John Doe'), equals('JD'));
      expect(AppAvatar.extractInitials('Budi'), equals('BU'));
      expect(AppAvatar.extractInitials('A'), equals('A'));
      expect(AppAvatar.extractInitials(''), equals('?'));
      expect(AppAvatar.extractInitials(null), equals('?'));
      expect(AppAvatar.extractInitials('Muhammad Rafli Andreansyah'), equals('MR'));
      expect(
        AppAvatar.extractInitials('Budi', explicitInitials: 'BS'),
        equals('BS'),
      );
    });
  });

  group('AppAvatar Widget Tests', () {
    testWidgets('renders initials when imageUrl is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              name: 'Sarah Jenkins',
              size: 48,
            ),
          ),
        ),
      );

      expect(find.text('SJ'), findsOneWidget);
    });

    testWidgets('renders explicit initials when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              name: 'Sarah Jenkins',
              initials: 'XX',
              size: 48,
            ),
          ),
        ),
      );

      expect(find.text('XX'), findsOneWidget);
    });

    testWidgets('renders fallback question mark when name and initials are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              size: 48,
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders Image.network when imageUrl is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: 'https://example.com/avatar.png',
              name: 'John Doe',
              size: 50,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
