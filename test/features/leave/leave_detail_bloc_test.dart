import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_bloc.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_event.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_state.dart';

class _MockLeaveRepository implements LeaveRepository {
  LeaveRequestDetailData? mockDetail;
  ApiException? errorToThrow;
  String? lastApprovedId;
  bool? lastIsApproved;
  String? lastApproverNotes;
  String? lastDeletedId;

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockDetail ??
        LeaveRequestDetailData(
          id: id,
          status: 'requested',
          leaveType: const LeaveTypeDetailModel(id: 'lt-1', name: 'Sick Leave'),
          employee: const LeaveEmployeeDetailModel(
            id: 'emp-1',
            firstName: 'Sarah',
            lastName: 'Jenkins',
            email: 'sarah@oasish.com',
          ),
        );
  }

  @override
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastApprovedId = id;
    lastIsApproved = isApproved;
    lastApproverNotes = approverNotes;
  }

  @override
  Future<void> deleteLeaveRequest(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastDeletedId = id;
  }

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
  group('LeaveDetailBloc Tests', () {
    late _MockLeaveRepository repository;

    setUp(() {
      repository = _MockLeaveRepository();
    });

    final testDetail = LeaveRequestDetailData(
      id: 'leave-123',
      status: 'requested',
      totalDays: 2,
      notes: 'Sick leave note',
      leaveType: const LeaveTypeDetailModel(id: 'lt-1', name: 'Sick Leave'),
      employee: const LeaveEmployeeDetailModel(
        id: 'emp-1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
      ),
    );

    test('initial state sesuai default', () {
      final bloc = LeaveDetailBloc(repository: repository);

      expect(bloc.state, const LeaveDetailState());
      expect(bloc.state.status, LeaveDetailStatus.initial);
      expect(bloc.state.detail, isNull);
      expect(bloc.state.isApprover, isFalse);
      expect(bloc.state.errorMessage, isNull);

      bloc.close();
    });

    test('emits [loading, success] when LeaveDetailStarted succeeds', () async {
      repository.mockDetail = testDetail;
      final bloc = LeaveDetailBloc(repository: repository);
      final states = <LeaveDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const LeaveDetailStarted(id: 'leave-123', isApprover: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, LeaveDetailStatus.loading);
      expect(states[0].id, 'leave-123');
      expect(states[0].isApprover, isTrue);

      expect(states[1].status, LeaveDetailStatus.success);
      expect(states[1].id, 'leave-123');
      expect(states[1].isApprover, isTrue);
      expect(states[1].detail, testDetail);

      await sub.cancel();
      await bloc.close();
    });

    test('emits [loading, failure] with statusCode when LeaveDetailStarted fails with 404', () async {
      repository.errorToThrow = ApiException(
        message: 'Data tidak ditemukan',
        statusCode: 404,
      );
      final bloc = LeaveDetailBloc(repository: repository);
      final states = <LeaveDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const LeaveDetailStarted(id: 'invalid-id'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, LeaveDetailStatus.loading);
      expect(states[1].status, LeaveDetailStatus.failure);
      expect(states[1].errorMessage, 'Data tidak ditemukan');
      expect(states[1].statusCode, 404);

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, actionSuccess] when LeaveDetailApproveSubmitted succeeds (Approve)', () async {
      repository.mockDetail = testDetail;
      final bloc = LeaveDetailBloc(repository: repository);

      // Start first to set detail
      bloc.add(const LeaveDetailStarted(id: 'leave-123', isApprover: true));
      await Future.delayed(const Duration(milliseconds: 50));

      final states = <LeaveDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const LeaveDetailApproveSubmitted(
          isApproved: true,
          approverNotes: 'Approved by lead',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, LeaveDetailStatus.submittingAction);

      expect(states[1].status, LeaveDetailStatus.actionSuccess);
      expect(states[1].detail?.status, 'approved');
      expect(states[1].detail?.approverNotes, 'Approved by lead');
      expect(states[1].actionMessage, 'Pengajuan cuti berhasil disetujui');

      expect(repository.lastApprovedId, 'leave-123');
      expect(repository.lastIsApproved, isTrue);
      expect(repository.lastApproverNotes, 'Approved by lead');

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, actionSuccess] when LeaveDetailApproveSubmitted succeeds (Reject)', () async {
      repository.mockDetail = testDetail;
      final bloc = LeaveDetailBloc(repository: repository);

      bloc.add(const LeaveDetailStarted(id: 'leave-123', isApprover: true));
      await Future.delayed(const Duration(milliseconds: 50));

      final states = <LeaveDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const LeaveDetailApproveSubmitted(
          isApproved: false,
          approverNotes: 'Kuota tidak mencukupi',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, LeaveDetailStatus.submittingAction);

      expect(states[1].status, LeaveDetailStatus.actionSuccess);
      expect(states[1].detail?.status, 'rejected');
      expect(states[1].detail?.approverNotes, 'Kuota tidak mencukupi');
      expect(states[1].actionMessage, 'Pengajuan cuti berhasil ditolak');

      expect(repository.lastApprovedId, 'leave-123');
      expect(repository.lastIsApproved, isFalse);
      expect(repository.lastApproverNotes, 'Kuota tidak mencukupi');

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, deleteSuccess] when LeaveDetailDeleteSubmitted succeeds', () async {
      repository.mockDetail = testDetail;
      final bloc = LeaveDetailBloc(repository: repository);

      bloc.add(const LeaveDetailStarted(id: 'leave-123', isApprover: false));
      await Future.delayed(const Duration(milliseconds: 50));

      final states = <LeaveDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const LeaveDetailDeleteSubmitted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, LeaveDetailStatus.submittingAction);

      expect(states[1].status, LeaveDetailStatus.deleteSuccess);
      expect(states[1].actionMessage, 'Pengajuan cuti berhasil dihapus');

      expect(repository.lastDeletedId, 'leave-123');

      await sub.cancel();
      await bloc.close();
    });
  });
}
