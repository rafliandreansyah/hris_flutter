import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/pages/leave_detail_screen.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_approver_card.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_document_card.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_employee_card.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_overview_card.dart';

class _FakeLeaveRepository implements LeaveRepository {
  final LeaveRequestDetailData detail;

  _FakeLeaveRepository(this.detail);

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id) async {
    return detail;
  }

  @override
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  }) async {}

  @override
  Future<void> deleteLeaveRequest(String id) async {}

  @override
  Future<List<LeaveTypeOptionModel>> getLeaveTypes() async => const [];

  @override
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  }) async {
    return const CreateLeaveResultModel(success: true, message: 'OK');
  }
}

void main() {
  group('LeaveDetailScreen Widget Tests', () {
    final baseDetail = LeaveRequestDetailData(
      id: 'leave-abc-123',
      startDate: DateTime(2026, 8, 28),
      endDate: DateTime(2026, 8, 28),
      totalDays: 1,
      notes: 'Annual medical checkup and dental appointment.',
      status: 'requested',
      leaveType: const LeaveTypeDetailModel(id: 'lt-1', name: 'Sick Leave'),
      employee: const LeaveEmployeeDetailModel(
        id: 'emp-1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
        email: 'sarah.j@oasish.com',
        position: LeaveOrgItemModel(id: 'p1', name: 'Frontend Engineer'),
        department: LeaveOrgItemModel(id: 'd1', name: 'Engineering'),
        company: LeaveOrgItemModel(id: 'c1', name: 'Oasish Tech'),
      ),
      approver: const LeaveApproverDetailModel(
        id: 'app-1',
        firstName: 'Alex',
        lastName: 'Rivera',
        position: LeaveOrgItemModel(id: 'p2', name: 'Engineering Manager'),
        department: LeaveOrgItemModel(id: 'd1', name: 'Engineering'),
      ),
      filePath: null,
    );

    testWidgets(
      'Displays Overview, Employee, and Approver when approver is present',
      (tester) async {
        final repo = _FakeLeaveRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaveDetailScreen(
              id: 'leave-abc-123',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LeaveDetailOverviewCard), findsOneWidget);
        expect(find.byType(LeaveDetailEmployeeCard), findsOneWidget);
        expect(find.byType(LeaveDetailApproverCard), findsOneWidget);
        expect(find.text('Sarah Jenkins'), findsOneWidget);
        expect(find.text('Alex Rivera'), findsOneWidget);
        expect(find.text('Sick Leave'), findsOneWidget);
        expect(find.text('1 Work Day(s)'), findsOneWidget);
      },
    );

    testWidgets(
      'Hides Approver card when approver is null (per user requirement)',
      (tester) async {
        final detailWithoutApprover =
            baseDetail.copyWith(clearApprover: true);
        final repo = _FakeLeaveRepository(detailWithoutApprover);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaveDetailScreen(
              id: 'leave-abc-123',
              isApprover: false,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LeaveDetailOverviewCard), findsOneWidget);
        expect(find.byType(LeaveDetailEmployeeCard), findsOneWidget);
        expect(find.byType(LeaveDetailApproverCard), findsNothing);
        expect(find.text('ASSIGNED APPROVER'), findsNothing);
      },
    );

    testWidgets(
      'Shows Reject and Approve buttons when isApprover: true and status: requested',
      (tester) async {
        final repo = _FakeLeaveRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaveDetailScreen(
              id: 'leave-abc-123',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reject'), findsOneWidget);
        expect(find.text('Approve'), findsOneWidget);
      },
    );

    testWidgets(
      'Hides Reject and Approve buttons when isApprover: false (own request)',
      (tester) async {
        final repo = _FakeLeaveRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaveDetailScreen(
              id: 'leave-abc-123',
              isApprover: false,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reject'), findsNothing);
        expect(find.text('Approve'), findsNothing);
      },
    );

    testWidgets(
      'Hides Reject and Approve buttons when status is approved even if isApprover: true',
      (tester) async {
        final approvedDetail = baseDetail.copyWith(status: 'approved');
        final repo = _FakeLeaveRepository(approvedDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaveDetailScreen(
              id: 'leave-abc-123',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Reject'), findsNothing);
        expect(find.text('Approve'), findsNothing);
      },
    );

    testWidgets(
      'Hides Document card when filePath is null',
      (tester) async {
        final repo = _FakeLeaveRepository(baseDetail);

        await tester.pumpWidget(
          MaterialApp(
            home: LeaveDetailScreen(
              id: 'leave-abc-123',
              isApprover: true,
              repository: repo,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LeaveDetailDocumentCard), findsNothing);
        expect(find.text('SUPPORTING DOCUMENT'), findsNothing);
      },
    );
  });
}
