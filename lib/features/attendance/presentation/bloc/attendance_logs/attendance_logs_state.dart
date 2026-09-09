import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_filter_bottom_sheet.dart';

enum AttendanceLogsStatus { initial, loading, success, failure }

class AttendanceLogsState extends Equatable {
  final AttendanceLogsStatus status;
  final List<AttendanceLogItem> logs;
  final AttendanceLogSummary? summary;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final bool isLoadingMore;
  final AttendanceLogFilterCriteria filterCriteria;
  final String? errorMessage;
  final int? statusCode;
  final String? employeeId;
  final bool lastMonth;

  const AttendanceLogsState({
    this.status = AttendanceLogsStatus.initial,
    this.logs = const [],
    this.summary,
    this.currentPage = 1,
    this.totalPages = 1,
    this.pageSize = 20,
    this.isLoadingMore = false,
    this.filterCriteria = const AttendanceLogFilterCriteria(),
    this.errorMessage,
    this.statusCode,
    this.employeeId,
    this.lastMonth = false,
  });

  bool get isNotFound => statusCode == 404;
  bool get isForbidden => statusCode == 403;

  bool get hasMorePages => currentPage < totalPages;

  AttendanceLogsState copyWith({
    AttendanceLogsStatus? status,
    List<AttendanceLogItem>? logs,
    AttendanceLogSummary? summary,
    int? currentPage,
    int? totalPages,
    int? pageSize,
    bool? isLoadingMore,
    AttendanceLogFilterCriteria? filterCriteria,
    String? errorMessage,
    int? statusCode,
    String? employeeId,
    bool? lastMonth,
    bool clearError = false,
    bool clearSummary = false,
  }) {
    return AttendanceLogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      summary: clearSummary ? null : (summary ?? this.summary),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusCode: clearError ? null : (statusCode ?? this.statusCode),
      employeeId: employeeId ?? this.employeeId,
      lastMonth: lastMonth ?? this.lastMonth,
    );
  }

  @override
  List<Object?> get props => [
    status,
    logs,
    summary,
    currentPage,
    totalPages,
    pageSize,
    isLoadingMore,
    filterCriteria,
    errorMessage,
    statusCode,
    employeeId,
    lastMonth,
  ];
}
