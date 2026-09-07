import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';

enum ActivityDetailStatus {
  initial,
  loading,
  loaded,
  submitting,
  actionSuccess,
  failure,
}

class ActivityDetailState extends Equatable {
  final ActivityDetailStatus status;
  final ActivityItem activity;
  final bool isCreator;
  final String? currentEmployeeId;
  final bool hasChanged;
  final String? actionMessage;
  final String? errorMessage;

  const ActivityDetailState({
    this.status = ActivityDetailStatus.initial,
    required this.activity,
    this.isCreator = false,
    this.currentEmployeeId,
    this.hasChanged = false,
    this.actionMessage,
    this.errorMessage,
  });

  ActivityDetailState copyWith({
    ActivityDetailStatus? status,
    ActivityItem? activity,
    bool? isCreator,
    String? currentEmployeeId,
    bool? hasChanged,
    String? actionMessage,
    String? errorMessage,
  }) {
    return ActivityDetailState(
      status: status ?? this.status,
      activity: activity ?? this.activity,
      isCreator: isCreator ?? this.isCreator,
      currentEmployeeId: currentEmployeeId ?? this.currentEmployeeId,
      hasChanged: hasChanged ?? this.hasChanged,
      actionMessage: actionMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activity,
        isCreator,
        currentEmployeeId,
        hasChanged,
        actionMessage,
        errorMessage,
      ];
}
