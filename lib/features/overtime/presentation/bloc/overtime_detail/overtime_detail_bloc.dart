import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_event.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_state.dart';

class OvertimeDetailBloc extends Bloc<OvertimeDetailEvent, OvertimeDetailState> {
  final OvertimeRepository _repository;

  OvertimeDetailBloc({OvertimeRepository? repository})
      : _repository = repository ?? OvertimeRepositoryImpl(),
        super(const OvertimeDetailState()) {
    on<OvertimeDetailStarted>(_onStarted);
    on<OvertimeDetailRefreshRequested>(_onRefreshRequested);
    on<OvertimeDetailApproveSubmitted>(_onApproveSubmitted);
    on<OvertimeDetailDeleteSubmitted>(_onDeleteSubmitted);
  }

  Future<void> _onStarted(
    OvertimeDetailStarted event,
    Emitter<OvertimeDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: OvertimeDetailStatus.loading,
      id: event.id,
      isApprover: event.isApprover,
      errorMessage: null,
      statusCode: null,
    ));

    try {
      final detail = await _repository.getOvertimeDetail(event.id);
      emit(state.copyWith(
        status: OvertimeDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.failure,
        errorMessage: 'Gagal memuat detail pengajuan lembur: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    OvertimeDetailRefreshRequested event,
    Emitter<OvertimeDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    try {
      final detail = await _repository.getOvertimeDetail(state.id);
      emit(state.copyWith(
        status: OvertimeDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.failure,
        errorMessage: 'Gagal memuat ulang detail pengajuan lembur: $e',
      ));
    }
  }

  Future<void> _onApproveSubmitted(
    OvertimeDetailApproveSubmitted event,
    Emitter<OvertimeDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    emit(state.copyWith(
      status: OvertimeDetailStatus.submittingAction,
      errorMessage: null,
      actionMessage: null,
    ));

    try {
      await _repository.approveOvertime(
        id: state.id,
        isApproved: event.isApproved,
        approverNotes: event.approverNotes,
      );

      final msg = event.isApproved
          ? 'Pengajuan lembur berhasil disetujui'
          : 'Pengajuan lembur berhasil ditolak';

      final updatedDetail = state.detail?.copyWith(
        status: event.isApproved ? 'approved' : 'rejected',
        approverNotes: event.approverNotes,
      );

      emit(state.copyWith(
        status: OvertimeDetailStatus.actionSuccess,
        detail: updatedDetail,
        actionMessage: msg,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.actionFailure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.actionFailure,
        errorMessage: 'Gagal memproses persetujuan lembur: $e',
      ));
    }
  }

  Future<void> _onDeleteSubmitted(
    OvertimeDetailDeleteSubmitted event,
    Emitter<OvertimeDetailState> emit,
  ) async {
    if (state.id.isEmpty) return;

    emit(state.copyWith(
      status: OvertimeDetailStatus.submittingAction,
      errorMessage: null,
      actionMessage: null,
    ));

    try {
      await _repository.deleteOvertime(state.id);

      emit(state.copyWith(
        status: OvertimeDetailStatus.deleteSuccess,
        actionMessage: 'Pengajuan lembur berhasil dihapus',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.actionFailure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OvertimeDetailStatus.actionFailure,
        errorMessage: 'Gagal menghapus pengajuan lembur: $e',
      ));
    }
  }
}
