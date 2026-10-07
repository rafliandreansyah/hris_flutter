import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';

enum LiveTrackingStatus { initial, loading, loaded, failure }

class LiveTrackingState extends Equatable {
  final LiveTrackingStatus status;
  final LiveTrackingResponse? data;
  final LiveEmployeeLocation? selectedEmployee;
  final List<TrackingLogItem> selectedRouteLogs;
  final bool isLoadingRoute;
  final String? routeErrorMessage;
  final String? selectedCompanyId;
  final String? selectedDepartmentId;
  final String selectedStatus; // 'all' | 'attendance' | 'activity'
  final bool activeOnly;
  final String searchQuery;
  final String? errorMessage;
  final DateTime lastRefreshed;

  const LiveTrackingState({
    this.status = LiveTrackingStatus.initial,
    this.data,
    this.selectedEmployee,
    this.selectedRouteLogs = const [],
    this.isLoadingRoute = false,
    this.routeErrorMessage,
    this.selectedCompanyId,
    this.selectedDepartmentId,
    this.selectedStatus = 'all',
    this.activeOnly = true,
    this.searchQuery = '',
    this.errorMessage,
    required this.lastRefreshed,
  });

  /// Daftar karyawan yang telah difilter berdasarkan teks pencarian (nama / NIK)
  List<LiveEmployeeLocation> get filteredEmployees {
    final list = data?.employees ?? [];
    if (searchQuery.trim().isEmpty) return list;

    final q = searchQuery.toLowerCase().trim();
    return list.where((emp) {
      final nameMatch = emp.name.toLowerCase().contains(q);
      final numMatch = emp.employeeNumber.toLowerCase().contains(q);
      final deptMatch = emp.departmentName?.toLowerCase().contains(q) ?? false;
      return nameMatch || numMatch || deptMatch;
    }).toList();
  }

  LiveTrackingSummary get summary =>
      data?.summary ?? LiveTrackingSummary.empty();

  LiveTrackingState copyWith({
    LiveTrackingStatus? status,
    LiveTrackingResponse? Function()? data,
    LiveEmployeeLocation? Function()? selectedEmployee,
    List<TrackingLogItem>? selectedRouteLogs,
    bool? isLoadingRoute,
    String? Function()? routeErrorMessage,
    String? Function()? selectedCompanyId,
    String? Function()? selectedDepartmentId,
    String? selectedStatus,
    bool? activeOnly,
    String? searchQuery,
    String? Function()? errorMessage,
    DateTime? lastRefreshed,
  }) {
    return LiveTrackingState(
      status: status ?? this.status,
      data: data != null ? data() : this.data,
      selectedEmployee: selectedEmployee != null
          ? selectedEmployee()
          : this.selectedEmployee,
      selectedRouteLogs: selectedRouteLogs ?? this.selectedRouteLogs,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      routeErrorMessage: routeErrorMessage != null
          ? routeErrorMessage()
          : this.routeErrorMessage,
      selectedCompanyId: selectedCompanyId != null
          ? selectedCompanyId()
          : this.selectedCompanyId,
      selectedDepartmentId: selectedDepartmentId != null
          ? selectedDepartmentId()
          : this.selectedDepartmentId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      activeOnly: activeOnly ?? this.activeOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        selectedEmployee,
        selectedRouteLogs,
        isLoadingRoute,
        routeErrorMessage,
        selectedCompanyId,
        selectedDepartmentId,
        selectedStatus,
        activeOnly,
        searchQuery,
        errorMessage,
        lastRefreshed,
      ];
}
