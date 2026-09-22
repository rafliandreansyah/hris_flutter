import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_state.dart';

class CashAdvanceDetailBloc
    extends Bloc<CashAdvanceDetailEvent, CashAdvanceDetailState> {
  final ReimbursementRepository _repository;
  String? _currentId;

  CashAdvanceDetailBloc({ReimbursementRepository? repository})
      : _repository = repository ?? ReimbursementRepositoryImpl(),
        super(const CashAdvanceDetailState()) {
    on<CashAdvanceDetailFetched>(_onFetched);
    on<CashAdvanceDetailApproved>(_onApproved);
    on<CashAdvanceRefundSubmitted>(_onRefundSubmitted);
  }

  Future<void> _onFetched(
    CashAdvanceDetailFetched event,
    Emitter<CashAdvanceDetailState> emit,
  ) async {
    _currentId = event.id;
    emit(state.copyWith(
      status: CashAdvanceDetailStatus.loading,
      clearErrorMessage: true,
    ));

    try {
      final detail = await _repository.getCashAdvanceDetail(event.id);
      emit(state.copyWith(
        status: CashAdvanceDetailStatus.success,
        detail: detail,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CashAdvanceDetailStatus.failure,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onApproved(
    CashAdvanceDetailApproved event,
    Emitter<CashAdvanceDetailState> emit,
  ) async {
    if (_currentId == null) return;
    emit(state.copyWith(
      isActionLoading: true,
      clearActionMessage: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.approveCashAdvance(
        id: _currentId!,
        isApproved: event.isApproved,
        approvedAmount: event.approvedAmount,
        approverNotes: event.approverNotes,
      );

      emit(state.copyWith(
        isActionLoading: false,
        actionSuccessMessage: event.isApproved
            ? 'Kasbon berhasil disetujui'
            : 'Kasbon berhasil ditolak',
      ));

      // Refresh detail
      final updated = await _repository.getCashAdvanceDetail(_currentId!);
      emit(state.copyWith(detail: updated));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onRefundSubmitted(
    CashAdvanceRefundSubmitted event,
    Emitter<CashAdvanceDetailState> emit,
  ) async {
    if (_currentId == null) return;
    emit(state.copyWith(
      isActionLoading: true,
      clearActionMessage: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.refundCashAdvance(
        id: _currentId!,
        amount: event.amount,
        method: event.method,
        refundDate: event.refundDate,
        notes: event.notes,
        proofFile: event.proofFile,
      );

      emit(state.copyWith(
        isActionLoading: false,
        actionSuccessMessage: 'Pengembalian sisa kasbon berhasil diserahkan',
      ));

      // Refresh detail
      final updated = await _repository.getCashAdvanceDetail(_currentId!);
      emit(state.copyWith(detail: updated));
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}
