import 'package:equatable/equatable.dart';

/// Titik koordinat GPS individual yang dicatat oleh sensor perangkat
class TrackingLocationPoint extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final int? batteryLevel;
  final bool isMock;
  final bool isGpsOff;
  final DateTime recordedAt;

  const TrackingLocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.batteryLevel,
    this.isMock = false,
    this.isGpsOff = false,
    required this.recordedAt,
  });

  /// Konversi ke payload JSON untuk API POST /tracking/batch
  Map<String, dynamic> toApiJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        if (altitude != null) 'altitude': altitude,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        'isMock': isMock,
        'isGpsOff': isGpsOff,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };

  /// Serialisasi lengkap untuk penyimpanan antrean lokal
  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'altitude': altitude,
        'batteryLevel': batteryLevel,
        'isMock': isMock,
        'isGpsOff': isGpsOff,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };

  factory TrackingLocationPoint.fromLocalJson(Map<String, dynamic> json) {
    return TrackingLocationPoint(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      batteryLevel: (json['batteryLevel'] as num?)?.toInt(),
      isMock: json['isMock'] == true,
      isGpsOff: json['isGpsOff'] == true,
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        accuracy,
        speed,
        heading,
        altitude,
        batteryLevel,
        isMock,
        isGpsOff,
        recordedAt,
      ];
}

/// Payload pengiriman batch titik koordinat ke POST /tracking/batch
class TrackingBatchPayload extends Equatable {
  final String sourceType; // 'attendance' | 'activity'
  final String referenceId; // attendanceId atau activityId
  final List<TrackingLocationPoint> locations;

  const TrackingBatchPayload({
    required this.sourceType,
    required this.referenceId,
    required this.locations,
  });

  Map<String, dynamic> toJson() => {
        'sourceType': sourceType,
        'referenceId': referenceId,
        'locations': locations.map((loc) => loc.toApiJson()).toList(),
      };

  @override
  List<Object?> get props => [sourceType, referenceId, locations];
}
