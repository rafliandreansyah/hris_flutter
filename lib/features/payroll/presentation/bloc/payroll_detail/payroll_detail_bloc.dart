import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_state.dart';

class PayrollDetailBloc extends Bloc<PayrollDetailEvent, PayrollDetailState> {
  final PayrollRepository _repository;
  String? _payrollId;

  PayrollDetailBloc({PayrollRepository? repository})
      : _repository = repository ?? PayrollRepositoryImpl(),
        super(const PayrollDetailState()) {
    on<PayrollDetailFetched>(_onFetched);
    on<PayrollDetailDownloadRequested>(_onDownloadRequested);
    on<PayrollDetailPrivacyToggled>(_onPrivacyToggled);
  }

  Future<void> _onFetched(
    PayrollDetailFetched event,
    Emitter<PayrollDetailState> emit,
  ) async {
    _payrollId = event.id;
    emit(state.copyWith(status: PayrollDetailStatus.loading));

    try {
      final detail = await _repository.getPayrollDetail(event.id);
      emit(state.copyWith(
        status: PayrollDetailStatus.success,
        detail: detail,
        clearErrorMessage: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PayrollDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PayrollDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDownloadRequested(
    PayrollDetailDownloadRequested event,
    Emitter<PayrollDetailState> emit,
  ) async {
    final id = _payrollId ?? state.detail?.id;
    if (id == null) return;

    emit(state.copyWith(isDownloading: true, clearDownloadedPdfUrl: true));

    try {
      final downloadRes = await _repository.downloadPayslip(
        id,
        force: event.force,
      );

      emit(state.copyWith(
        isDownloading: false,
        downloadedPdfUrl: downloadRes.payslipUrl,
        clearErrorMessage: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isDownloading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDownloading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onPrivacyToggled(
    PayrollDetailPrivacyToggled event,
    Emitter<PayrollDetailState> emit,
  ) {
    emit(state.copyWith(isPrivacyMasked: !state.isPrivacyMasked));
  }
}
