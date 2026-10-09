import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_state.dart';

class PayrollEmployeeSlipsBloc
    extends Bloc<PayrollEmployeeSlipsEvent, PayrollEmployeeSlipsState> {
  final PayrollRepository _repository;

  PayrollEmployeeSlipsBloc({
    PayrollRepository? repository,
    String employeeId = '',
  })  : _repository = repository ?? PayrollRepositoryImpl(),
        super(PayrollEmployeeSlipsState(
          employeeId: employeeId,
          selectedYear: DateTime.now().year,
        )) {
    on<PayrollEmployeeSlipsStarted>(_onStarted);
    on<PayrollEmployeeSlipsYearChanged>(_onYearChanged);
    on<PayrollEmployeeSlipsFilterApplied>(_onFilterApplied);
    on<PayrollEmployeeSlipsSearchChanged>(
      _onSearchChanged,
      transformer: debounceRestartable(),
    );
    on<PayrollEmployeeSlipsPrivacyToggled>(_onPrivacyToggled);
    on<PayrollEmployeeSlipsRefreshed>(_onRefreshed);
    on<PayrollEmployeeSlipsLoadMore>(_onLoadMore);
  }

  Future<void> _onStarted(
    PayrollEmployeeSlipsStarted event,
    Emitter<PayrollEmployeeSlipsState> emit,
  ) async {
    emit(state.copyWith(
      status: PayrollEmployeeSlipsStatus.loading,
      employeeId: event.employeeId,
    ));

    await _fetchSlips(emit, page: 1, employeeId: event.employeeId);
  }

  Future<void> _onYearChanged(
    PayrollEmployeeSlipsYearChanged event,
    Emitter<PayrollEmployeeSlipsState> emit,
  ) async {
    if (state.selectedYear == event.year) return;

    emit(state.copyWith(
      selectedYear: event.year,
      status: PayrollEmployeeSlipsStatus.loading,
    ));

    await _fetchSlips(emit, page: 1, year: event.year);
  }

  Future<void> _onFilterApplied(
    PayrollEmployeeSlipsFilterApplied event,
    Emitter<PayrollEmployeeSlipsState> emit,
  ) async {
    final targetYear = event.year ?? state.selectedYear;
    emit(state.copyWith(
      status: PayrollEmployeeSlipsStatus.loading,
      selectedYear: targetYear,
      selectedMonth: event.month,
      clearSelectedMonth: event.month == null,
      selectedStatus: event.status,
      clearSelectedStatus: event.status == null,
    ));

    await _fetchSlips(
      emit,
      page: 1,
      year: targetYear,
      month: event.month,
      status: event.status,
    );
  }

  Future<void> _onSearchChanged(
    PayrollEmployeeSlipsSearchChanged event,
    Emitter<PayrollEmployeeSlipsState> emit,
  ) async {
    final query = event.query.trim();
    if (state.searchQuery == query) return;

    emit(state.copyWith(
      searchQuery: query,
      status: PayrollEmployeeSlipsStatus.loading,
    ));

    await _fetchSlips(emit, page: 1, search: query);
  }

  void _onPrivacyToggled(
    PayrollEmployeeSlipsPrivacyToggled event,
    Emitter<PayrollEmployeeSlipsState> emit,
  ) {
    emit(state.copyWith(isPrivacyMasked: !state.isPrivacyMasked));
  }

  Future<void> _onRefreshed(
    PayrollEmployeeSlipsRefreshed event,
    Emitter<PayrollEmployeeSlipsState> emit,
  ) async {
    try {
      final response = await _repository.getPayrolls(
        page: 1,
        size: 10,
        employeeId: state.employeeId,
        year: state.selectedYear,
        month: state.selectedMonth,
        status: state.selectedStatus,
        search: state.searchQuery,
      );

      emit(state.copyWith(
        status: PayrollEmployeeSlipsStatus.success,
        slips: response.data,
        page: 1,
        hasMore: response.meta.page < response.meta.totalPages,
        clearErrorMessage: true,
      ));
    } catch (_) {}
  }

  Future<void> _onLoadMore(
    PayrollEmployeeSlipsLoadMore event,
    Emitter<PayrollEmployeeSlipsState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.status == PayrollEmployeeSlipsStatus.loading) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.page + 1;
      final response = await _repository.getPayrolls(
        page: nextPage,
        size: 10,
        employeeId: state.employeeId,
        year: state.selectedYear,
        month: state.selectedMonth,
        status: state.selectedStatus,
        search: state.searchQuery,
      );

      emit(state.copyWith(
        isLoadingMore: false,
        slips: [...state.slips, ...response.data],
        page: nextPage,
        hasMore: response.meta.page < response.meta.totalPages,
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _fetchSlips(
    Emitter<PayrollEmployeeSlipsState> emit, {
    required int page,
    String? employeeId,
    int? year,
    int? month,
    String? status,
    String? search,
  }) async {
    try {
      final empId = employeeId ?? state.employeeId;
      if (empId.isEmpty) {
        emit(state.copyWith(
          status: PayrollEmployeeSlipsStatus.failure,
          errorMessage: 'Employee ID tidak valid',
        ));
        return;
      }

      final response = await _repository.getPayrolls(
        page: page,
        size: 10,
        employeeId: empId,
        year: year ?? state.selectedYear,
        month: month ?? state.selectedMonth,
        status: status ?? state.selectedStatus,
        search: search ?? state.searchQuery,
      );

      emit(state.copyWith(
        status: PayrollEmployeeSlipsStatus.success,
        slips: response.data,
        page: response.meta.page,
        hasMore: response.meta.page < response.meta.totalPages,
        clearErrorMessage: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PayrollEmployeeSlipsStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PayrollEmployeeSlipsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
