import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:hris_flutter/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_state.dart';

class PayrollListBloc extends Bloc<PayrollListEvent, PayrollListState> {
  final PayrollRepository _repository;
  final SecureStorageService _storageService;

  PayrollListBloc({
    PayrollRepository? repository,
    SecureStorageService? storageService,
  })  : _repository = repository ?? PayrollRepositoryImpl(),
        _storageService = storageService ?? SecureStorageService.instance,
        super(PayrollListState(selectedYear: DateTime.now().year)) {
    on<PayrollListStarted>(_onStarted);
    on<PayrollListTabChanged>(_onTabChanged);
    on<PayrollListYearChanged>(_onYearChanged);
    on<PayrollListFilterApplied>(_onFilterApplied);
    on<PayrollListSearchChanged>(
      _onSearchChanged,
      transformer: debounceRestartable(),
    );
    on<PayrollListPrivacyToggled>(_onPrivacyToggled);
    on<PayrollListRefreshed>(_onRefreshed);
    on<PayrollListLoadMore>(_onLoadMore);
  }

  Future<void> _onStarted(
    PayrollListStarted event,
    Emitter<PayrollListState> emit,
  ) async {
    emit(state.copyWith(
      status: PayrollListStatus.loading,
      isMyLoading: true,
      isEmployeesLoading: true,
    ));

    final canViewTeam = _storageService.hasPermissionInMemory(
          AppPermissions.payrollSlipView,
        ) ||
        _storageService.hasPermissionInMemory('payroll.view') ||
        _storageService.hasPermissionInMemory('MANAGE_PAYROLL');

    try {
      final periodsFuture = _repository.getPayrollPeriods(
        year: state.selectedYear,
      );

      final myResponseFuture = _repository.getMyPayslips(
        page: 1,
        size: 10,
        year: state.selectedYear,
        month: state.selectedMonth,
      );

      final results = await Future.wait([periodsFuture, myResponseFuture]);
      final periods = results[0] as List<dynamic>;
      final myResponse = results[1] as PayrollListResponseModel;

      PayrollSlipModel? latestSlip;
      if (myResponse.data.isNotEmpty) {
        latestSlip = myResponse.data.first;
      }

      List<PayrollEmployeeItemModel> employees = [];
      int employeesPage = 1;
      bool employeesHasMore = false;

      if (canViewTeam) {
        try {
          final empResponse = await _repository.getPayrollEmployees(
            page: 1,
            size: 20,
            search: state.searchQuery,
            companyId: state.selectedCompanyId,
            departmentId: state.selectedDepartmentId,
          );
          employees = empResponse.data;
          employeesPage = empResponse.meta.page;
          employeesHasMore = empResponse.meta.page < empResponse.meta.totalPages;
        } catch (_) {}
      }

      emit(state.copyWith(
        status: PayrollListStatus.success,
        isMyLoading: false,
        isEmployeesLoading: false,
        periods: periods.cast(),
        mySlips: myResponse.data,
        latestSlip: latestSlip,
        canViewTeam: canViewTeam,
        myPage: myResponse.meta.page,
        myHasMore: myResponse.meta.page < myResponse.meta.totalPages,
        employees: employees,
        employeesPage: employeesPage,
        employeesHasMore: employeesHasMore,
        clearErrorMessage: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isMyLoading: false,
        isEmployeesLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isMyLoading: false,
        isEmployeesLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTabChanged(
    PayrollListTabChanged event,
    Emitter<PayrollListState> emit,
  ) async {
    if (state.activeTab == event.tabIndex) return;

    emit(state.copyWith(activeTab: event.tabIndex));

    if (event.tabIndex == 1 && state.employees.isEmpty && state.canViewTeam) {
      await _fetchEmployees(emit, page: 1);
    }
  }

  Future<void> _onYearChanged(
    PayrollListYearChanged event,
    Emitter<PayrollListState> emit,
  ) async {
    if (state.selectedYear == event.year) return;

    emit(state.copyWith(
      selectedYear: event.year,
      status: PayrollListStatus.loading,
      isMyLoading: true,
    ));

    try {
      final myResponse = await _repository.getMyPayslips(
        page: 1,
        size: 10,
        year: event.year,
        month: state.selectedMonth,
      );
      emit(state.copyWith(
        status: PayrollListStatus.success,
        isMyLoading: false,
        mySlips: myResponse.data,
        latestSlip: myResponse.data.isNotEmpty ? myResponse.data.first : null,
        myPage: 1,
        myHasMore: myResponse.meta.page < myResponse.meta.totalPages,
        clearErrorMessage: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isMyLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isMyLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFilterApplied(
    PayrollListFilterApplied event,
    Emitter<PayrollListState> emit,
  ) async {
    final targetYear = event.year ?? state.selectedYear;
    emit(state.copyWith(
      status: PayrollListStatus.loading,
      isMyLoading: state.activeTab == 0,
      isEmployeesLoading: state.activeTab == 1,
      selectedYear: targetYear,
      selectedMonth: event.month,
      clearSelectedMonth: event.month == null,
      selectedStatus: event.status,
      clearSelectedStatus: event.status == null,
      selectedCompanyId: event.companyId,
      clearSelectedCompanyId: event.companyId == null,
      selectedDepartmentId: event.departmentId,
      clearSelectedDepartmentId: event.departmentId == null,
    ));

    try {
      if (state.activeTab == 0) {
        final myResponse = await _repository.getMyPayslips(
          page: 1,
          size: 10,
          year: targetYear,
          month: event.month,
        );
        emit(state.copyWith(
          status: PayrollListStatus.success,
          isMyLoading: false,
          mySlips: myResponse.data,
          latestSlip: myResponse.data.isNotEmpty ? myResponse.data.first : null,
          myPage: 1,
          myHasMore: myResponse.meta.page < myResponse.meta.totalPages,
          clearErrorMessage: true,
        ));
      } else {
        await _fetchEmployees(
          emit,
          page: 1,
          companyId: event.companyId,
          departmentId: event.departmentId,
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isMyLoading: false,
        isEmployeesLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isMyLoading: false,
        isEmployeesLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSearchChanged(
    PayrollListSearchChanged event,
    Emitter<PayrollListState> emit,
  ) async {
    final query = event.query.trim();
    if (state.searchQuery == query) return;

    emit(state.copyWith(
      searchQuery: query,
      isEmployeesLoading: true,
    ));

    if (state.activeTab == 1) {
      await _fetchEmployees(emit, page: 1, search: query);
    }
  }

  void _onPrivacyToggled(
    PayrollListPrivacyToggled event,
    Emitter<PayrollListState> emit,
  ) {
    emit(state.copyWith(isPrivacyMasked: !state.isPrivacyMasked));
  }

  Future<void> _onRefreshed(
    PayrollListRefreshed event,
    Emitter<PayrollListState> emit,
  ) async {
    try {
      if (state.activeTab == 0) {
        final myResponse = await _repository.getMyPayslips(
          page: 1,
          size: 10,
          year: state.selectedYear,
          month: state.selectedMonth,
        );
        emit(state.copyWith(
          mySlips: myResponse.data,
          latestSlip: myResponse.data.isNotEmpty ? myResponse.data.first : null,
          myPage: 1,
          myHasMore: myResponse.meta.page < myResponse.meta.totalPages,
          clearErrorMessage: true,
        ));
      } else {
        final empResponse = await _repository.getPayrollEmployees(
          page: 1,
          size: 20,
          companyId: state.selectedCompanyId,
          departmentId: state.selectedDepartmentId,
          search: state.searchQuery,
        );
        emit(state.copyWith(
          employees: empResponse.data,
          employeesPage: 1,
          employeesHasMore: empResponse.meta.page < empResponse.meta.totalPages,
          clearErrorMessage: true,
        ));
      }
    } catch (_) {}
  }

  Future<void> _onLoadMore(
    PayrollListLoadMore event,
    Emitter<PayrollListState> emit,
  ) async {
    if (state.status == PayrollListStatus.loadingMore ||
        state.isMyLoadingMore ||
        state.isEmployeesLoadingMore) {
      return;
    }

    if (state.activeTab == 0) {
      if (!state.myHasMore) return;

      emit(state.copyWith(isMyLoadingMore: true));
      try {
        final nextPage = state.myPage + 1;
        final response = await _repository.getMyPayslips(
          page: nextPage,
          size: 10,
          year: state.selectedYear,
          month: state.selectedMonth,
        );

        emit(state.copyWith(
          isMyLoadingMore: false,
          mySlips: [...state.mySlips, ...response.data],
          myPage: nextPage,
          myHasMore: response.meta.page < response.meta.totalPages,
          clearErrorMessage: true,
        ));
      } catch (e) {
        emit(state.copyWith(isMyLoadingMore: false));
      }
    } else {
      if (!state.employeesHasMore) return;

      emit(state.copyWith(isEmployeesLoadingMore: true));
      try {
        final nextPage = state.employeesPage + 1;
        final response = await _repository.getPayrollEmployees(
          page: nextPage,
          size: 20,
          companyId: state.selectedCompanyId,
          departmentId: state.selectedDepartmentId,
          search: state.searchQuery,
        );

        emit(state.copyWith(
          isEmployeesLoadingMore: false,
          employees: [...state.employees, ...response.data],
          employeesPage: nextPage,
          employeesHasMore: response.meta.page < response.meta.totalPages,
          clearErrorMessage: true,
        ));
      } catch (e) {
        emit(state.copyWith(isEmployeesLoadingMore: false));
      }
    }
  }

  Future<void> _fetchEmployees(
    Emitter<PayrollListState> emit, {
    required int page,
    String? companyId,
    String? departmentId,
    String? search,
  }) async {
    try {
      final response = await _repository.getPayrollEmployees(
        page: page,
        size: 20,
        companyId: companyId ?? state.selectedCompanyId,
        departmentId: departmentId ?? state.selectedDepartmentId,
        search: search ?? state.searchQuery,
      );

      emit(state.copyWith(
        status: PayrollListStatus.success,
        isEmployeesLoading: false,
        employees: response.data,
        employeesPage: response.meta.page,
        employeesHasMore: response.meta.page < response.meta.totalPages,
        clearErrorMessage: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isEmployeesLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PayrollListStatus.failure,
        isEmployeesLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
