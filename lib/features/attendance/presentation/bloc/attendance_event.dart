import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceFetchRequested extends AttendanceEvent {
  final bool isRefresh;

  const AttendanceFetchRequested({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class AttendanceClockTicked extends AttendanceEvent {
  final DateTime currentTime;

  const AttendanceClockTicked(this.currentTime);

  @override
  List<Object?> get props => [currentTime];
}

class AttendanceLocationUpdated extends AttendanceEvent {
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isInsideGeofence;

  const AttendanceLocationUpdated({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isInsideGeofence,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, isInsideGeofence];
}

/// Event untuk memilih/mengganti lokasi kerja yang digunakan.
class AttendanceWorkLocationChanged extends AttendanceEvent {
  final WorkLocationItem selectedLocation;

  const AttendanceWorkLocationChanged(this.selectedLocation);

  @override
  List<Object?> get props => [selectedLocation];
}

class AttendanceClockInSubmitted extends AttendanceEvent {
  final double latitude;
  final double longitude;
  final String? address;
  final String? note;

  const AttendanceClockInSubmitted({
    required this.latitude,
    required this.longitude,
    this.address,
    this.note,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, note];
}

class AttendanceClockOutSubmitted extends AttendanceEvent {
  final double latitude;
  final double longitude;
  final String? address;
  final String? note;

  const AttendanceClockOutSubmitted({
    required this.latitude,
    required this.longitude,
    this.address,
    this.note,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, note];
}

class AttendanceBreakToggled extends AttendanceEvent {
  const AttendanceBreakToggled();
}

class AttendanceReportIssueSubmitted extends AttendanceEvent {
  final String issueDescription;
  final double latitude;
  final double longitude;

  const AttendanceReportIssueSubmitted({
    required this.issueDescription,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [issueDescription, latitude, longitude];
}

