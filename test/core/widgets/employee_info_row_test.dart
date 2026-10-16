import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
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

  group('EmployeeInfoRow Widget Tests', () {
    testWidgets('renders correctly using individual fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const EmployeeInfoRow(
            name: 'Sarah Connor',
            role: 'Lead Mobile Engineer',
            department: 'Mobile Tech',
            company: 'PT Oasish Digital Solution',
            employeeId: 'EMP-9021',
            avatarSize: 44,
          ),
        ),
      );

      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('Lead Mobile Engineer • Mobile Tech'), findsOneWidget);
      expect(find.text('EMP-9021'), findsOneWidget);
      expect(find.text('PT Oasish Digital Solution'), findsOneWidget);
      expect(find.byIcon(LucideIcons.idCard), findsOneWidget);
      expect(find.byType(AppAvatar), findsOneWidget);
    });

    testWidgets('renders correctly using EmployeeDirectoryItem model', (tester) async {
      const item = EmployeeDirectoryItem(
        id: 'uuid-1234',
        employeeNumber: 'NIP-8888',
        name: 'John Doe',
        role: 'DevOps Specialist',
        department: 'Infrastructure',
        company: 'PT Global Indo',
        email: 'john@example.com',
        phone: '08123456789',
        avatarUrl: null,
        initials: 'JD',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const EmployeeInfoRow(
            employee: item,
            avatarSize: 40,
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('DevOps Specialist • Infrastructure'), findsOneWidget);
      expect(find.text('NIP-8888'), findsOneWidget);
      expect(find.text('PT Global Indo'), findsOneWidget);
    });

    testWidgets('omits company badge and ID badge when they are absent', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const EmployeeInfoRow(
            name: 'Jane Doe',
            role: 'Product Designer',
          ),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Product Designer'), findsOneWidget);
      expect(find.byIcon(LucideIcons.idCard), findsNothing);
    });

    testWidgets('uses employee id fallback when employeeNumber is null or empty in model',
        (tester) async {
      const item = EmployeeDirectoryItem(
        id: 'ID-ONLY-99',
        employeeNumber: '',
        name: 'Alex Mercer',
        role: 'Security Analyst',
        department: 'Cybersec',
        company: null,
        email: 'alex@example.com',
        initials: 'AM',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const EmployeeInfoRow(employee: item),
        ),
      );

      expect(find.text('ID-ONLY-99'), findsOneWidget);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          themeMode: ThemeMode.dark,
          child: const EmployeeInfoRow(
            name: 'Dark User',
            role: 'Tester',
            department: 'QA',
            company: 'Dark Corp',
            employeeId: 'EMP-001',
          ),
        ),
      );

      expect(find.text('Dark User'), findsOneWidget);
      expect(find.text('Tester • QA'), findsOneWidget);
      expect(find.text('EMP-001'), findsOneWidget);
      expect(find.text('Dark Corp'), findsOneWidget);
    });
  });
}
