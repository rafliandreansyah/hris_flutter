import 'package:equatable/equatable.dart';

/// Model respons API dari endpoint Schedule Attendance (`POST /attendances/requests/schedule`).
class ScheduleAttendanceResponse extends Equatable {
  final bool success;
  final String message;
  final ScheduleAttendanceData? data;

  const ScheduleAttendanceResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ScheduleAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleAttendanceResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? ScheduleAttendanceData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, message, data];
}

class ScheduleAttendanceData extends Equatable {
  final String id;
  final String? type;
  final String? attendanceType;
  final String? attendanceTime;
  final String? attendanceInTime;
  final String? attendanceOutTime;
  final String? status;

  const ScheduleAttendanceData({
    required this.id,
    this.type,
    this.attendanceType,
    this.attendanceTime,
    this.attendanceInTime,
    this.attendanceOutTime,
    this.status,
  });

  factory ScheduleAttendanceData.fromJson(Map<String, dynamic> json) {
    return ScheduleAttendanceData(
      id: json['id'] as String? ?? '',
      type: json['type'] as String?,
      attendanceType: json['attendanceType'] as String?,
      attendanceTime: json['attendanceTime'] as String?,
      attendanceInTime: json['attendanceInTime'] as String?,
      attendanceOutTime: json['attendanceOutTime'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (type != null) 'type': type,
      if (attendanceType != null) 'attendanceType': attendanceType,
      if (attendanceTime != null) 'attendanceTime': attendanceTime,
      if (attendanceInTime != null) 'attendanceInTime': attendanceInTime,
      if (attendanceOutTime != null) 'attendanceOutTime': attendanceOutTime,
      if (status != null) 'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        attendanceType,
        attendanceTime,
        attendanceInTime,
        attendanceOutTime,
        status,
      ];
}

