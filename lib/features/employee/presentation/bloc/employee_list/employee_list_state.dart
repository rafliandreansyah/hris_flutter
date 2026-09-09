import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';

enum EmployeeListStatus { initial, loading, success, failure }

class EmployeeListState extends Equatable {
  final EmployeeListStatus status;
  final List<EmployeeDirectoryItem> employees;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final EmployeeFilterCriteria filterCriteria;
  final List<EmployeeDirectoryItem>? customEmployees;
  final String? errorMessage;
  final int? statusCode;
  final bool isTeamAttendance;

  const EmployeeListState({
    this.status = EmployeeListStatus.initial,
    this.employees = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.pageSize = 30,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filterCriteria = const EmployeeFilterCriteria(),
    this.customEmployees,
    this.errorMessage,
    this.statusCode,
    this.isTeamAttendance = false,
  });

  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  EmployeeListState copyWith({
    EmployeeListStatus? status,
    List<EmployeeDirectoryItem>? employees,
    int? currentPage,
    int? totalPages,
    int? pageSize,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    EmployeeFilterCriteria? filterCriteria,
    List<EmployeeDirectoryItem>? customEmployees,
    String? errorMessage,
    int? statusCode,
    bool? isTeamAttendance,
    bool clearError = false,
  }) {
    return EmployeeListState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      pageSize: pageSize ?? this.pageSize,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      customEmployees: customEmployees ?? this.customEmployees,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusCode: clearError ? null : (statusCode ?? this.statusCode),
      isTeamAttendance: isTeamAttendance ?? this.isTeamAttendance,
    );
  }

  @override
  List<Object?> get props => [
        status,
        employees,
        currentPage,
        totalPages,
        pageSize,
        isLoading,
        isLoadingMore,
        searchQuery,
        filterCriteria,
        customEmployees,
        errorMessage,
        statusCode,
        isTeamAttendance,
      ];
}
