import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_state.dart';

class _MockAttendanceRequestRepository implements AttendanceRequestRepository {
  AttendanceRequestDetailData? mockDetail;
  ApiException? errorToThrow;
  String? lastApprovedId;
  bool? lastIsApproved;
  String? lastApproverNotes;
  String? lastDeletedId;

  @override
  Future<AttendanceRequestListResponse> getAttendanceRequests({
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceRequestDetailData> getAttendanceRequestDetail(
      String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockDetail ??
        AttendanceRequestDetailData(
          id: id,
          status: 'requested',
          method: 'photo',
          reason: 'Kunjungan klien',
          attendanceType: 'in',
          latitude: -6.229728,
          longitude: 106.816666,
          address: 'Menara Mandiri, Jakarta Selatan',
          employee: const AttendanceRequestEmployeeModel(
            id: 'emp-1',
            firstName: 'Sarah',
            lastName: 'Jenkins',
            email: 'sarah@oasish.com',
          ),
        );
  }

  @override
  Future<void> approveAttendanceRequest({
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
  Future<void> deleteAttendanceRequest(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastDeletedId = id;
  }
}

void main() {
  group('AttendanceRequestDetailBloc Tests', () {
    late _MockAttendanceRequestRepository repository;

    setUp(() {
      repository = _MockAttendanceRequestRepository();
    });

    const testDetail = AttendanceRequestDetailData(
      id: 'req-123',
      status: 'requested',
      method: 'photo',
      reason: 'Kunjungan kerja',
      attendanceType: 'in',
      latitude: -6.229728,
      longitude: 106.816666,
      address: 'Menara Mandiri, Jakarta Selatan',
      employee: AttendanceRequestEmployeeModel(
        id: 'emp-1',
        firstName: 'Sarah',
        lastName: 'Jenkins',
      ),
    );

    test('emits [loading, success] on AttendanceRequestDetailStarted success',
        () async {
      repository.mockDetail = testDetail;
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const AttendanceRequestDetailStarted(id: 'req-123', isApprover: true),
      );
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, AttendanceRequestDetailStatus.loading);
      expect(states[0].id, 'req-123');
      expect(states[0].isApprover, isTrue);

      expect(states[1].status, AttendanceRequestDetailStatus.success);
      expect(states[1].detail, testDetail);

      await sub.cancel();
      await bloc.close();
    });

    test(
        'emits [loading, failure] on AttendanceRequestDetailStarted failure with ApiException',
        () async {
      repository.errorToThrow = const ApiException(
        message: 'Data permohonan presensi tidak ditemukan',
        statusCode: 404,
      );
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AttendanceRequestDetailStarted(id: 'invalid-id'));
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, AttendanceRequestDetailStatus.loading);
      expect(states[1].status, AttendanceRequestDetailStatus.failure);
      expect(
          states[1].errorMessage, 'Data permohonan presensi tidak ditemukan');
      expect(states[1].statusCode, 404);

      await sub.cancel();
      await bloc.close();
    });

    test('emits [success] on AttendanceRequestDetailRefreshRequested',
        () async {
      repository.mockDetail = testDetail;
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const AttendanceRequestDetailStarted(id: 'req-123'));
      await pumpEventQueue();

      final updatedDetail = testDetail.copyWith(reason: 'Refreshed reason');
      repository.mockDetail = updatedDetail;

      bloc.add(const AttendanceRequestDetailRefreshRequested());
      await pumpEventQueue();

      expect(states.last.status, AttendanceRequestDetailStatus.success);
      expect(states.last.detail?.reason, 'Refreshed reason');

      await sub.cancel();
      await bloc.close();
    });

    test(
        'emits [submittingAction, actionSuccess] on approve submit (isApproved: true)',
        () async {
      repository.mockDetail = testDetail;
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const AttendanceRequestDetailStarted(id: 'req-123', isApprover: true),
      );
      await pumpEventQueue();

      bloc.add(
        const AttendanceRequestDetailApproveSubmitted(
          isApproved: true,
          approverNotes: 'Disetujui silakan bertugas',
        ),
      );
      await pumpEventQueue();

      expect(states.length, 4);
      expect(states[2].status, AttendanceRequestDetailStatus.submittingAction);
      expect(states[3].status, AttendanceRequestDetailStatus.actionSuccess);
      expect(states[3].detail?.isApproved, isTrue);
      expect(states[3].detail?.approverNote, 'Disetujui silakan bertugas');
      expect(repository.lastApprovedId, 'req-123');
      expect(repository.lastIsApproved, isTrue);
      expect(repository.lastApproverNotes, 'Disetujui silakan bertugas');

      await sub.cancel();
      await bloc.close();
    });

    test(
        'emits [submittingAction, actionSuccess] on reject submit (isApproved: false)',
        () async {
      repository.mockDetail = testDetail;
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const AttendanceRequestDetailStarted(id: 'req-123', isApprover: true),
      );
      await pumpEventQueue();

      bloc.add(
        const AttendanceRequestDetailApproveSubmitted(
          isApproved: false,
          approverNotes: 'Lokasi tidak sesuai jadwal',
        ),
      );
      await pumpEventQueue();

      expect(states.length, 4);
      expect(states[2].status, AttendanceRequestDetailStatus.submittingAction);
      expect(states[3].status, AttendanceRequestDetailStatus.actionSuccess);
      expect(states[3].detail?.isRejected, isTrue);
      expect(states[3].detail?.approverNote, 'Lokasi tidak sesuai jadwal');
      expect(repository.lastApprovedId, 'req-123');
      expect(repository.lastIsApproved, isFalse);
      expect(repository.lastApproverNotes, 'Lokasi tidak sesuai jadwal');

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, deleteSuccess] on delete submit', () async {
      repository.mockDetail = testDetail;
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const AttendanceRequestDetailStarted(id: 'req-123', isApprover: false),
      );
      await pumpEventQueue();

      bloc.add(const AttendanceRequestDetailDeleteSubmitted());
      await pumpEventQueue();

      expect(states.length, 4);
      expect(states[2].status, AttendanceRequestDetailStatus.submittingAction);
      expect(states[3].status, AttendanceRequestDetailStatus.deleteSuccess);
      expect(states[3].actionMessage, 'Permohonan presensi berhasil dihapus');
      expect(repository.lastDeletedId, 'req-123');

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, actionFailure] on approve failure',
        () async {
      repository.mockDetail = testDetail;
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const AttendanceRequestDetailStarted(id: 'req-123', isApprover: true),
      );
      await pumpEventQueue();

      repository.errorToThrow = const ApiException(
        message: 'Gagal memperbarui status pengajuan',
        statusCode: 500,
      );

      bloc.add(
        const AttendanceRequestDetailApproveSubmitted(isApproved: true),
      );
      await pumpEventQueue();

      expect(states.length, 4);
      expect(states[2].status, AttendanceRequestDetailStatus.submittingAction);
      expect(states[3].status, AttendanceRequestDetailStatus.actionFailure);
      expect(
          states[3].errorMessage, 'Gagal memperbarui status pengajuan');
      expect(states[3].statusCode, 500);

      await sub.cancel();
      await bloc.close();
    });

    test('emits [submittingAction, actionFailure] on delete failure', () async {
      repository.mockDetail = testDetail;
      final bloc = AttendanceRequestDetailBloc(repository: repository);
      final states = <AttendanceRequestDetailState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        const AttendanceRequestDetailStarted(id: 'req-123', isApprover: false),
      );
      await pumpEventQueue();

      repository.errorToThrow = const ApiException(
        message: 'Tidak dapat menghapus pengajuan yang telah disetujui',
        statusCode: 400,
      );

      bloc.add(const AttendanceRequestDetailDeleteSubmitted());
      await pumpEventQueue();

      expect(states.length, 4);
      expect(states[2].status, AttendanceRequestDetailStatus.submittingAction);
      expect(states[3].status, AttendanceRequestDetailStatus.actionFailure);
      expect(states[3].errorMessage,
          'Tidak dapat menghapus pengajuan yang telah disetujui');
      expect(states[3].statusCode, 400);

      await sub.cancel();
      await bloc.close();
    });
  });
}
