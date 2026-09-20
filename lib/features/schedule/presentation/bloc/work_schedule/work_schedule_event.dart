import 'package:equatable/equatable.dart';

abstract class WorkScheduleEvent extends Equatable {
  const WorkScheduleEvent();

  @override
  List<Object?> get props => [];
}

class WorkScheduleFetchRequested extends WorkScheduleEvent {
  final String? employeeId;

  const WorkScheduleFetchRequested({this.employeeId});

  @override
  List<Object?> get props => [employeeId];
}

class WorkScheduleDateSelected extends WorkScheduleEvent {
  final DateTime selectedDate;

  const WorkScheduleDateSelected(this.selectedDate);

  @override
  List<Object?> get props => [selectedDate];
}

class WorkScheduleRefreshRequested extends WorkScheduleEvent {
  const WorkScheduleRefreshRequested();
}
