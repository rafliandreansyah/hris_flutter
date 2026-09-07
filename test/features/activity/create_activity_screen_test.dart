import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/pages/create_activity_screen.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/create_activity_map_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:image_picker/image_picker.dart';

class _MockActivityRepository implements ActivityRepository {
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
      data: {'id': id},
    );
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'OK');
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'OK');
  }

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    return const ActivityTypesResponse(
      success: true,
      message: 'OK',
      data: [
        ActivityTypeModel(
          id: 'type-site-inspection',
          name: 'Site Inspection',
          code: 'SI',
        ),
        ActivityTypeModel(
          id: 'type-client-meeting',
          name: 'Client Meeting',
          code: 'CM',
        ),
      ],
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
    return CreateActivityResponse(
      success: true,
      message: 'Activity created',
      data: {
        'id': 'ACT-NEW-001',
        'activityTypeId': activityTypeId,
        'locationName': locationName,
        'locationAddress': locationAddress,
        'description': description,
        'status': 'ongoing',
        'startTime': '2026-09-07T08:00:00.000Z',
        'activityType': {
          'id': activityTypeId,
          'name': 'Site Inspection',
          'code': 'SI',
        },
      },
    );
  }
}

void main() {
  Widget createDirectTestWidget({ActivityRepository? repo}) {
    return MaterialApp(
      home: CreateActivityScreen(
        repository: repo ?? _MockActivityRepository(),
      ),
    );
  }

  group('CreateActivityScreen & CreateActivityMapCard Widget Tests', () {
    testWidgets('renders TopAppBar and refreshes GPS location on action tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDirectTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Title & Subtitle
      expect(find.text('Create Activity'), findsOneWidget);
      expect(
        find.text('Phase 1: Log initial activity & check-in'),
        findsOneWidget,
      );

      // Back button & Locate Fixed icon
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.locateFixed), findsAtLeast(1));

      // Tap GPS refresh button in AppBar
      final locateIcon = find.byTooltip('Perbarui Lokasi GPS');
      expect(locateIcon, findsOneWidget);
      await tester.tap(locateIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Lokasi GPS diperbarui ke:'), findsAtLeast(1));
    });

    testWidgets('CreateActivityMapCard displays only required GPS information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDirectTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CreateActivityMapCard), findsOneWidget);

      // Badges on Map
      expect(find.text('Live GPS Tracking'), findsOneWidget);
      expect(find.text('GPS Akurat (±3m)'), findsOneWidget);

      // Footer row
      expect(find.text('-6.2088° S, 106.8456° E'), findsOneWidget);
      expect(find.text('Real-time'), findsOneWidget);

      // Verify Buka di Maps button exists
      expect(find.text('Buka di Maps'), findsOneWidget);
    });

    testWidgets('Form validation alerts user when required fields are missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDirectTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap submit immediately without filling form
      final submitBtn = find.text('Submit & Start Activity');
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Warns about Activity Type first
      expect(
        find.text('Silakan pilih Activity Type terlebih dahulu.'),
        findsAtLeast(1),
      );
    });

    testWidgets('Selects Activity Type and opens Photo picker options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDirectTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Select Activity Type
      await tester.tap(find.text('Select activity type...'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pilih Jenis Aktivitas'), findsOneWidget);
      expect(find.text('Site Inspection'), findsOneWidget);

      await tester.tap(find.text('Site Inspection'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Site Inspection'), findsOneWidget);

      // 2. Open Photo Options Modal
      await tester.ensureVisible(find.text('Tap to Capture or Upload Photo'));
      await tester.tap(find.text('Tap to Capture or Upload Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pilih Sumber Foto'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
      expect(find.text('Gunakan Foto Sampel Lapangan'), findsOneWidget);

      // Select sample photo option
      await tester.tap(find.text('Gunakan Foto Sampel Lapangan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After photo selected, 'Ganti Foto' button should appear
      expect(find.text('Ganti Foto'), findsOneWidget);
    });

    testWidgets('Fills all fields, selects photo, and submits successfully', (
      WidgetTester tester,
    ) async {
      ActivityItem? returnedActivity;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push<ActivityItem>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateActivityScreen(
                          repository: _MockActivityRepository(),
                        ),
                      ),
                    );
                    returnedActivity = result;
                  },
                  child: const Text('Launch Screen'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap launch and wait for page transition to finish
      await tester.tap(find.text('Launch Screen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Select Activity Type
      await tester.tap(find.text('Select activity type...'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Site Inspection'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Fill Location Name
      final locationField = find.widgetWithText(
        TextField,
        'e.g., SCBD Tower 2 - Meeting Room 4A',
      );
      await tester.enterText(
        locationField,
        'SCBD Tower 2 - Construction Floor 14',
      );
      await tester.pump();

      // 3. Fill Address
      final addressField = find.widgetWithText(
        TextField,
        'e.g., Jl. Jend. Sudirman Kav. 52-53, Jakarta Selatan',
      );
      await tester.enterText(
        addressField,
        'SCBD Lot 28, Jl. Jend. Sudirman Kav. 52-53',
      );
      await tester.pump();

      // 4. Fill Description
      final descField = find.widgetWithText(
        TextField,
        'Describe the purpose of this activity, agenda, or initial scope...',
      );
      await tester.enterText(
        descField,
        'Conducted weekly safety audit and verified scaffolding.',
      );
      await tester.pump();

      // 5. Select Sample Photo
      await tester.ensureVisible(find.text('Tap to Capture or Upload Photo'));
      await tester.tap(find.text('Tap to Capture or Upload Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Gunakan Foto Sampel Lapangan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 6. Submit
      final submitBtn = find.text('Submit & Start Activity');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify that activity was created and returned
      expect(returnedActivity, isNotNull);
      expect(returnedActivity!.title, 'Site Inspection');
      expect(
        returnedActivity!.location,
        'SCBD Tower 2 - Construction Floor 14',
      );
      expect(returnedActivity!.status, ActivityStatus.inProgress);
      expect(returnedActivity!.isMyActivity, isTrue);
    });
  });
}
