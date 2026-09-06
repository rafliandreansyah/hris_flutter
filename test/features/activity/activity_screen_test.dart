import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_screen.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  final testActivities = [
    ActivityItem(
      id: 'ACT-001',
      title: 'Code Review',
      description: 'Reviewed PR #204 for attendance geolocation improvements.',
      userName: 'Sarah Jenkins',
      userRole: 'Frontend Engineer',
      department: 'Engineering',
      company: 'PT Oasish Tech Nusantara',
      initials: 'SJ',
      status: ActivityStatus.completed,
      location: 'HQ Office - Floor 3',
      time: '14:10',
      date: DateTime(2026, 9, 6, 14, 10),
      isMyActivity: true,
    ),
    ActivityItem(
      id: 'ACT-002',
      title: 'Site Inspection',
      description: 'Conducted weekly safety assessment and verified material delivery.',
      userName: 'Budi Santoso',
      userRole: 'Site Supervisor',
      department: 'Operations',
      company: 'PT Oasish Tech Nusantara',
      initials: 'BS',
      status: ActivityStatus.completed,
      location: 'SCBD Tower Construction Site',
      time: '11:30',
      date: DateTime(2026, 9, 6, 11, 30),
      isMyActivity: false,
    ),
    ActivityItem(
      id: 'ACT-003',
      title: 'Regression Testing',
      description: 'Executing mobile app test suite for v2.4 sprint release.',
      userName: 'Jessica Pranata',
      userRole: 'QA Engineer',
      department: 'Quality Assurance',
      company: 'PT Oasish Tech Nusantara',
      initials: 'JP',
      status: ActivityStatus.inProgress,
      location: 'Remote / Home Office',
      time: '10:15',
      date: DateTime(2026, 9, 1, 10, 15),
      isMyActivity: false,
    ),
  ];

  Widget createTestWidget() {
    return MaterialApp(
      home: ActivityScreen(
        customActivities: testActivities,
      ),
    );
  }

  group('ActivityScreen & Google Stitch Specifications Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('Renders AppBar with only filter icon, without calendar or download icons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Activity Reports'), findsOneWidget);
      expect(find.text('Track work logs & operational tasks'), findsOneWidget);

      // Verify back button
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

      // Verify ONLY filter icon is in the AppBar action area
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);

      // Verify no calendar_today or download icons in the app bar
      expect(find.byIcon(LucideIcons.calendar), findsNothing);
      expect(find.byIcon(LucideIcons.download), findsNothing);
    });

    testWidgets('Does NOT render horizontal filter chips below search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify search bar is present
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Search by employee name or keyword...'),
        findsOneWidget,
      );

      // Verify chip filters from original design do NOT exist
      expect(find.text('Company: All'), findsNothing);
      expect(find.text('Dept: Engineering'), findsNothing);
      expect(find.text('Position: All Roles'), findsNothing);
      expect(find.text('Status: Completed'), findsNothing);
    });

    testWidgets('Switches tabs between My Activities and Team Activities properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify TabBar and TabBarView widgets are used
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.byType(TabBarView), findsOneWidget);

      // Default initial tab is My Activities (Tab 0):
      // Only Sarah Jenkins is visible in My Activities (isMyActivity: true)
      expect(find.text('My Activities'), findsOneWidget);
      expect(find.text('Team Activities'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Jessica Pranata'), findsNothing);

      // FAB is visible on My Activities tab
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Tambah Aktivitas'), findsOneWidget);

      // Tap 'Team Activities' tab (Tab 1)
      await tester.tap(find.text('Team Activities'));
      await tester.pumpAndSettle();

      // All 3 items are visible in Team Activities
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Jessica Pranata'), findsOneWidget);

      // FAB is hidden on Team Activities tab
      expect(find.byType(FloatingActionButton), findsNothing);

      // Tap back to 'My Activities' tab (Tab 0)
      await tester.tap(find.text('My Activities'));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Jessica Pranata'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Tapping FAB on My Activities opens Add Activity bottom sheet and creates activity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap FAB on My Activities tab
      await tester.tap(find.byKey(const ValueKey('add_activity_fab')));
      await tester.pumpAndSettle();

      // Verify bottom sheet title
      expect(find.text('Tambah Aktivitas Kerja'), findsOneWidget);
      expect(find.text('Simpan Aktivitas'), findsOneWidget);

      // Fill in activity title
      await tester.enterText(
        find.widgetWithText(TextField, 'Misal: Review PR #142 & Sprint Planning'),
        'Pemeriksaan Deployment Staging',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Simpan Aktivitas'));
      await tester.pumpAndSettle();

      // Verify newly created activity appears in the list
      expect(find.text('Pemeriksaan Deployment Staging'), findsOneWidget);
    });

    testWidgets('Search query filters activity feed correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Team Activities to test full search
      await tester.tap(find.text('Team Activities'));
      await tester.pumpAndSettle();

      // Enter search term 'Budi'
      await tester.enterText(find.byType(TextField), 'Budi');
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsNothing);
      expect(find.text('Jessica Pranata'), findsNothing);

      // Clear search query using suffix clear icon
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Jessica Pranata'), findsOneWidget);
    });

    testWidgets('Tapping filter icon opens ActivityFilterBottomSheet with date range and company field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter icon
      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
      await tester.pumpAndSettle();

      // Verify bottom sheet title & fields
      expect(find.text('Filter Daftar Aktivitas'), findsOneWidget);
      expect(find.text('Rentang Tanggal (Date Range)'), findsOneWidget);
      expect(find.text('Perusahaan (Company)'), findsOneWidget);
      expect(find.text('Departemen (Division)'), findsOneWidget);
      expect(find.text('Jabatan (Position)'), findsOneWidget);
      // Status field is removed as requested
      expect(find.text('Status Aktivitas'), findsNothing);
      expect(find.text('Terapkan Filter'), findsOneWidget);
      expect(find.text('Reset Filter'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('Applies department filter from bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Team Activities tab
      await tester.tap(find.text('Team Activities'));
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
      await tester.pumpAndSettle();

      // Department & position are disabled initially with helper text
      expect(find.text('Pilih perusahaan terlebih dahulu'), findsNWidgets(2));

      // Select company first
      await tester.tap(find.text('Semua Perusahaan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PT Oasish Tech Nusantara'));
      await tester.pumpAndSettle();

      // Now department is enabled, tap Departemen field to choose Operations
      await tester.tap(find.text('Semua Departemen'));
      await tester.pumpAndSettle();

      expect(find.text('Operations'), findsOneWidget);
      await tester.tap(find.text('Operations'));
      await tester.pumpAndSettle();

      // Apply filter
      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      // Only Budi Santoso (Operations) should be shown
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsNothing);
      expect(find.text('Jessica Pranata'), findsNothing);
    });

    testWidgets('Applies company filter from bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Team Activities tab
      await tester.tap(find.text('Team Activities'));
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
      await tester.pumpAndSettle();

      // Tap Perusahaan field
      await tester.tap(find.text('Semua Perusahaan'));
      await tester.pumpAndSettle();

      expect(find.text('PT Oasish Tech Nusantara'), findsOneWidget);
      await tester.tap(find.text('PT Oasish Tech Nusantara'));
      await tester.pumpAndSettle();

      // Verify button has StadiumBorder and LucideIcons.filter
      expect(find.byIcon(LucideIcons.filter), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);

      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      // All 3 belong to PT Oasish Tech Nusantara
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Jessica Pranata'), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
    });

    testWidgets('Applies position filter from bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Team Activities tab
      await tester.tap(find.text('Team Activities'));
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
      await tester.pumpAndSettle();

      // Department & position are disabled initially with helper text
      expect(find.text('Pilih perusahaan terlebih dahulu'), findsNWidgets(2));

      // Select company first
      await tester.tap(find.text('Semua Perusahaan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PT Oasish Tech Nusantara'));
      await tester.pumpAndSettle();

      // Now position is enabled, tap Jabatan field
      await tester.tap(find.text('Semua Jabatan'));
      await tester.pumpAndSettle();

      expect(find.text('QA Engineer'), findsOneWidget);
      await tester.tap(find.text('QA Engineer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan Filter'));
      await tester.pumpAndSettle();

      // Only Jessica Pranata (QA Engineer) should be shown
      expect(find.text('Jessica Pranata'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(find.text('Sarah Jenkins'), findsNothing);
    });

    testWidgets('Hides search bar on scroll up and restores it on scroll down / top', (
      WidgetTester tester,
    ) async {
      final manyActivities = List.generate(
        10,
        (i) => ActivityItem(
          id: 'ACT-MANY-$i',
          title: 'Task $i',
          description: 'Description $i',
          userName: 'User $i',
          userRole: 'Role $i',
          department: 'Engineering',
          company: 'Company',
          initials: 'U$i',
          status: ActivityStatus.completed,
          location: 'Location $i',
          time: '10:00',
          date: DateTime(2026, 9, 6),
          isMyActivity: true,
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: ActivityScreen(customActivities: manyActivities),
      ));
      await tester.pumpAndSettle();

      final animatedContainerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.duration == const Duration(milliseconds: 250),
      );
      expect(animatedContainerFinder, findsOneWidget);

      AnimatedContainer container =
          tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect(container.constraints?.maxHeight ?? 58, 58);

      // Scroll content upwards (drag with offset -300)
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      container = tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect(container.constraints?.maxHeight ?? 0, 0);

      // Scroll content downwards (drag with offset +300)
      await tester.drag(find.byType(ListView).first, const Offset(0, 300));
      await tester.pumpAndSettle();

      container = tester.widget<AnimatedContainer>(animatedContainerFinder);
      expect(container.constraints?.maxHeight ?? 58, 58);
    });
  });

  group('ActivityCard & Model Tests', () {
    testWidgets('ActivityCard displays all metadata accurately', (
      WidgetTester tester,
    ) async {
      final activity = testActivities[0];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityCard(activity: activity),
          ),
        ),
      );


      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.textContaining('Frontend Engineer'), findsOneWidget);
      expect(find.textContaining('Engineering'), findsOneWidget);
      expect(find.text('Code Review'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(
        find.text('Reviewed PR #204 for attendance geolocation improvements.'),
        findsOneWidget,
      );
      expect(find.text('HQ Office - Floor 3'), findsOneWidget);
      expect(find.text('14:10'), findsOneWidget);
    });

    test('ActivityFilterCriteria computes active filters and count correctly', () {
      const emptyCriteria = ActivityFilterCriteria();
      expect(emptyCriteria.hasActiveFilter, isFalse);
      expect(emptyCriteria.activeFilterCount, 0);

      final criteriaWithPosition = const ActivityFilterCriteria(
        position: 'QA Engineer',
      );
      expect(criteriaWithPosition.hasActiveFilter, isTrue);
      expect(criteriaWithPosition.activeFilterCount, 1);

      final fullCriteria = ActivityFilterCriteria(
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 28),
        ),
        company: 'PT Oasish Tech Nusantara',
        department: 'Engineering',
        position: 'Frontend Engineer',
      );
      expect(fullCriteria.hasActiveFilter, isTrue);
      expect(fullCriteria.activeFilterCount, 4);

      final copied = fullCriteria.copyWith(position: 'Senior Manager');
      expect(copied.position, 'Senior Manager');
      expect(copied.company, 'PT Oasish Tech Nusantara');
      expect(copied.department, 'Engineering');
      expect(copied.dateRange, isNotNull);
    });
  });
}
