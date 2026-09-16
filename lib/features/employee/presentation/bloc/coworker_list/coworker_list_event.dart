import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

abstract class CoworkerListEvent extends Equatable {
  const CoworkerListEvent();

  @override
  List<Object?> get props => [];
}

class CoworkerListStarted extends CoworkerListEvent {
  final List<EmployeeDirectoryItem>? initialCoworkers;

  const CoworkerListStarted({this.initialCoworkers});

  @override
  List<Object?> get props => [initialCoworkers];
}

class CoworkerListSearchChanged extends CoworkerListEvent {
  final String query;

  const CoworkerListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class CoworkerListRefreshed extends CoworkerListEvent {
  const CoworkerListRefreshed();
}
