import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

enum CreatePlanActivityStatus {
  initial,
  loadingData,
  dataLoaded,
  submitting,
  success,
  failure,
}

class CreatePlanActivityState extends Equatable {
  final CreatePlanActivityStatus status;
  final List<ActivityTypeModel> activityTypes;
  final List<EmployeeDirectoryItem> employees;
  final EmployeeDirectoryItem? selectedEmployee;
  final ActivityTypeModel? selectedActivityType;
  final ActivityItem? createdActivity;
  final String errorMessage;

  const CreatePlanActivityState({
    this.status = CreatePlanActivityStatus.initial,
    this.activityTypes = const [],
    this.employees = const [],
    this.selectedEmployee,
    this.selectedActivityType,
    this.createdActivity,
    this.errorMessage = '',
  });

  bool get isLoadingData => status == CreatePlanActivityStatus.loadingData;
  bool get isSubmitting => status == CreatePlanActivityStatus.submitting;

  CreatePlanActivityState copyWith({
    CreatePlanActivityStatus? status,
    List<ActivityTypeModel>? activityTypes,
    List<EmployeeDirectoryItem>? employees,
    EmployeeDirectoryItem? selectedEmployee,
    ActivityTypeModel? selectedActivityType,
    ActivityItem? createdActivity,
    String? errorMessage,
  }) {
    return CreatePlanActivityState(
      status: status ?? this.status,
      activityTypes: activityTypes ?? this.activityTypes,
      employees: employees ?? this.employees,
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      selectedActivityType: selectedActivityType ?? this.selectedActivityType,
      createdActivity: createdActivity ?? this.createdActivity,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activityTypes,
        employees,
        selectedEmployee,
        selectedActivityType,
        createdActivity,
        errorMessage,
      ];
}
