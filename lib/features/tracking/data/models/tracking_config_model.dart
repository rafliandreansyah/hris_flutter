import 'package:equatable/equatable.dart';

/// Kebijakan sesi pelacakan (presensi atau dinas lapangan)
class TrackingSessionPolicy extends Equatable {
  final bool enabled;
  final int intervalMinutes;
  final String? activeSessionId;

  const TrackingSessionPolicy({
    required this.enabled,
    required this.intervalMinutes,
    this.activeSessionId,
  });

  factory TrackingSessionPolicy.fromJson(Map<String, dynamic> json) {
    return TrackingSessionPolicy(
      enabled: json['enabled'] == true,
      intervalMinutes: (json['intervalMinutes'] as num?)?.toInt() ?? 10,
      activeSessionId: (json['activeAttendanceId'] ?? json['activeActivityId'] ?? json['activeSessionId'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'intervalMinutes': intervalMinutes,
      'activeSessionId': activeSessionId,
    };
  }

  @override
  List<Object?> get props => [enabled, intervalMinutes, activeSessionId];
}

/// Model Konfigurasi Pelacakan dari GET /tracking/config
class TrackingConfigModel extends Equatable {
  final bool hasAccess;
  final bool isTrackingEnabled;
  final TrackingSessionPolicy attendance;
  final TrackingSessionPolicy activity;

  const TrackingConfigModel({
    required this.hasAccess,
    required this.isTrackingEnabled,
    required this.attendance,
    required this.activity,
  });

  factory TrackingConfigModel.fromJson(Map<String, dynamic> json) {
    return TrackingConfigModel(
      hasAccess: json['hasAccess'] == true,
      isTrackingEnabled: json['isTrackingEnabled'] == true,
      attendance: TrackingSessionPolicy.fromJson(
        json['attendance'] is Map<String, dynamic>
            ? json['attendance'] as Map<String, dynamic>
            : {},
      ),
      activity: TrackingSessionPolicy.fromJson(
        json['activity'] is Map<String, dynamic>
            ? json['activity'] as Map<String, dynamic>
            : {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasAccess': hasAccess,
      'isTrackingEnabled': isTrackingEnabled,
      'attendance': attendance.toJson(),
      'activity': activity.toJson(),
    };
  }

  @override
  List<Object?> get props => [hasAccess, isTrackingEnabled, attendance, activity];
}
