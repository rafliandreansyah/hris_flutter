import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:image_picker/image_picker.dart';

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

/// GPS gagal didapat (izin ditolak, layanan GPS mati, atau timeout).
class AttendanceGpsIssueReported extends AttendanceEvent {
  final AttendanceGpsIssue issue;

  const AttendanceGpsIssueReported(this.issue);

  @override
  List<Object?> get props => [issue];
}

/// Event untuk memilih/mengganti lokasi kerja yang digunakan.
class AttendanceWorkLocationChanged extends AttendanceEvent {
  final WorkLocationItem selectedLocation;

  /// Jika `true`, lokasi ini juga akan dikirim ke API sebagai default.
  final bool setAsDefault;

  const AttendanceWorkLocationChanged(
    this.selectedLocation, {
    this.setAsDefault = false,
  });

  @override
  List<Object?> get props => [selectedLocation, setAsDefault];
}

class AttendanceClockInSubmitted extends AttendanceEvent {
  final double latitude;
  final double longitude;
  final String? address;
  final String? note;
  final String attendanceMethod;
  final String? workLocationId;
  final XFile? photoFile;

  const AttendanceClockInSubmitted({
    required this.latitude,
    required this.longitude,
    this.address,
    this.note,
    this.attendanceMethod = 'photo',
    this.workLocationId,
    this.photoFile,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    address,
    note,
    attendanceMethod,
    workLocationId,
    photoFile,
  ];
}

class AttendanceClockOutSubmitted extends AttendanceEvent {
  final double latitude;
  final double longitude;
  final String? address;
  final String? note;
  final String attendanceMethod;
  final String? workLocationId;
  final XFile? photoFile;

  const AttendanceClockOutSubmitted({
    required this.latitude,
    required this.longitude,
    this.address,
    this.note,
    this.attendanceMethod = 'photo',
    this.workLocationId,
    this.photoFile,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    address,
    note,
    attendanceMethod,
    workLocationId,
    photoFile,
  ];
}

/// Memulai istirahat (`POST /attendances/break/start`) memakai lokasi GPS terakhir.
class AttendanceBreakStarted extends AttendanceEvent {
  final String? note;

  const AttendanceBreakStarted({this.note});

  @override
  List<Object?> get props => [note];
}

/// Mengakhiri istirahat yang sedang berjalan (`POST /attendances/break/end`).
class AttendanceBreakEnded extends AttendanceEvent {
  final String? note;

  const AttendanceBreakEnded({this.note});

  @override
  List<Object?> get props => [note];
}
