import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';

enum CreateLeaveStatus {
  initial,
  loadingTypes,
  typesLoaded,
  submitting,
  success,
  failure,
}

class CreateLeaveState extends Equatable {
  final CreateLeaveStatus status;
  final List<LeaveTypeOptionModel> leaveTypes;
  final LeaveTypeOptionModel? selectedType;
  final String? createdId;
  final String successMessage;
  final String errorMessage;
  final int? statusCode;

  const CreateLeaveState({
    this.status = CreateLeaveStatus.initial,
    this.leaveTypes = const [],
    this.selectedType,
    this.createdId,
    this.successMessage = '',
    this.errorMessage = '',
    this.statusCode,
  });

  bool get isLoadingTypes => status == CreateLeaveStatus.loadingTypes;
  bool get isSubmitting => status == CreateLeaveStatus.submitting;
  bool get isSuccess => status == CreateLeaveStatus.success;
  bool get isFailure => status == CreateLeaveStatus.failure;

  CreateLeaveState copyWith({
    CreateLeaveStatus? status,
    List<LeaveTypeOptionModel>? leaveTypes,
    LeaveTypeOptionModel? selectedType,
    bool clearSelectedType = false,
    String? createdId,
    String? successMessage,
    String? errorMessage,
    int? statusCode,
  }) {
    return CreateLeaveState(
      status: status ?? this.status,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      selectedType:
          clearSelectedType ? null : (selectedType ?? this.selectedType),
      createdId: createdId ?? this.createdId,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCode: statusCode ?? this.statusCode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        leaveTypes,
        selectedType,
        createdId,
        successMessage,
        errorMessage,
        statusCode,
      ];
}
