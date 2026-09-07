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

  const EmployeeListStarted({this.customEmployees});

  @override
  List<Object?> get props => [customEmployees];
}

class EmployeeListRefreshed extends EmployeeListEvent {
  const EmployeeListRefreshed();
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
