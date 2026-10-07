import 'package:equatable/equatable.dart';

/// Item jejak rute GPS dari respons GET /tracking/logs
class TrackingLogItem extends Equatable {
  final String id;
  final String employeeId;
  final String sourceType;
  final String? attendanceId;
  final String? activityId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final int? batteryLevel;
  final bool isMock;
  final DateTime recordedAt;
  final DateTime? createdAt;

  const TrackingLogItem({
    required this.id,
    required this.employeeId,
    required this.sourceType,
    this.attendanceId,
    this.activityId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.batteryLevel,
    this.isMock = false,
    required this.recordedAt,
    this.createdAt,
  });

  factory TrackingLogItem.fromJson(Map<String, dynamic> json) {
    return TrackingLogItem(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      attendanceId: json['attendanceId']?.toString(),
      activityId: json['activityId']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      batteryLevel: (json['batteryLevel'] as num?)?.toInt(),
      isMock: json['isMock'] == true,
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'sourceType': sourceType,
      'attendanceId': attendanceId,
      'activityId': activityId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'batteryLevel': batteryLevel,
      'isMock': isMock,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        sourceType,
        attendanceId,
        activityId,
        latitude,
        longitude,
        accuracy,
        speed,
        heading,
        altitude,
        batteryLevel,
        isMock,
        recordedAt,
        createdAt,
      ];
}
