import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';

enum PayrollListStatus {
  initial,
  loading,
  success,
  failure,
  loadingMore,
}

class PayrollListState extends Equatable {
  final PayrollListStatus status;
  final List<PayrollSlipModel> mySlips;
  final List<PayrollEmployeeItemModel> employees;
  final List<PayrollPeriodModel> periods;
  final PayrollSlipModel? latestSlip;
  final int activeTab; // 0: Slip Saya, 1: Semua Pegawai
  final int selectedYear;
  final int? selectedMonth;
  final String? selectedStatus;
  final String? selectedCompanyId;
  final String? selectedDepartmentId;
  final String searchQuery;
  final bool isPrivacyMasked;
  final bool canViewTeam;
  final int myPage;
  final bool myHasMore;
  final int employeesPage;
  final bool employeesHasMore;
  final bool isMyLoading;
  final bool isEmployeesLoading;
  final bool isMyLoadingMore;
  final bool isEmployeesLoadingMore;
  final String? errorMessage;

  const PayrollListState({
    this.status = PayrollListStatus.initial,
    this.mySlips = const [],
    this.employees = const [],
    this.periods = const [],
    this.latestSlip,
    this.activeTab = 0,
    required this.selectedYear,
    this.selectedMonth,
    this.selectedStatus,
    this.selectedCompanyId,
    this.selectedDepartmentId,
    this.searchQuery = '',
    this.isPrivacyMasked = true,
    this.canViewTeam = false,
    this.myPage = 1,
    this.myHasMore = true,
    this.employeesPage = 1,
    this.employeesHasMore = true,
    this.isMyLoading = false,
    this.isEmployeesLoading = false,
    this.isMyLoadingMore = false,
    this.isEmployeesLoadingMore = false,
    this.errorMessage,
  });

  PayrollListState copyWith({
    PayrollListStatus? status,
    List<PayrollSlipModel>? mySlips,
    List<PayrollEmployeeItemModel>? employees,
    List<PayrollPeriodModel>? periods,
    PayrollSlipModel? latestSlip,
    bool clearLatestSlip = false,
    int? activeTab,
    int? selectedYear,
    int? selectedMonth,
    bool clearSelectedMonth = false,
    String? selectedStatus,
    bool clearSelectedStatus = false,
    String? selectedCompanyId,
    bool clearSelectedCompanyId = false,
    String? selectedDepartmentId,
    bool clearSelectedDepartmentId = false,
    String? searchQuery,
    bool? isPrivacyMasked,
    bool? canViewTeam,
    int? myPage,
    bool? myHasMore,
    int? employeesPage,
    bool? employeesHasMore,
    bool? isMyLoading,
    bool? isEmployeesLoading,
    bool? isMyLoadingMore,
    bool? isEmployeesLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PayrollListState(
      status: status ?? this.status,
      mySlips: mySlips ?? this.mySlips,
      employees: employees ?? this.employees,
      periods: periods ?? this.periods,
      latestSlip: clearLatestSlip ? null : (latestSlip ?? this.latestSlip),
      activeTab: activeTab ?? this.activeTab,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: clearSelectedMonth ? null : (selectedMonth ?? this.selectedMonth),
      selectedStatus: clearSelectedStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedCompanyId: clearSelectedCompanyId
          ? null
          : (selectedCompanyId ?? this.selectedCompanyId),
      selectedDepartmentId: clearSelectedDepartmentId
          ? null
          : (selectedDepartmentId ?? this.selectedDepartmentId),
      searchQuery: searchQuery ?? this.searchQuery,
      isPrivacyMasked: isPrivacyMasked ?? this.isPrivacyMasked,
      canViewTeam: canViewTeam ?? this.canViewTeam,
      myPage: myPage ?? this.myPage,
      myHasMore: myHasMore ?? this.myHasMore,
      employeesPage: employeesPage ?? this.employeesPage,
      employeesHasMore: employeesHasMore ?? this.employeesHasMore,
      isMyLoading: isMyLoading ?? this.isMyLoading,
      isEmployeesLoading: isEmployeesLoading ?? this.isEmployeesLoading,
      isMyLoadingMore: isMyLoadingMore ?? this.isMyLoadingMore,
      isEmployeesLoadingMore: isEmployeesLoadingMore ?? this.isEmployeesLoadingMore,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        mySlips,
        employees,
        periods,
        latestSlip,
        activeTab,
        selectedYear,
        selectedMonth,
        selectedStatus,
        selectedCompanyId,
        selectedDepartmentId,
        searchQuery,
        isPrivacyMasked,
        canViewTeam,
        myPage,
        myHasMore,
        employeesPage,
        employeesHasMore,
        isMyLoading,
        isEmployeesLoading,
        isMyLoadingMore,
        isEmployeesLoadingMore,
        errorMessage,
      ];
}
