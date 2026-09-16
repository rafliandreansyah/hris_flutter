import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_plan_activity/create_plan_activity_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/pages/create_plan_activity_screen.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:image_picker/image_picker.dart';

class _FakePlanActivityRepository implements ActivityRepository {
  String? lastEmployeeId;

  @override
  Future<ActivityListResponse> getActivities({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async =>
      const ActivityListResponse(
        success: true,
        message: 'OK',
        data: [],
        meta: ActivityPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
      );

  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) async =>
      ActivityDetailResponse(success: true, message: 'OK', data: {'id': id});

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async =>
      const ActivityActionResponse(success: true, message: 'OK');

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async =>
      const ActivityActionResponse(success: true, message: 'OK');

  @override
  Future<ActivityActionResponse> startActivity({
    required String id,
    required double latitude,
    required double longitude,
    required String locationAddress,
    XFile? file,
  }) async =>
      const ActivityActionResponse(success: true, message: 'OK');

  @override
  Future<ActivityTypesResponse> getActivityTypes() async =>
      const ActivityTypesResponse(
        success: true,
        message: 'OK',
        data: [
          ActivityTypeModel(id: 'type-1', name: 'Instalasi Perangkat'),
          ActivityTypeModel(id: 'type-2', name: 'Maintenance Jaringan'),
        ],
      );

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
  }) async =>
      const CreateActivityResponse(success: true, message: 'OK', data: {});

  @override
  Future<CreateActivityResponse> createPlanActivity({
    required String employeeId,
    required String activityTypeId,
    required String startTime,
    required String locationName,
    required String locationAddress,
    required String description,
    double latitude = 0,
    double longitude = 0,
    XFile? file,
  }) async {
    lastEmployeeId = employeeId;
    return const CreateActivityResponse(
      success: true,
      message: 'Rencana aktivitas berhasil dibuat!',
      data: {'id': 'plan-101'},
    );
  }
}

class _FakePlanEmployeeRepository implements EmployeeRepository {
  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async =>
      const EmployeeListResponse(
        success: true,
        message: 'OK',
        data: [
          EmployeeDirectoryItem(
            id: 'uuid-subordinate-777',
            rawId: 'uuid-subordinate-777',
            employeeNumber: 'SUP-001',
            name: 'Budi Santoso',
            email: 'budi@example.com',
            role: 'Field Technician',
            department: 'Engineering',
            initials: 'BS',
          ),
          EmployeeDirectoryItem(
            id: 'uuid-subordinate-888',
            rawId: 'uuid-subordinate-888',
            employeeNumber: 'SUP-002',
            name: 'Dewi Lestari',
            email: 'dewi@example.com',
            role: 'Supervisor',
            department: 'Operations',
            initials: 'DL',
          ),
        ],
        meta: EmployeePaginationMeta(page: 1, limit: 30, total: 2, totalPages: 1),
      );

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) {
    throw UnimplementedError();
  }

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    return [];
  }
}

void main() {
  testWidgets('CreatePlanActivityScreen selects employee and closes bottom sheet without Provider error', (tester) async {
    final activityRepo = _FakePlanActivityRepository();
    final employeeRepo = _FakePlanEmployeeRepository();

    final bloc = CreatePlanActivityBloc(
      activityRepository: activityRepo,
      employeeRepository: employeeRepo,
    )..add(const CreatePlanActivityStarted());

    await tester.pumpWidget(
      MaterialApp(
        home: CreatePlanActivityScreen(
          activityRepository: activityRepo,
          employeeRepository: employeeRepo,
          bloc: bloc,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Screen rendered
    expect(find.text('Buat Rencana Aktivitas'), findsWidgets);

    // Tap employee selector
    final employeeSelector = find.text('Ketuk untuk memilih bawahan...');
    expect(employeeSelector, findsOneWidget);
    await tester.tap(employeeSelector);
    await tester.pumpAndSettle();

    // Bottom sheet is now visible
    expect(find.text('Pilih Pegawai / Bawahan'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);

    // Tap the employee item
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    // Bottom sheet should be closed, and employee name displayed on screen
    expect(find.text('Pilih Pegawai / Bawahan'), findsNothing);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('SUP-001 • Field Technician • Engineering'), findsOneWidget);
  });

  testWidgets('Submitting CreatePlanActivityScreen sends employee UUID not employeeNumber', (tester) async {
    final activityRepo = _FakePlanActivityRepository();
    final employeeRepo = _FakePlanEmployeeRepository();

    final bloc = CreatePlanActivityBloc(
      activityRepository: activityRepo,
      employeeRepository: employeeRepo,
    )..add(const CreatePlanActivityStarted());

    await tester.pumpWidget(
      MaterialApp(
        home: CreatePlanActivityScreen(
          activityRepository: activityRepo,
          employeeRepository: employeeRepo,
          bloc: bloc,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Select employee
    await tester.tap(find.text('Ketuk untuk memilih bawahan...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    // 2. Select activity type
    await tester.tap(find.text('Pilih jenis aktivitas...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instalasi Perangkat'));
    await tester.pumpAndSettle();

    // 3. Fill text fields
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Gedung Cyber 1');
    await tester.enterText(textFields.at(1), 'Jl. Kuningan Barat No. 8');
    await tester.enterText(textFields.at(2), 'Pemasangan router baru');
    await tester.pumpAndSettle();

    // 4. Tap submit button
    final submitButton = find.byKey(const ValueKey('submit_plan_activity_button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // 5. Verify the submitted employeeId is the UUID, NOT "SUP-001"
    expect(activityRepo.lastEmployeeId, 'uuid-subordinate-777');
  });

  testWidgets('CreatePlanActivityScreen renders red asterisks on mandatory fields', (tester) async {
    final activityRepo = _FakePlanActivityRepository();
    final employeeRepo = _FakePlanEmployeeRepository();

    final bloc = CreatePlanActivityBloc(
      activityRepository: activityRepo,
      employeeRepository: employeeRepo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreatePlanActivityScreen(
          activityRepository: activityRepo,
          employeeRepository: employeeRepo,
          bloc: bloc,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find rich text widgets that contain the red asterisk
    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final redAsteriskSpans = <TextSpan>[];

    for (final rt in richTexts) {
      if (rt.text is TextSpan) {
        final span = rt.text as TextSpan;
        span.visitChildren((child) {
          if (child is TextSpan && child.text == ' *' && child.style?.color == AppColors.error) {
            redAsteriskSpans.add(child);
          }
          return true;
        });
      }
    }

    // Should find red asterisks for sections & fields
    expect(redAsteriskSpans.length, greaterThanOrEqualTo(4));
  });
}
