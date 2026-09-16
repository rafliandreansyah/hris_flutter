import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

enum EmployeeDetailStatus { initial, loading, success, failure }

class EmployeeDetailState extends Equatable {
  final EmployeeDetailStatus status;
  final EmployeeDetailData? detail;
  final String? employeeId;
  final EmployeeDirectoryItem? employee;
  final List<EmployeeDirectoryItem>? coworkers;
  final String? errorMessage;

  const EmployeeDetailState({
    this.status = EmployeeDetailStatus.initial,
    this.detail,
    this.employeeId,
    this.employee,
    this.coworkers,
    this.errorMessage,
  });

  bool get isLoading => status == EmployeeDetailStatus.loading;

  EmployeeDetailState copyWith({
    EmployeeDetailStatus? status,
    EmployeeDetailData? detail,
    String? employeeId,
    EmployeeDirectoryItem? employee,
    List<EmployeeDirectoryItem>? coworkers,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeeDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      employeeId: employeeId ?? this.employeeId,
      employee: employee ?? this.employee,
      coworkers: coworkers ?? this.coworkers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        detail,
        employeeId,
        employee,
        coworkers,
        errorMessage,
      ];
}
