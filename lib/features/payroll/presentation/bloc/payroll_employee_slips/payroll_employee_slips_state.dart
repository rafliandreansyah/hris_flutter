import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';

enum PayrollEmployeeSlipsStatus {
  initial,
  loading,
  success,
  failure,
  loadingMore,
}

class PayrollEmployeeSlipsState extends Equatable {
  final PayrollEmployeeSlipsStatus status;
  final String employeeId;
  final List<PayrollSlipModel> slips;
  final int selectedYear;
  final int? selectedMonth;
  final String? selectedStatus;
  final String searchQuery;
  final bool isPrivacyMasked;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  const PayrollEmployeeSlipsState({
    this.status = PayrollEmployeeSlipsStatus.initial,
    this.employeeId = '',
    this.slips = const [],
    required this.selectedYear,
    this.selectedMonth,
    this.selectedStatus,
    this.searchQuery = '',
    this.isPrivacyMasked = true,
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  PayrollEmployeeSlipsState copyWith({
    PayrollEmployeeSlipsStatus? status,
    String? employeeId,
    List<PayrollSlipModel>? slips,
    int? selectedYear,
    int? selectedMonth,
    bool clearSelectedMonth = false,
    String? selectedStatus,
    bool clearSelectedStatus = false,
    String? searchQuery,
    bool? isPrivacyMasked,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PayrollEmployeeSlipsState(
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      slips: slips ?? this.slips,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: clearSelectedMonth ? null : (selectedMonth ?? this.selectedMonth),
      selectedStatus: clearSelectedStatus ? null : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      isPrivacyMasked: isPrivacyMasked ?? this.isPrivacyMasked,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        employeeId,
        slips,
        selectedYear,
        selectedMonth,
        selectedStatus,
        searchQuery,
        isPrivacyMasked,
        page,
        hasMore,
        isLoadingMore,
        errorMessage,
      ];
}
