import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_filter_bottom_sheet.dart';

abstract class AttendanceLogsEvent extends Equatable {
  const AttendanceLogsEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceLogsStarted extends AttendanceLogsEvent {
  final String? employeeId;
  final bool lastMonth;

  const AttendanceLogsStarted({
    this.employeeId,
    this.lastMonth = false,
  });

  @override
  List<Object?> get props => [employeeId, lastMonth];
}

class AttendanceLogsRefreshed extends AttendanceLogsEvent {
  final String? employeeId;
  final bool? lastMonth;

  const AttendanceLogsRefreshed({
    this.employeeId,
    this.lastMonth,
  });

  @override
  List<Object?> get props => [employeeId, lastMonth];
}

class AttendanceLogsMonthToggled extends AttendanceLogsEvent {
  final bool lastMonth;

  const AttendanceLogsMonthToggled(this.lastMonth);

  @override
  List<Object?> get props => [lastMonth];
}

class AttendanceLogsLoadMore extends AttendanceLogsEvent {
  const AttendanceLogsLoadMore();
}

class AttendanceLogsFilterApplied extends AttendanceLogsEvent {
  final AttendanceLogFilterCriteria criteria;

  const AttendanceLogsFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}
