import 'package:equatable/equatable.dart';

class NotificationSettingsModel extends Equatable {
  final String id;
  final String employeeId;
  final bool pushAttendanceRequest;
  final bool pushLeave;
  final bool pushOvertime;
  final bool pushPayroll;
  final bool pushAnnouncement;
  final bool pushWarningLetter;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NotificationSettingsModel({
    this.id = '',
    this.employeeId = '',
    this.pushAttendanceRequest = true,
    this.pushLeave = true,
    this.pushOvertime = true,
    this.pushPayroll = true,
    this.pushAnnouncement = true,
    this.pushWarningLetter = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAllEnabled =>
      pushAttendanceRequest &&
      pushLeave &&
      pushOvertime &&
      pushPayroll &&
      pushAnnouncement &&
      pushWarningLetter;

  NotificationSettingsModel copyWith({
    String? id,
    String? employeeId,
    bool? pushAttendanceRequest,
    bool? pushLeave,
    bool? pushOvertime,
    bool? pushPayroll,
    bool? pushAnnouncement,
    bool? pushWarningLetter,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      pushAttendanceRequest:
          pushAttendanceRequest ?? this.pushAttendanceRequest,
      pushLeave: pushLeave ?? this.pushLeave,
      pushOvertime: pushOvertime ?? this.pushOvertime,
      pushPayroll: pushPayroll ?? this.pushPayroll,
      pushAnnouncement: pushAnnouncement ?? this.pushAnnouncement,
      pushWarningLetter: pushWarningLetter ?? this.pushWarningLetter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  NotificationSettingsModel toggleAll(bool value) {
    return copyWith(
      pushAttendanceRequest: value,
      pushLeave: value,
      pushOvertime: value,
      pushPayroll: value,
      pushAnnouncement: value,
      pushWarningLetter: value,
    );
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return NotificationSettingsModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      pushAttendanceRequest: json['pushAttendanceRequest'] as bool? ?? true,
      pushLeave: json['pushLeave'] as bool? ?? true,
      pushOvertime: json['pushOvertime'] as bool? ?? true,
      pushPayroll: json['pushPayroll'] as bool? ?? true,
      pushAnnouncement: json['pushAnnouncement'] as bool? ?? true,
      pushWarningLetter: json['pushWarningLetter'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'pushAttendanceRequest': pushAttendanceRequest,
      'pushLeave': pushLeave,
      'pushOvertime': pushOvertime,
      'pushPayroll': pushPayroll,
      'pushAnnouncement': pushAnnouncement,
      'pushWarningLetter': pushWarningLetter,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'pushAttendanceRequest': pushAttendanceRequest,
      'pushLeave': pushLeave,
      'pushOvertime': pushOvertime,
      'pushPayroll': pushPayroll,
      'pushAnnouncement': pushAnnouncement,
      'pushWarningLetter': pushWarningLetter,
    };
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        pushAttendanceRequest,
        pushLeave,
        pushOvertime,
        pushPayroll,
        pushAnnouncement,
        pushWarningLetter,
        createdAt,
        updatedAt,
      ];
}

class NotificationSettingsResponse extends Equatable {
  final bool success;
  final String? message;
  final NotificationSettingsModel? data;

  const NotificationSettingsResponse({
    this.success = false,
    this.message,
    this.data,
  });

  factory NotificationSettingsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? NotificationSettingsModel.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, message, data];
}
