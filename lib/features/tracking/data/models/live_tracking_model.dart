import 'package:equatable/equatable.dart';

/// Ringkasan metrik pemantauan live tracking
class LiveTrackingSummary extends Equatable {
  final int totalTracked;
  final int attendanceCount;
  final int activityCount;
  final int onlineCount;
  final int gpsOffCount;

  const LiveTrackingSummary({
    required this.totalTracked,
    required this.attendanceCount,
    required this.activityCount,
    required this.onlineCount,
    required this.gpsOffCount,
  });

  factory LiveTrackingSummary.fromJson(Map<String, dynamic> json) {
    return LiveTrackingSummary(
      totalTracked: (json['totalTracked'] as num?)?.toInt() ?? 0,
      attendanceCount: (json['attendanceCount'] as num?)?.toInt() ?? 0,
      activityCount: (json['activityCount'] as num?)?.toInt() ?? 0,
      onlineCount: (json['onlineCount'] as num?)?.toInt() ?? 0,
      gpsOffCount: (json['gpsOffCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory LiveTrackingSummary.empty() => const LiveTrackingSummary(
        totalTracked: 0,
        attendanceCount: 0,
        activityCount: 0,
        onlineCount: 0,
        gpsOffCount: 0,
      );

  Map<String, dynamic> toJson() => {
        'totalTracked': totalTracked,
        'attendanceCount': attendanceCount,
        'activityCount': activityCount,
        'onlineCount': onlineCount,
        'gpsOffCount': gpsOffCount,
      };

  @override
  List<Object?> get props => [
        totalTracked,
        attendanceCount,
        activityCount,
        onlineCount,
        gpsOffCount,
      ];
}

/// Sesi aktif karyawan (Presensi harian atau Tugas dinas lapangan)
class LiveTrackingSession extends Equatable {
  final String type; // 'attendance' | 'activity'
  final String id;
  final String? title;
  final DateTime? startTime;
  final String? notes;

  const LiveTrackingSession({
    required this.type,
    required this.id,
    this.title,
    this.startTime,
    this.notes,
  });

  factory LiveTrackingSession.fromJson(Map<String, dynamic> json) {
    return LiveTrackingSession(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString())
          : null,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'title': title,
        'startTime': startTime?.toUtc().toIso8601String(),
        'notes': notes,
      };

  @override
  List<Object?> get props => [type, id, title, startTime, notes];
}

/// Posisi dan status terkini seorang karyawan di peta pemantauan
class LiveEmployeeLocation extends Equatable {
  final String employeeId;
  final String name;
  final String employeeNumber;
  final String? photoUrl;
  final String? companyId;
  final String? companyName;
  final String? departmentName;
  final String? positionName;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final int? batteryLevel;
  final String status; // 'attendance' | 'activity'
  final String? activeRefId;
  final DateTime recordedAt;
  final DateTime? updatedAt;
  final bool isOnline;
  final int minutesSinceLastPing;
  final bool isGpsOff;
  final LiveTrackingSession? session;

  const LiveEmployeeLocation({
    required this.employeeId,
    required this.name,
    required this.employeeNumber,
    this.photoUrl,
    this.companyId,
    this.companyName,
    this.departmentName,
    this.positionName,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.batteryLevel,
    required this.status,
    this.activeRefId,
    required this.recordedAt,
    this.updatedAt,
    required this.isOnline,
    required this.minutesSinceLastPing,
    this.isGpsOff = false,
    this.session,
  });

  factory LiveEmployeeLocation.fromJson(Map<String, dynamic> json) {
    final dept = json['department'];
    final deptName = dept is Map ? dept['name']?.toString() : dept?.toString();
    final pos = json['position'];
    final posName = pos is Map ? pos['name']?.toString() : pos?.toString();

    final minutes = (json['minutesSinceLastPing'] as num?)?.toInt() ?? 0;
    final isOnlineVal = json['isOnline'] == true || (minutes <= 15);

    return LiveEmployeeLocation(
      employeeId: json['employeeId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Karyawan',
      employeeNumber: json['employeeNumber']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      companyId: json['companyId']?.toString(),
      companyName: json['companyName']?.toString(),
      departmentName: deptName,
      positionName: posName,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      batteryLevel: (json['batteryLevel'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'attendance',
      activeRefId: json['activeRefId']?.toString(),
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isOnline: isOnlineVal,
      minutesSinceLastPing: minutes,
      isGpsOff: json['isGpsOff'] == true,
      session: json['session'] is Map<String, dynamic>
          ? LiveTrackingSession.fromJson(json['session'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'name': name,
        'employeeNumber': employeeNumber,
        'photoUrl': photoUrl,
        'companyId': companyId,
        'companyName': companyName,
        'departmentName': departmentName,
        'positionName': positionName,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'batteryLevel': batteryLevel,
        'status': status,
        'activeRefId': activeRefId,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
        'isOnline': isOnline,
        'minutesSinceLastPing': minutesSinceLastPing,
        'isGpsOff': isGpsOff,
        'session': session?.toJson(),
      };

  @override
  List<Object?> get props => [
        employeeId,
        name,
        employeeNumber,
        photoUrl,
        companyId,
        companyName,
        departmentName,
        positionName,
        latitude,
        longitude,
        accuracy,
        batteryLevel,
        status,
        activeRefId,
        recordedAt,
        updatedAt,
        isOnline,
        minutesSinceLastPing,
        isGpsOff,
        session,
      ];
}

/// Respons pembungkus lengkap untuk GET /tracking/live
class LiveTrackingResponse extends Equatable {
  final LiveTrackingSummary summary;
  final List<LiveEmployeeLocation> employees;

  const LiveTrackingResponse({
    required this.summary,
    required this.employees,
  });

  factory LiveTrackingResponse.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : <String, dynamic>{};
    final employeesJson = json['employees'] as List<dynamic>? ?? [];

    return LiveTrackingResponse(
      summary: LiveTrackingSummary.fromJson(summaryJson),
      employees: employeesJson
          .whereType<Map<String, dynamic>>()
          .map((e) => LiveEmployeeLocation.fromJson(e))
          .toList(),
    );
  }

  factory LiveTrackingResponse.empty() => LiveTrackingResponse(
        summary: LiveTrackingSummary.empty(),
        employees: const [],
      );

  @override
  List<Object?> get props => [summary, employees];
}
