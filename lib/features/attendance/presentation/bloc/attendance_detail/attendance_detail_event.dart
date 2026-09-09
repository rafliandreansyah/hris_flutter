import 'package:equatable/equatable.dart';

abstract class AttendanceDetailEvent extends Equatable {
  const AttendanceDetailEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceDetailStarted extends AttendanceDetailEvent {
  final String id;

  const AttendanceDetailStarted(this.id);

  @override
  List<Object?> get props => [id];
}

class AttendanceDetailRefreshed extends AttendanceDetailEvent {
  final String id;

  const AttendanceDetailRefreshed(this.id);

  @override
  List<Object?> get props => [id];
}
