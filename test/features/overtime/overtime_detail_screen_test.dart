import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/overtime_detail_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_approver_card.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_employee_card.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_evidence_card.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_overview_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeOvertimeRepository implements OvertimeRepository {
  final OvertimeDetailData detail;

  _FakeOvertimeRepository(this.detail);

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
    String? statusApprove,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OvertimeDetailData> getOvertimeDetail(String id) async {
    return detail;
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {}

  @override
  Future<void> deleteOvertime(String id) async {}
}

void main() {
  group('OvertimeDetailScreen Widget Tests', () {
    final baseDetail = OvertimeDetailData(
      id: 'ot-abc-1234',
      startOvertime: DateTime(2026, 8, 28, 17, 0),
      endOvertime: DateTime(2026, 8, 28, 21, 0),
      notes: 'Deploying critical microservice updates and running post-migration sanity tests.',
      status: 'requested',
      timezone: 'WIB',
      createdAt: DateTime(2026, 8, 28, 9, 33),
      employee: const OvertimeEmployeeModel(
        id: 'emp-1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
        email: 'sarah.j@oasish.com',
        position: OvertimePositionModel(id: 'pos-1', name: 'Frontend Engineer'),
        department: OvertimeDepartmentModel(id: 'dept-1', name: 'Engineering'),
        company: OvertimeCompanyModel(id: 'comp-1', name: 'Oasish Tech'),
        employeeNumber: 'EMP-2024-019',
      ),
      approver: const OvertimeEmployeeModel(
        id: 'app-1',
        firstName: 'Alex',
        lastName: 'Rivera',
        email: 'alex.r@oasish.com',
        position: OvertimePositionModel(id: 'pos-2', name: 'Engineering Manager'),
        company: OvertimeCompanyModel(id: 'comp-1', name: 'Oasish Tech'),
      ),
      filePath: null,
    );

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(800, 1800);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets(
      'Displays Overview, Employee, and Approver cards when approver is present',
      (tester) async {
        final repo = _FakeOvertimeRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: OvertimeDetailScreen(
              id: 'ot-abc-1234',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(OvertimeDetailOverviewCard), findsOneWidget);
        expect(find.byType(OvertimeDetailEmployeeCard), findsOneWidget);
        expect(find.byType(OvertimeDetailApproverCard), findsOneWidget);
        expect(find.text('Sarah Jenkins'), findsOneWidget);
        expect(find.text('Alex Rivera'), findsOneWidget);
        expect(find.text('Overtime Shift'), findsOneWidget);
        expect(find.text('4 Jam Kerja'), findsOneWidget);
      },
    );

    testWidgets(
      'Hides Approver card when approver is null',
      (tester) async {
        final detailWithoutApprover = baseDetail.copyWith(clearApprover: true);
        final repo = _FakeOvertimeRepository(detailWithoutApprover);

        await tester.pumpWidget(
          MaterialApp(
            home: OvertimeDetailScreen(
              id: 'ot-abc-1234',
              isApprover: false,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(OvertimeDetailOverviewCard), findsOneWidget);
        expect(find.byType(OvertimeDetailEmployeeCard), findsOneWidget);
        expect(find.byType(OvertimeDetailApproverCard), findsNothing);
        expect(find.text('ASSIGNED APPROVER'), findsNothing);
      },
    );

    testWidgets(
      'Shows Reject and Approve Overtime buttons when isApprover: true and status: requested',
      (tester) async {
        final repo = _FakeOvertimeRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: OvertimeDetailScreen(
              id: 'ot-abc-1234',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reject'), findsOneWidget);
        expect(find.text('Approve Overtime'), findsOneWidget);
      },
    );

    testWidgets(
      'Hides Reject and Approve Overtime buttons when isApprover: false (own request)',
      (tester) async {
        final repo = _FakeOvertimeRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: OvertimeDetailScreen(
              id: 'ot-abc-1234',
              isApprover: false,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reject'), findsNothing);
        expect(find.text('Approve Overtime'), findsNothing);

        // Verify that delete option is available in AppBar
        expect(find.byIcon(LucideIcons.ellipsisVertical), findsOneWidget);
      },
    );

    testWidgets(
      'Hides Reject, Approve, and Delete when status is approved (final state)',
      (tester) async {
        final approvedDetail = baseDetail.copyWith(status: 'approved');
        final repo = _FakeOvertimeRepository(approvedDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: OvertimeDetailScreen(
              id: 'ot-abc-1234',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reject'), findsNothing);
        expect(find.text('Approve Overtime'), findsNothing);
        expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
      },
    );

    testWidgets(
      'Hides Reject, Approve, and Delete when status is rejected (final state)',
      (tester) async {
        final rejectedDetail = baseDetail.copyWith(status: 'rejected');
        final repo = _FakeOvertimeRepository(rejectedDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: OvertimeDetailScreen(
              id: 'ot-abc-1234',
              isApprover: false,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reject'), findsNothing);
        expect(find.text('Approve Overtime'), findsNothing);
        expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
      },
    );

    testWidgets(
      'Displays Evidence card with placeholder when filePath is null',
      (tester) async {
        final repo = _FakeOvertimeRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: OvertimeDetailScreen(
              id: 'ot-abc-1234',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(OvertimeDetailEvidenceCard), findsOneWidget);
        expect(find.text('Tidak ada foto bukti dilampirkan.'), findsOneWidget);
      },
    );
  });
}
