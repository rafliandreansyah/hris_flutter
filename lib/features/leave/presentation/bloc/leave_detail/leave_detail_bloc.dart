import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_event.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_state.dart';

class LeaveDetailBloc extends Bloc<LeaveDetailEvent, LeaveDetailState> {
  final LeaveRepository _repository;

  LeaveDetailBloc({LeaveRepository? repository})
      : _repository = repository ?? LeaveRepositoryImpl(),
        super(const LeaveDetailState()) {
    on<LeaveDetailStarted>(_onStarted);
    on<LeaveDetailRefreshRequested>(_onRefreshRequested);
    on<LeaveDetailApproveSubmitted>(_onApproveSubmitted);
    on<LeaveDetailDeleteSubmitted>(_onDeleteSubmitted);
  }

  Future<void> _onStarted(
    LeaveDetailStarted event,
    Emitter<LeaveDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: LeaveDetailStatus.loading,
      id: event.id,
      isApprover: event.isApprover,
      errorMessage: null,
      statusCode: null,
    ));

    try {
      final detail = await _repository.getLeaveRequestDetail(event.id);
      emit(state.copyWith(
        status: LeaveDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.failure,
        errorMessage: 'Gagal memuat detail pengajuan cuti: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    LeaveDetailRefreshRequested event,
    Emitter<LeaveDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    try {
      final detail = await _repository.getLeaveRequestDetail(state.id);
      emit(state.copyWith(
        status: LeaveDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.failure,
        errorMessage: 'Gagal memuat ulang detail pengajuan cuti: $e',
      ));
    }
  }

  Future<void> _onApproveSubmitted(
    LeaveDetailApproveSubmitted event,
    Emitter<LeaveDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    emit(state.copyWith(
      status: LeaveDetailStatus.submittingAction,
      errorMessage: null,
      actionMessage: null,
    ));

    try {
      await _repository.approveLeaveRequest(
        state.id,
        isApproved: event.isApproved,
        approverNotes: event.approverNotes,
      );

      final msg = event.isApproved
          ? 'Pengajuan cuti berhasil disetujui'
          : 'Pengajuan cuti berhasil ditolak';

      final updatedDetail = state.detail?.copyWith(
        status: event.isApproved ? 'approved' : 'rejected',
        approverNotes: event.approverNotes,
      );

      emit(state.copyWith(
        status: LeaveDetailStatus.actionSuccess,
        detail: updatedDetail,
        actionMessage: msg,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.actionFailure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.actionFailure,
        errorMessage: 'Gagal memproses persetujuan cuti: $e',
      ));
    }
  }

  Future<void> _onDeleteSubmitted(
    LeaveDetailDeleteSubmitted event,
    Emitter<LeaveDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    emit(state.copyWith(
      status: LeaveDetailStatus.submittingAction,
      errorMessage: null,
      actionMessage: null,
    ));

    try {
      await _repository.deleteLeaveRequest(state.id);

      emit(state.copyWith(
        status: LeaveDetailStatus.deleteSuccess,
        actionMessage: 'Pengajuan cuti berhasil dihapus',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.actionFailure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LeaveDetailStatus.actionFailure,
        errorMessage: 'Gagal menghapus pengajuan cuti: $e',
      ));
    }
  }
}
