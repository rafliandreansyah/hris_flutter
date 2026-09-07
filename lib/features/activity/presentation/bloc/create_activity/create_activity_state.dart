import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';

enum CreateActivityStatus {
  initial,
  loadingTypes,
  typesLoaded,
  submitting,
  success,
  failure,
}

class CreateActivityState extends Equatable {
  final CreateActivityStatus status;
  final List<ActivityTypeModel> activityTypes;
  final ActivityItem? createdActivity;
  final String errorMessage;

  const CreateActivityState({
    this.status = CreateActivityStatus.initial,
    this.activityTypes = const [],
    this.createdActivity,
    this.errorMessage = '',
  });

  bool get isLoadingTypes =>
      status == CreateActivityStatus.loadingTypes;

  bool get isSubmitting =>
      status == CreateActivityStatus.submitting;

  CreateActivityState copyWith({
    CreateActivityStatus? status,
    List<ActivityTypeModel>? activityTypes,
    ActivityItem? createdActivity,
    String? errorMessage,
  }) {
    return CreateActivityState(
      status: status ?? this.status,
      activityTypes: activityTypes ?? this.activityTypes,
      createdActivity: createdActivity ?? this.createdActivity,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activityTypes,
        createdActivity,
        errorMessage,
      ];
}
