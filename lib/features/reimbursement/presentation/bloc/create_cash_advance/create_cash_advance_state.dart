import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';

class CreateCashAdvanceState extends Equatable {
  final EmployeeDetailData? employeeDetail;
  final bool isEmployeeLoading;
  final bool isSubmitting;
  final bool isSuccess;
  final String? createdAdvanceNumber;
  final String? errorMessage;

  const CreateCashAdvanceState({
    this.employeeDetail,
    this.isEmployeeLoading = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.createdAdvanceNumber,
    this.errorMessage,
  });

  CreateCashAdvanceState copyWith({
    EmployeeDetailData? employeeDetail,
    bool? isEmployeeLoading,
    bool? isSubmitting,
    bool? isSuccess,
    String? createdAdvanceNumber,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CreateCashAdvanceState(
      employeeDetail: employeeDetail ?? this.employeeDetail,
      isEmployeeLoading: isEmployeeLoading ?? this.isEmployeeLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      createdAdvanceNumber: createdAdvanceNumber ?? this.createdAdvanceNumber,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        employeeDetail,
        isEmployeeLoading,
        isSubmitting,
        isSuccess,
        createdAdvanceNumber,
        errorMessage,
      ];
}
