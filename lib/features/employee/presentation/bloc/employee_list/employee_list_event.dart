import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';

abstract class EmployeeListEvent extends Equatable {
  const EmployeeListEvent();

  @override
  List<Object?> get props => [];
}

class EmployeeListStarted extends EmployeeListEvent {
  final List<EmployeeDirectoryItem>? customEmployees;
  final bool? isTeamAttendance;

  const EmployeeListStarted({
    this.customEmployees,
    this.isTeamAttendance,
  });

  @override
  List<Object?> get props => [customEmployees, isTeamAttendance];
}

class EmployeeListRefreshed extends EmployeeListEvent {
  final bool? isTeamAttendance;

  const EmployeeListRefreshed({this.isTeamAttendance});

  @override
  List<Object?> get props => [isTeamAttendance];
}

class EmployeeListLoadMore extends EmployeeListEvent {
  const EmployeeListLoadMore();
}

class EmployeeListSearchChanged extends EmployeeListEvent {
  final String query;

  const EmployeeListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class EmployeeListFilterApplied extends EmployeeListEvent {
  final EmployeeFilterCriteria criteria;

  const EmployeeListFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}
