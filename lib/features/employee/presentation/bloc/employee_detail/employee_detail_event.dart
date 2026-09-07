import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

abstract class EmployeeDetailEvent extends Equatable {
  const EmployeeDetailEvent();

  @override
  List<Object?> get props => [];
}

class EmployeeDetailStarted extends EmployeeDetailEvent {
  final String? employeeId;
  final EmployeeDirectoryItem? employee;

  const EmployeeDetailStarted({
    this.employeeId,
    this.employee,
  });

  @override
  List<Object?> get props => [employeeId, employee];
}

class EmployeeDetailRefreshed extends EmployeeDetailEvent {
  const EmployeeDetailRefreshed();
}
