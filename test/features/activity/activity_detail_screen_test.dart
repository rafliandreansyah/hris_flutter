import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_detail_screen.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_map_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_timeline_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  final testActivity = ActivityItem(
    id: 'ACT-002',
    title: 'Site Inspection',
    description:
        'Conducted weekly safety assessment and verified material delivery manifests.',
    userName: 'Budi Santoso',
    userRole: 'Site Supervisor (L4)',
    department: 'Operations',
    company: 'PT Oasish Tech Nusantara',
    initials: 'BS',
    status: ActivityStatus.completed,
    location: 'SCBD Tower 2 - Construction Floor 14',
    time: '11:30',
    date: DateTime(2026, 8, 27),
    isMyActivity: false,
    category: 'Site Inspection',
    latitude: -6.2253,
    longitude: 106.8097,
    fullAddress: 'SCBD Lot 28, Jl. Jend. Sudirman Kav. 52-53',
    districtCity:
        'Kec. Kebayoran Baru, Kota Jakarta Selatan, DKI Jakarta 12190',
    gpsAccuracy: '±3m',
    isGpsVerified: true,
  );

  Widget createTestWidget({ActivityItem? activity}) {
    return MaterialApp(
      home: ActivityDetailScreen(
        activity: activity ?? testActivity,
      ),
    );
  }

  group('ActivityDetailScreen Widget Tests', () {
    testWidgets(
      'renders TopAppBar with title, ID, status, and ONLY share action icon',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Title and ID
        expect(find.text('Activity Detail'), findsOneWidget);
        expect(find.text('ID: ACT-002 • Completed'), findsOneWidget);

        // ONLY share action icon must be in AppBar
        expect(find.byIcon(LucideIcons.share2), findsOneWidget);

        // Verification: more_vert / filter icons should NOT exist in AppBar
        expect(find.byIcon(Icons.more_vert), findsNothing);
        expect(find.byIcon(LucideIcons.slidersHorizontal), findsNothing);
      },
    );

    testWidgets('renders Employee Profile & Status Card correctly', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Category chip
      expect(find.text('Site Inspection'), findsAtLeast(1));

      // Status chip
      expect(find.text('Completed'), findsAtLeast(1));

      // Employee Information
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Site Supervisor (L4)'), findsOneWidget);
      expect(
        find.text('Operations • PT Oasish Tech Nusantara'),
        findsOneWidget,
      );

      // Location in Profile Card
      expect(
        find.text('SCBD Tower 2 - Construction Floor 14'),
        findsAtLeast(1),
      );
    });

    testWidgets(
      'renders ActivityMapCard with address, GPS chips, and maps link',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ActivityMapCard), findsOneWidget);
        expect(find.text('Lokasi Aktivitas'), findsOneWidget);
        expect(find.text('Buka di Maps'), findsOneWidget);
        expect(
          find.text('SCBD Lot 28, Jl. Jend. Sudirman Kav. 52-53'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Kec. Kebayoran Baru, Kota Jakarta Selatan, DKI Jakarta 12190',
          ),
          findsOneWidget,
        );
        expect(find.text('-6.2253° S, 106.8097° E'), findsOneWidget);
        expect(find.text('• Zona Terverifikasi'), findsOneWidget);
      },
    );

    testWidgets(
      'renders ActivityTimelineSection with Phase 1 and Phase 2 nodes',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ActivityTimelineSection), findsOneWidget);
        expect(find.text('Activity Progress Timeline'), findsOneWidget);

        // Phase 1
        expect(find.text('Phase 1: Start & Check-In'), findsOneWidget);
        expect(find.text('Initial Description / Task Scope'), findsOneWidget);
        expect(find.byIcon(LucideIcons.play), findsOneWidget);

        // Phase 2
        expect(find.text('Phase 2: Completion & Report'), findsOneWidget);
        expect(find.text('Completion Notes / Outcome'), findsOneWidget);
        expect(find.byIcon(LucideIcons.check), findsOneWidget);
      },
    );

    testWidgets('renders Export Activity Summary PDF button and handles tap', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final exportBtn = find.text('Export Activity Summary (PDF)');
      expect(exportBtn, findsOneWidget);

      // Scroll to button and tap
      await tester.ensureVisible(exportBtn);
      await tester.tap(exportBtn);
      await tester.pump();

      // Check snackbar appeared
      expect(
        find.text('Mengunduh ringkasan PDF untuk aktivitas ACT-002...'),
        findsOneWidget,
      );
    });

    testWidgets('tap on photo opens preview dialog with close button', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find preview button overlay
      final previewHints = find.text('Lihat');
      expect(previewHints, findsAtLeast(1));

      await tester.ensureVisible(previewHints.first);
      await tester.tap(previewHints.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog should open with close button
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(LucideIcons.x), findsNothing);
    });
  });
}
