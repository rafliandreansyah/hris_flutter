import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('Employee Directory Tests', () {
    const testEmployees = [
      EmployeeDirectoryItem(
        id: 'EMP-092',
        name: 'Sarah Jenkins',
        role: 'Senior Frontend Engineer',
        department: 'Engineering',
        email: 's.jenkins@oasis.corp',
        phone: '+62 812-3456-7890',
        initials: 'SJ',
      ),
      EmployeeDirectoryItem(
        id: 'EMP-145',
        name: 'Budi Santoso',
        role: 'Site Operations Supervisor',
        department: 'Operations',
        email: 'b.santoso@oasis.corp',
        phone: '+62 813-9876-5432',
        initials: 'BS',
      ),
      EmployeeDirectoryItem(
        id: 'EMP-003',
        name: 'Jessica Pranata',
        role: 'Head of People & Culture',
        department: 'Human Resources',
        email: 'j.pranata@oasis.corp',
        phone: '+62 811-2233-4455',
        initials: 'JP',
      ),
    ];

    testWidgets('EmployeeDirectoryScreen renders all Stitch components properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmployeeDirectoryScreen(customEmployees: testEmployees),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Header and AppBar
      expect(find.text('Employee Directory'), findsOneWidget);
      expect(
        find.text('Find colleagues, departments & contact info'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);

      // 2. Search Bar
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Search by name, role, department, or email...'),
        findsOneWidget,
      );

      // 3. Employee Cards
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Senior Frontend Engineer'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Site Operations Supervisor'), findsOneWidget);
      expect(find.text('Jessica Pranata'), findsOneWidget);
      expect(find.text('Head of People & Culture'), findsOneWidget);

      // 4. Badges and Meta
      expect(find.text('ID: EMP-092'), findsOneWidget);
      expect(find.text('ID: EMP-145'), findsOneWidget);
      expect(find.text('ID: EMP-003'), findsOneWidget);

      // 5. Initials Avatar for Jessica Pranata
      expect(find.text('JP'), findsOneWidget);

      // 6. When paging is complete, completion text is shown instead of endless spinner
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      expect(find.text('Semua data pegawai telah ditampilkan'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Real-time search filters employees by name and role', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmployeeDirectoryScreen(customEmployees: testEmployees),
        ),
      );
      await tester.pump();

      // Type "budi" into search bar
      await tester.enterText(find.byType(TextField), 'budi');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Budi should be found
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Site Operations Supervisor'), findsOneWidget);

      // Others should be hidden
      expect(find.text('Sarah Jenkins'), findsNothing);
      expect(find.text('Jessica Pranata'), findsNothing);

      // Clear button should be visible
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // All employees restored
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Jessica Pranata'), findsOneWidget);
    });

    testWidgets('Real-time search filters employees by department', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmployeeDirectoryScreen(customEmployees: testEmployees),
        ),
      );
      await tester.pump();

      // Search by department: "Human Resources"
      await tester.enterText(find.byType(TextField), 'Human Resources');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Jessica Pranata'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsNothing);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('Empty state displayed when search yields no matches', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmployeeDirectoryScreen(customEmployees: testEmployees),
        ),
      );
      await tester.pump();

      // Search for something non-existent
      await tester.enterText(
        find.byType(TextField),
        'KaryawanTidakDitemukanXYZ',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Pegawai tidak ditemukan'), findsOneWidget);
      expect(
        find.text(
          'Tidak ada pegawai yang cocok dengan kata kunci "KaryawanTidakDitemukanXYZ".',
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('EmployeeCard quick action buttons show action notifications', (
      WidgetTester tester,
    ) async {
      const sampleItem = EmployeeDirectoryItem(
        id: 'EMP-001',
        name: 'Test Employee',
        role: 'Software Architect',
        department: 'Engineering',
        email: 'test@oasis.corp',
        phone: '+62 812-3456-7890',
        initials: 'TE',
      );

      var cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmployeeCard(
              employee: sampleItem,
              onTap: () {
                cardTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Employee'), findsOneWidget);
      expect(find.text('Software Architect'), findsOneWidget);
      expect(find.text('View Profile'), findsOneWidget);

      // Tap Phone button
      await tester.tap(find.byIcon(LucideIcons.phone));
      await tester.pump();

      expect(
        find.text('Menghubungi Test Employee (+62 812-3456-7890)'),
        findsOneWidget,
      );
      // Tapping phone should not trigger card tap
      expect(cardTapped, isFalse);

      // Tap Mail button
      await tester.tap(find.byIcon(LucideIcons.mail));
      await tester.pump();

      expect(find.text('Mengirim email ke test@oasis.corp'), findsOneWidget);
      expect(cardTapped, isFalse);

      // Tap whole card
      await tester.tap(find.text('View Profile'));
      await tester.pump();

      expect(cardTapped, isTrue);
    });

    testWidgets('Tapping employee card navigates to Employee Detail with employee data', (
      WidgetTester tester,
    ) async {
      final testRouter = GoRouter(
        initialLocation: Routes.EMPLOYEE_DIRECTORY,
        routes: [
          GoRoute(
            path: Routes.EMPLOYEE_DIRECTORY,
            builder: (context, state) => const EmployeeDirectoryScreen(
              customEmployees: testEmployees,
            ),
          ),
          GoRoute(
            path: Routes.EMPLOYEE_DETAIL,
            builder: (context, state) {
              final employee = state.extra as EmployeeDirectoryItem?;
              return EmployeeDetailScreen(employee: employee);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pump();

      expect(find.text('Budi Santoso'), findsOneWidget);

      // Tap on Budi Santoso's card
      await tester.tap(find.text('Budi Santoso'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should be on Employee Detail Screen with Budi Santoso's details
      expect(find.text('Employee Detail'), findsOneWidget);
      expect(find.text('EMP-145 • Operations'), findsOneWidget);
      expect(find.text('Site Operations Supervisor'), findsOneWidget);
    });

    testWidgets('Tapping filter button opens EmployeeFilterBottomSheet and filters list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmployeeDirectoryScreen(customEmployees: testEmployees),
        ),
      );
      await tester.pump();

      // Tap filter action button
      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet elements should be displayed
      expect(find.text('Filter Data Pegawai'), findsOneWidget);
      expect(
        find.text('Saring daftar pegawai berdasarkan perusahaan, departemen, dan jabatan'),
        findsOneWidget,
      );
      expect(find.text('Perusahaan (Company)'), findsOneWidget);
      expect(find.text('Departemen (Department)'), findsOneWidget);
      expect(find.text('Jabatan (Position)'), findsOneWidget);
      expect(find.text('Reset Filter'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);

      // Verify department and position are disabled with helper text before company is chosen
      expect(find.text('Pilih perusahaan terlebih dahulu'), findsNWidgets(2));

      // Select company first
      await tester.tap(find.text('Semua Perusahaan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Pilih Perusahaan'), findsOneWidget);
      await tester.tap(find.text('PT Oasish Group'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now department is enabled, tap on Departemen selector
      await tester.tap(find.text('Semua Departemen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Choose "Human Resources" from the selector list
      expect(find.text('Pilih Departemen'), findsOneWidget);
      await tester.tap(find.text('Human Resources').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Now tap "Terapkan Filter"
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet is closed, list should be filtered to Jessica Pranata only
      expect(find.text('Jessica Pranata'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsNothing);
      expect(find.text('Budi Santoso'), findsNothing);

      // Active filter chip should appear (along with card subtitle)
      expect(find.text('Human Resources'), findsNWidgets(2));

      // Tap "Hapus Semua" to reset filter
      await tester.tap(find.text('Hapus Semua'));
      await tester.pump();

      // All employees restored
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Jessica Pranata'), findsOneWidget);
    });
  });
}
