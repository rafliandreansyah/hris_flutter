import 'package:equatable/equatable.dart';

/// Data payload respons dari pembuatan Live Attendance.
class LiveAttendanceData extends Equatable {
  final String id;
  final String? type;
  final String? attendanceType;
  final String? attendanceTime;
  final String? attendanceInTime;
  final String? attendanceOutTime;

  const LiveAttendanceData({
    required this.id,
    this.type,
    this.attendanceType,
    this.attendanceTime,
    this.attendanceInTime,
    this.attendanceOutTime,
  });

  factory LiveAttendanceData.fromJson(Map<String, dynamic> json) {
    return LiveAttendanceData(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String?,
      attendanceType: json['attendanceType'] as String?,
      attendanceTime: json['attendanceTime'] as String?,
      attendanceInTime: json['attendanceInTime'] as String?,
      attendanceOutTime: json['attendanceOutTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (type != null) 'type': type,
        if (attendanceType != null) 'attendanceType': attendanceType,
        if (attendanceTime != null) 'attendanceTime': attendanceTime,
        if (attendanceInTime != null) 'attendanceInTime': attendanceInTime,
        if (attendanceOutTime != null) 'attendanceOutTime': attendanceOutTime,
      };

  @override
  List<Object?> get props => [
        id,
        type,
        attendanceType,
        attendanceTime,
        attendanceInTime,
        attendanceOutTime,
      ];
}

/// Pembungkus respons API dari endpoint `POST /attendances/requests/live`.
class LiveAttendanceResponse extends Equatable {
  final bool success;
  final String message;
  final LiveAttendanceData? data;

  const LiveAttendanceResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LiveAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return LiveAttendanceResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? LiveAttendanceData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };

  @override
  List<Object?> get props => [success, message, data];
}
