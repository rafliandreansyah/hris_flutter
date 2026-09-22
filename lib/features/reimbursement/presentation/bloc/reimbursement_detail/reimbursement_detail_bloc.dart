import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_state.dart';

class ReimbursementDetailBloc
    extends Bloc<ReimbursementDetailEvent, ReimbursementDetailState> {
  final ReimbursementRepository _repository;
  String? _currentId;

  ReimbursementDetailBloc({ReimbursementRepository? repository})
      : _repository = repository ?? ReimbursementRepositoryImpl(),
        super(const ReimbursementDetailState()) {
    on<ReimbursementDetailFetched>(_onFetched);
    on<ReimbursementDetailApproved>(_onApproved);
  }

  Future<void> _onFetched(
    ReimbursementDetailFetched event,
    Emitter<ReimbursementDetailState> emit,
  ) async {
    _currentId = event.id;
    emit(state.copyWith(
      status: ReimbursementDetailStatus.loading,
      clearErrorMessage: true,
    ));

    try {
      final detail = await _repository.getReimbursementDetail(event.id);
      emit(state.copyWith(
        status: ReimbursementDetailStatus.success,
        detail: detail,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReimbursementDetailStatus.failure,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onApproved(
    ReimbursementDetailApproved event,
    Emitter<ReimbursementDetailState> emit,
  ) async {
    if (_currentId == null) return;
    emit(state.copyWith(
      isActionLoading: true,
      clearActionMessage: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.approveReimbursement(
        id: _currentId!,
        isApproved: event.isApproved,
        approverNotes: event.approverNotes,
        rejectionReason: event.rejectionReason,
      );

      emit(state.copyWith(
        isActionLoading: false,
        actionSuccessMessage: event.isApproved
            ? 'Pengajuan reimbursement berhasil disetujui'
            : 'Pengajuan reimbursement berhasil ditolak',
      ));

      // Refresh detail
      final updated = await _repository.getReimbursementDetail(_currentId!);
      emit(state.copyWith(detail: updated));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}
