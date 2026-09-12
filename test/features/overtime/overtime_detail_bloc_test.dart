import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_bloc.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_event.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_state.dart';
import 'package:image_picker/image_picker.dart';

class _MockOvertimeRepository implements OvertimeRepository {
  OvertimeDetailData? mockDetail;
  ApiException? errorToThrow;
  String? lastApprovedId;
  bool? lastIsApproved;
  String? lastApproverNotes;
  String? lastDeletedId;

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
    if (errorToThrow != null) throw errorToThrow!;
    return mockDetail ??
        OvertimeDetailData(
          id: id,
          status: 'requested',
          employee: const OvertimeEmployeeModel(
            id: 'emp-1',
            firstName: 'Sarah',
            lastName: 'Jenkins',
            email: 'sarah@oasish.com',
          ),
        );
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastApprovedId = id;
    lastIsApproved = isApproved;
    lastApproverNotes = approverNotes;
  }

  @override
  Future<void> deleteOvertime(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastDeletedId = id;
  }
}

void main() {
  group('OvertimeDetailBloc Tests', () {
    late _MockOvertimeRepository repository;

    setUp(() {
      repository = _MockOvertimeRepository();
    });

    const testDetail = OvertimeDetailData(
      id: 'ot-123',
      status: 'requested',
      notes: 'Critical bug fix',
      employee: OvertimeEmployeeModel(
        id: 'emp-1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
        email: 'sarah@oasish.com',
      ),
    );

    test('emits [loading, success] on OvertimeDetailStarted success', () async {
      repository.mockDetail = testDetail;
      final bloc = OvertimeDetailBloc(repository: repository);
      final states = <OvertimeDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const OvertimeDetailStarted(id: 'ot-123', isApprover: true));
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, OvertimeDetailStatus.loading);
      expect(states[0].id, 'ot-123');
      expect(states[0].isApprover, isTrue);

      expect(states[1].status, OvertimeDetailStatus.success);
      expect(states[1].detail, testDetail);

      await sub.cancel();
      await bloc.close();
    });

    test('emits [loading, failure] on OvertimeDetailStarted failure', () async {
      repository.errorToThrow = ApiException(
        message: 'Pengajuan tidak ditemukan',
        statusCode: 404,
      );
      final bloc = OvertimeDetailBloc(repository: repository);
      final states = <OvertimeDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const OvertimeDetailStarted(id: 'ot-404', isApprover: false));
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, OvertimeDetailStatus.loading);
      expect(states[1].status, OvertimeDetailStatus.failure);
      expect(states[1].errorMessage, 'Pengajuan tidak ditemukan');
      expect(states[1].statusCode, 404);

      await sub.cancel();
      await bloc.close();
    });

    test('emits [success] on OvertimeDetailRefreshRequested', () async {
      repository.mockDetail = testDetail;
      final bloc = OvertimeDetailBloc(repository: repository);
      final states = <OvertimeDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const OvertimeDetailStarted(id: 'ot-123'));
      await pumpEventQueue();

      final updatedDetail = testDetail.copyWith(notes: 'Refreshed notes');
      repository.mockDetail = updatedDetail;

      bloc.add(const OvertimeDetailRefreshRequested());
      await pumpEventQueue();

      expect(states.last.status, OvertimeDetailStatus.success);
      expect(states.last.detail?.notes, 'Refreshed notes');

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, actionSuccess] on approve submit', () async {
      repository.mockDetail = testDetail;
      final bloc = OvertimeDetailBloc(repository: repository);
      final states = <OvertimeDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const OvertimeDetailStarted(id: 'ot-123', isApprover: true));
      await pumpEventQueue();

      bloc.add(const OvertimeDetailApproveSubmitted(
        isApproved: true,
        approverNotes: 'Approved by lead',
      ));
      await pumpEventQueue();

      expect(repository.lastApprovedId, 'ot-123');
      expect(repository.lastIsApproved, isTrue);
      expect(repository.lastApproverNotes, 'Approved by lead');

      expect(states.any((s) => s.status == OvertimeDetailStatus.submittingAction), isTrue);
      final lastState = states.last;
      expect(lastState.status, OvertimeDetailStatus.actionSuccess);
      expect(lastState.detail?.isApproved, isTrue);
      expect(lastState.actionMessage, 'Pengajuan lembur berhasil disetujui');

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, actionSuccess] on reject submit', () async {
      repository.mockDetail = testDetail;
      final bloc = OvertimeDetailBloc(repository: repository);
      final states = <OvertimeDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const OvertimeDetailStarted(id: 'ot-123', isApprover: true));
      await pumpEventQueue();

      bloc.add(const OvertimeDetailApproveSubmitted(
        isApproved: false,
        approverNotes: 'Overtime rejected',
      ));
      await pumpEventQueue();

      expect(repository.lastApprovedId, 'ot-123');
      expect(repository.lastIsApproved, isFalse);

      final lastState = states.last;
      expect(lastState.status, OvertimeDetailStatus.actionSuccess);
      expect(lastState.detail?.isRejected, isTrue);
      expect(lastState.actionMessage, 'Pengajuan lembur berhasil ditolak');

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, deleteSuccess] on delete submit', () async {
      repository.mockDetail = testDetail;
      final bloc = OvertimeDetailBloc(repository: repository);
      final states = <OvertimeDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const OvertimeDetailStarted(id: 'ot-123', isApprover: false));
      await pumpEventQueue();

      bloc.add(const OvertimeDetailDeleteSubmitted());
      await pumpEventQueue();

      expect(repository.lastDeletedId, 'ot-123');
      final lastState = states.last;
      expect(lastState.status, OvertimeDetailStatus.deleteSuccess);
      expect(lastState.actionMessage, 'Pengajuan lembur berhasil dihapus');

      await sub.cancel();
      await bloc.close();
    });
  });
}
