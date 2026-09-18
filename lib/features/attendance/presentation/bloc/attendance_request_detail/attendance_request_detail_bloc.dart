import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_request_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_state.dart';

class AttendanceRequestDetailBloc
    extends Bloc<AttendanceRequestDetailEvent, AttendanceRequestDetailState> {
  final AttendanceRequestRepository _repository;

  AttendanceRequestDetailBloc({AttendanceRequestRepository? repository})
      : _repository = repository ?? AttendanceRequestRepositoryImpl(),
        super(const AttendanceRequestDetailState()) {
    on<AttendanceRequestDetailStarted>(_onStarted);
    on<AttendanceRequestDetailRefreshRequested>(_onRefreshRequested);
    on<AttendanceRequestDetailApproveSubmitted>(_onApproveSubmitted);
    on<AttendanceRequestDetailDeleteSubmitted>(_onDeleteSubmitted);
  }

  Future<void> _onStarted(
    AttendanceRequestDetailStarted event,
    Emitter<AttendanceRequestDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: AttendanceRequestDetailStatus.loading,
      id: event.id,
      isApprover: event.isApprover,
      errorMessage: null,
      statusCode: null,
    ));

    try {
      final detail = await _repository.getAttendanceRequestDetail(event.id);
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.failure,
        errorMessage: 'Gagal memuat detail permohonan presensi: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    AttendanceRequestDetailRefreshRequested event,
    Emitter<AttendanceRequestDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    try {
      final detail = await _repository.getAttendanceRequestDetail(state.id);
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.failure,
        errorMessage: 'Gagal memuat ulang detail permohonan presensi: $e',
      ));
    }
  }

  Future<void> _onApproveSubmitted(
    AttendanceRequestDetailApproveSubmitted event,
    Emitter<AttendanceRequestDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    emit(state.copyWith(
      status: AttendanceRequestDetailStatus.submittingAction,
      errorMessage: null,
      actionMessage: null,
    ));

    try {
      await _repository.approveAttendanceRequest(
        id: state.id,
        isApproved: event.isApproved,
        approverNotes: event.approverNotes,
      );

      final msg = event.isApproved
          ? 'Permohonan presensi luar kantor berhasil disetujui'
          : 'Permohonan presensi luar kantor berhasil ditolak';

      final updatedDetail = state.detail?.copyWith(
        status: event.isApproved ? 'approved' : 'rejected',
        approverNote: event.approverNotes,
      );

      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.actionSuccess,
        detail: updatedDetail,
        actionMessage: msg,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.actionFailure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.actionFailure,
        errorMessage: 'Gagal memproses persetujuan presensi: $e',
      ));
    }
  }

  Future<void> _onDeleteSubmitted(
    AttendanceRequestDetailDeleteSubmitted event,
    Emitter<AttendanceRequestDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    emit(state.copyWith(
      status: AttendanceRequestDetailStatus.submittingAction,
      errorMessage: null,
      actionMessage: null,
    ));

    try {
      await _repository.deleteAttendanceRequest(state.id);

      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.deleteSuccess,
        actionMessage: 'Permohonan presensi berhasil dihapus',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.actionFailure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceRequestDetailStatus.actionFailure,
        errorMessage: 'Gagal menghapus permohonan presensi: $e',
      ));
    }
  }
}
