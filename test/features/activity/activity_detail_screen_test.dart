import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_detail_screen.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_map_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_timeline_section.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _MockDetailRepo implements ActivityRepository {
  bool finishCalled = false;
  bool cancelCalled = false;
  String? lastNotes;

  @override
  Future<ActivityListResponse> getActivities({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    bool approver = false,
  }) async {
    return const ActivityListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: ActivityPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
    );
  }

  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) async {
    return ActivityDetailResponse(
      success: true,
      message: 'OK',
      data: {
        'id': id,
        'employeeId': 'emp-001',
        'status': finishCalled ? 'completed' : (cancelCalled ? 'canceled' : 'ongoing'),
        'description': 'Pemeriksaan lapangan dan monitoring proyek.',
        'startTime': '2026-09-07T08:30:00.000Z',
        'endTime': finishCalled ? '2026-09-07T14:00:00.000Z' : null,
        'updatedAt': '2026-09-07T14:00:00.000Z',
        'notes': lastNotes ?? (finishCalled ? 'Meeting selesai.' : null),
        'filePath': 'https://example.com/start.jpg',
        'filePath2': finishCalled || cancelCalled ? 'https://example.com/end.jpg' : null,
        'employee': {
          'id': 'emp-001',
          'firstName': 'Sarah',
          'lastName': 'Jenkins',
          'photoUrl': null,
          'company': {'id': 'c1', 'name': 'PT Oasish Tech Nusantara'},
          'department': {'id': 'd1', 'name': 'Engineering'},
          'position': {'id': 'p1', 'name': 'Frontend Engineer'},
        },
      },
    );
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    finishCalled = true;
    lastNotes = notes;
    return const ActivityActionResponse(success: true, message: 'Berhasil selesai');
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    cancelCalled = true;
    lastNotes = notes;
    return const ActivityActionResponse(success: true, message: 'Berhasil batal');
  }

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    return const ActivityTypesResponse(
      success: true,
      message: 'OK',
      data: [],
    );
  }

  @override
  Future<CreateActivityResponse> createActivity({
    required String activityTypeId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String locationAddress,
    required String description,
    String status = 'ongoing',
    XFile? file,
  }) async {
    return const CreateActivityResponse(
      success: true,
      message: 'OK',
      data: {},
    );
  }
}

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

  Widget createTestWidget({
    ActivityItem? activity,
    ActivityRepository? repository,
  }) {
    return MaterialApp(
      home: ActivityDetailScreen(
        activity: activity ?? testActivity,
        activityRepository: repository,
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

    // --- Role-Based Creator vs Approver Tests ---

    testWidgets(
      'Creator with ongoing status displays Batalkan and Selesaikan buttons in bottom bar',
      (tester) async {
        final creatorOngoingActivity = testActivity.copyWith(
          id: 'ACT-999',
          isMyActivity: true,
          status: ActivityStatus.ongoing,
        );

        await tester.pumpWidget(createTestWidget(activity: creatorOngoingActivity));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Action buttons must be present
        expect(find.byKey(const ValueKey('cancel_activity_btn')), findsOneWidget);
        expect(find.byKey(const ValueKey('complete_activity_btn')), findsOneWidget);
        expect(find.text('Batalkan'), findsOneWidget);
        expect(find.text('Selesaikan'), findsOneWidget);
      },
    );

    testWidgets(
      'Approver mode with ongoing status does NOT display action buttons (view-only)',
      (tester) async {
        final approverOngoingActivity = testActivity.copyWith(
          id: 'ACT-998',
          isMyActivity: false,
          status: ActivityStatus.ongoing,
        );

        await tester.pumpWidget(createTestWidget(activity: approverOngoingActivity));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Action buttons must NOT exist
        expect(find.byKey(const ValueKey('cancel_activity_btn')), findsNothing);
        expect(find.byKey(const ValueKey('complete_activity_btn')), findsNothing);
      },
    );

    testWidgets(
      'Creator with completed status does NOT display action buttons',
      (tester) async {
        final creatorCompletedActivity = testActivity.copyWith(
          id: 'ACT-997',
          isMyActivity: true,
          status: ActivityStatus.completed,
        );

        await tester.pumpWidget(createTestWidget(activity: creatorCompletedActivity));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byKey(const ValueKey('cancel_activity_btn')), findsNothing);
        expect(find.byKey(const ValueKey('complete_activity_btn')), findsNothing);
      },
    );

    testWidgets(
      'Tapping Selesaikan button opens bottom sheet with modal form and notes input',
      (tester) async {
        final mockRepo = _MockDetailRepo();
        final creatorOngoingActivity = testActivity.copyWith(
          id: 'ACT-996',
          isMyActivity: true,
          status: ActivityStatus.ongoing,
        );

        await tester.pumpWidget(
          createTestWidget(
            activity: creatorOngoingActivity,
            repository: mockRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final completeBtn = find.byKey(const ValueKey('complete_activity_btn'));
        expect(completeBtn, findsOneWidget);
        await tester.tap(completeBtn);
        await tester.pumpAndSettle();

        // Check modal content
        expect(find.text('Selesaikan Aktivitas'), findsAtLeast(1));
        expect(find.byKey(const ValueKey('action_notes_field')), findsOneWidget);
        expect(find.byKey(const ValueKey('submit_action_confirm_btn')), findsOneWidget);

        // Submit complete
        await tester.tap(find.byKey(const ValueKey('submit_action_confirm_btn')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(mockRepo.finishCalled, isTrue);
      },
    );

    testWidgets(
      'Tapping Batalkan button opens bottom sheet with modal form and validates empty notes',
      (tester) async {
        final mockRepo = _MockDetailRepo();
        final creatorOngoingActivity = testActivity.copyWith(
          id: 'ACT-995',
          isMyActivity: true,
          status: ActivityStatus.ongoing,
        );

        await tester.pumpWidget(
          createTestWidget(
            activity: creatorOngoingActivity,
            repository: mockRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final cancelBtn = find.byKey(const ValueKey('cancel_activity_btn'));
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Check modal content
        expect(find.text('Batalkan Aktivitas'), findsAtLeast(1));
        final notesField = find.byKey(const ValueKey('action_notes_field'));
        expect(notesField, findsOneWidget);

        // Empty notes tap submit -> should show error
        final submitBtn = find.byKey(const ValueKey('submit_action_confirm_btn'));
        await tester.tap(submitBtn);
        await tester.pump();

        expect(find.text('Catatan tidak boleh kosong!'), findsOneWidget);
        expect(mockRepo.cancelCalled, isFalse);

        // Enter notes and submit
        await tester.enterText(notesField, 'Kendala cuaca ekstrem di lokasi kerja.');
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(mockRepo.cancelCalled, isTrue);
        expect(mockRepo.lastNotes, 'Kendala cuaca ekstrem di lokasi kerja.');
      },
    );

    testWidgets(
      'Dynamic timeline reflects Phase 1 and Phase 2 based on API detail data',
      (tester) async {
        final apiActivity = ActivityItem(
          id: 'ACT-DETAIL-01',
          title: 'Client Demo',
          description: 'Mempresentasikan modul absensi dan activity feed.',
          userName: 'Sarah Jenkins',
          userRole: 'Frontend Engineer',
          department: 'Engineering',
          company: 'PT Oasish Tech Nusantara',
          initials: 'SJ',
          status: ActivityStatus.completed,
          location: 'Plaza Senayan',
          time: '09:00',
          date: DateTime(2026, 9, 7),
          isMyActivity: true,
          filePath: 'https://example.com/start_meeting.jpg',
          filePath2: 'https://example.com/end_meeting.jpg',
          notes: 'Klien sangat puas dengan demo aplikasi.',
          startTime: DateTime(2026, 9, 7, 9, 0),
          endTime: DateTime(2026, 9, 7, 11, 30),
        );

        await tester.pumpWidget(createTestWidget(activity: apiActivity));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Phase 1 verification
        expect(find.text('Phase 1: Start & Check-In'), findsOneWidget);
        expect(find.text('Mempresentasikan modul absensi dan activity feed.'), findsOneWidget);

        // Phase 2 verification
        expect(find.text('Phase 2: Completion & Report'), findsOneWidget);
        expect(find.text('Klien sangat puas dengan demo aplikasi.'), findsOneWidget);
      },
    );
  });
}
