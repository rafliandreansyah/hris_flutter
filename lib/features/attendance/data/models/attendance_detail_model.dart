import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class AttendanceEmployeeInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String? company;
  final String? department;
  final String? position;
  final String? level;

  const AttendanceEmployeeInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.company,
    this.department,
    this.position,
    this.level,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AttendanceEmployeeInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceEmployeeInfo(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      company: json['company'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      level: json['level'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'company': company,
      'department': department,
      'position': position,
      'level': level,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        photoUrl,
        company,
        department,
        position,
        level,
      ];
}

class AttendanceWorkLocationInfo extends Equatable {
  final String id;
  final String name;

  const AttendanceWorkLocationInfo({
    required this.id,
    required this.name,
  });

  factory AttendanceWorkLocationInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceWorkLocationInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

class AttendanceShiftInfo extends Equatable {
  final String id;
  final String name;
  final String? startTime;
  final String? endTime;

  const AttendanceShiftInfo({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
  });

  String get timeRange {
    if (startTime != null && endTime != null) {
      return '$startTime - $endTime';
    }
    return startTime ?? endTime ?? '-';
  }

  factory AttendanceShiftInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceShiftInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  @override
  List<Object?> get props => [id, name, startTime, endTime];
}

class AttendanceDetailModel extends Equatable {
  final String id;
  final String attendanceType;
  final DateTime? attendanceTime;
  final String attendanceMethod;
  final AttendanceEmployeeInfo? employee;
  final double? latitude;
  final double? longitude;
  final AttendanceWorkLocationInfo? workLocation;
  final String? address;
  final String? filePath;
  final String? attendanceRequestId;
  final int lateInMinutes;
  final String? workDate;
  final AttendanceShiftInfo? shift;
  final String? timezone;

  const AttendanceDetailModel({
    required this.id,
    required this.attendanceType,
    this.attendanceTime,
    required this.attendanceMethod,
    this.employee,
    this.latitude,
    this.longitude,
    this.workLocation,
    this.address,
    this.filePath,
    this.attendanceRequestId,
    this.lateInMinutes = 0,
    this.workDate,
    this.shift,
    this.timezone,
  });

  bool get isClockIn {
    final type = attendanceType.toLowerCase();
    return type.contains('in') || type.contains('masuk');
  }

  bool get isLate => lateInMinutes > 0;

  bool get hasAttendanceRequest =>
      attendanceRequestId != null && attendanceRequestId!.trim().isNotEmpty;

  bool get isPhotoMethod {
    final method = attendanceMethod.toLowerCase();
    final hasPhotoKeyword = method.contains('photo') ||
        method.contains('foto') ||
        method.contains('face') ||
        method.contains('selfie');
    return hasPhotoKeyword && filePath != null && filePath!.trim().isNotEmpty;
  }

  /// Format jam 24 jam (HH:mm:ss), e.g. 14:24:55
  /// Menampilkan waktu murni dari server tanpa konversi ke lokal perangkat,
  /// karena server sudah menyesuaikan dengan timezone masing-masing pegawai.
  String get formattedTime24 {
    if (attendanceTime == null) return '--:--:--';
    return DateFormat('HH:mm:ss').format(attendanceTime!);
  }

  String get formattedDate {
    if (attendanceTime != null) {
      return DateFormat('EEEE, dd MMMM yyyy').format(attendanceTime!);
    }
    if (workDate != null && workDate!.isNotEmpty) {
      try {
        final cleanWorkDate = workDate!.trim().replaceFirst(RegExp(r'(?:[+-]\d{2}:?\d{2}|Z)$'), '');
        final parsed = DateTime.parse(cleanWorkDate);
        return DateFormat('EEEE, dd MMMM yyyy').format(parsed);
      } catch (_) {
        return workDate!;
      }
    }
    return '-';
  }

  String get coordinateDisplay {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
    }
    return '-';
  }

  /// Parsing waktu kehadiran dari server tanpa konversi ke lokal perangkat (.toLocal()).
  /// Data dari server sudah bersih dan mengikuti timezone masing-masing pegawai.
  static DateTime? _parseAttendanceTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return DateTime(
        raw.year,
        raw.month,
        raw.day,
        raw.hour,
        raw.minute,
        raw.second,
        raw.millisecond,
        raw.microsecond,
      );
    }
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Hapus offset timezone (+07:00, -05:00, +0700) atau 'Z' di akhir string.
    // Nilai waktu dari server sudah bersih mengikuti timezone masing-masing pegawai di database.
    final cleanStr = trimmed.replaceFirst(RegExp(r'(?:[+-]\d{2}:?\d{2}|Z)$'), '');
    final parsed = DateTime.tryParse(cleanStr);
    if (parsed != null) {
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }
    return null;
  }

  factory AttendanceDetailModel.fromJson(Map<String, dynamic> json) {
    final parsedTime = _parseAttendanceTime(json['attendanceTime']);

    double? parsedLat;
    if (json['latitude'] != null) {
      parsedLat = (json['latitude'] as num).toDouble();
    }

    double? parsedLng;
    if (json['longitude'] != null) {
      parsedLng = (json['longitude'] as num).toDouble();
    }

    return AttendanceDetailModel(
      id: json['id'] as String? ?? '',
      attendanceType: json['attendanceType'] as String? ?? '',
      attendanceTime: parsedTime,
      attendanceMethod: json['attendanceMethod'] as String? ?? '',
      employee: json['employee'] != null
          ? AttendanceEmployeeInfo.fromJson(
              json['employee'] as Map<String, dynamic>)
          : null,
      latitude: parsedLat,
      longitude: parsedLng,
      workLocation: json['workLocation'] != null
          ? AttendanceWorkLocationInfo.fromJson(
              json['workLocation'] as Map<String, dynamic>)
          : null,
      address: json['address'] as String?,
      filePath: json['filePath'] as String?,
      attendanceRequestId: json['attendanceRequestId'] as String?,
      lateInMinutes: (json['lateInMinutes'] as num?)?.toInt() ?? 0,
      workDate: json['workDate'] as String?,
      shift: json['shift'] != null
          ? AttendanceShiftInfo.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendanceType': attendanceType,
      'attendanceTime': attendanceTime?.toIso8601String(),
      'attendanceMethod': attendanceMethod,
      'employee': employee?.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'workLocation': workLocation?.toJson(),
      'address': address,
      'filePath': filePath,
      'attendanceRequestId': attendanceRequestId,
      'lateInMinutes': lateInMinutes,
      'workDate': workDate,
      'shift': shift?.toJson(),
      'timezone': timezone,
    };
  }

  @override
  List<Object?> get props => [
        id,
        attendanceType,
        attendanceTime,
        attendanceMethod,
        employee,
        latitude,
        longitude,
        workLocation,
        address,
        filePath,
        attendanceRequestId,
        lateInMinutes,
        workDate,
        shift,
        timezone,
      ];
}
