import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_state.dart';

class DisburseActionBloc
    extends Bloc<DisburseActionEvent, DisburseActionState> {
  final ReimbursementRepository _repository;

  DisburseActionBloc({ReimbursementRepository? repository})
      : _repository = repository ?? ReimbursementRepositoryImpl(),
        super(const DisburseActionState()) {
    on<DisburseMethodChanged>(_onMethodChanged);
    on<DisburseProofFileChanged>(_onProofFileChanged);
    on<DisburseSubmitted>(_onSubmitted);
  }

  void _onMethodChanged(
    DisburseMethodChanged event,
    Emitter<DisburseActionState> emit,
  ) {
    emit(state.copyWith(method: event.method));
  }

  void _onProofFileChanged(
    DisburseProofFileChanged event,
    Emitter<DisburseActionState> emit,
  ) {
    emit(state.copyWith(
      proofFile: event.file,
      clearProofFile: event.file == null,
    ));
  }

  Future<void> _onSubmitted(
    DisburseSubmitted event,
    Emitter<DisburseActionState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      clearErrorMessage: true,
    ));

    try {
      await _repository.disburseReimbursement(
        id: event.claimId,
        disbursementMethod: state.method,
        paymentReference: event.paymentReference,
        notes: event.notes,
        bankName: event.bankName,
        bankAccountNumber: event.bankAccountNumber,
        bankAccountHolder: event.bankAccountHolder,
        payrollPeriodId: event.payrollPeriodId,
        proofFile: state.proofFile,
      );

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}
