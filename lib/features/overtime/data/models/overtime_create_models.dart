import 'package:equatable/equatable.dart';

/// Model shift kerja dalam jadwal lembur (`schedule.shift`).
class OvertimeShiftModel extends Equatable {
  final String id;
  final String? startTime;
  final String? endTime;
  final bool isFlexibleTime;
  final bool isFlexibleBreak;
  final String? breakStart;
  final String? breakEnd;
  final bool isNightShift;
  final String? color;

  const OvertimeShiftModel({
    required this.id,
    this.startTime,
    this.endTime,
    this.isFlexibleTime = false,
    this.isFlexibleBreak = false,
    this.breakStart,
    this.breakEnd,
    this.isNightShift = false,
    this.color,
  });

  factory OvertimeShiftModel.fromJson(Map<String, dynamic> json) {
    return OvertimeShiftModel(
      id: json['id']?.toString() ?? '',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      isFlexibleTime: json['isFlexibleTime'] as bool? ?? false,
      isFlexibleBreak: json['isFlexibleBreak'] as bool? ?? false,
      breakStart: json['breakStart']?.toString(),
      breakEnd: json['breakEnd']?.toString(),
      isNightShift: json['isNightShift'] as bool? ?? false,
      color: json['color']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime,
        'endTime': endTime,
        'isFlexibleTime': isFlexibleTime,
        'isFlexibleBreak': isFlexibleBreak,
        'breakStart': breakStart,
        'breakEnd': breakEnd,
        'isNightShift': isNightShift,
        'color': color,
      };

  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        isFlexibleTime,
        isFlexibleBreak,
        breakStart,
        breakEnd,
        isNightShift,
        color,
      ];
}

/// Model objek jadwal kerja pada hari pengajuan (`schedule`).
class OvertimeScheduleInfoModel extends Equatable {
  final String id;
  final String? workDate;
  final bool isDayOff;
  final OvertimeShiftModel? shift;

  const OvertimeScheduleInfoModel({
    required this.id,
    this.workDate,
    this.isDayOff = false,
    this.shift,
  });

  factory OvertimeScheduleInfoModel.fromJson(Map<String, dynamic> json) {
    return OvertimeScheduleInfoModel(
      id: json['id']?.toString() ?? '',
      workDate: json['workDate']?.toString(),
      isDayOff: json['isDayOff'] as bool? ?? false,
      shift: json['shift'] is Map<String, dynamic>
          ? OvertimeShiftModel.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workDate': workDate,
        'isDayOff': isDayOff,
        'shift': shift?.toJson(),
      };

  @override
  List<Object?> get props => [id, workDate, isDayOff, shift];
}

/// Model data presensi pada tanggal pengajuan (`attendance`).
class OvertimeAttendanceInfoModel extends Equatable {
  final String id;
  final String? checkIn;
  final String? checkOut;

  const OvertimeAttendanceInfoModel({
    required this.id,
    this.checkIn,
    this.checkOut,
  });

  factory OvertimeAttendanceInfoModel.fromJson(Map<String, dynamic> json) {
    return OvertimeAttendanceInfoModel(
      id: json['id']?.toString() ?? '',
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'checkIn': checkIn,
        'checkOut': checkOut,
      };

  @override
  List<Object?> get props => [id, checkIn, checkOut];
}

/// Data payload respons dari endpoint `GET /overtime/schedule?dateTimeStart=`.
class OvertimeScheduleData extends Equatable {
  final bool isGenerated;
  final bool isDayOff;
  final bool requiresCheckOut;
  final String? workScheduleId;
  final OvertimeScheduleInfoModel? schedule;
  final OvertimeAttendanceInfoModel? attendance;
  final String? message;

  const OvertimeScheduleData({
    this.isGenerated = false,
    this.isDayOff = false,
    this.requiresCheckOut = false,
    this.workScheduleId,
    this.schedule,
    this.attendance,
    this.message,
  });

  factory OvertimeScheduleData.fromJson(Map<String, dynamic> json) {
    return OvertimeScheduleData(
      isGenerated: json['isGenerated'] as bool? ?? false,
      isDayOff: json['isDayOff'] as bool? ?? false,
      requiresCheckOut: json['requiresCheckOut'] as bool? ?? false,
      workScheduleId: json['workScheduleId']?.toString(),
      schedule: json['schedule'] is Map<String, dynamic>
          ? OvertimeScheduleInfoModel.fromJson(
              json['schedule'] as Map<String, dynamic>)
          : null,
      attendance: json['attendance'] is Map<String, dynamic>
          ? OvertimeAttendanceInfoModel.fromJson(
              json['attendance'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'isGenerated': isGenerated,
        'isDayOff': isDayOff,
        'requiresCheckOut': requiresCheckOut,
        'workScheduleId': workScheduleId,
        'schedule': schedule?.toJson(),
        'attendance': attendance?.toJson(),
        'message': message,
      };

  /// True jika karyawan memiliki jadwal kerja pada hari ini.
  bool get hasSchedule {
    if (workScheduleId != null && workScheduleId!.trim().isNotEmpty) {
      return true;
    }
    return schedule != null && !isDayOff;
  }

  /// True jika karyawan memiliki jadwal tetapi belum melakukan check-out presensi.
  bool get isMissingCheckOut {
    if (!hasSchedule) return false;
    final co = attendance?.checkOut;
    return co == null || co.trim().isEmpty;
  }

  /// ID efektif jadwal kerja untuk dikirim ke API POST /overtime.
  String? get effectiveWorkScheduleId {
    if (workScheduleId != null && workScheduleId!.trim().isNotEmpty) {
      return workScheduleId!.trim();
    }
    if (schedule != null && schedule!.id.isNotEmpty) {
      return schedule!.id;
    }
    return null;
  }

  /// Helper untuk mem-parsing jam shift mulai menjadi [DateTime] pada tanggal yang sama dengan [baseDate].
  DateTime? parsedShiftStartTime(DateTime baseDate) {
    final raw = schedule?.shift?.startTime;
    return _parseTimeToDateTime(raw, baseDate);
  }

  /// Helper untuk mem-parsing jam shift selesai menjadi [DateTime] pada tanggal yang sama dengan [baseDate].
  DateTime? parsedShiftEndTime(DateTime baseDate) {
    final raw = schedule?.shift?.endTime;
    return _parseTimeToDateTime(raw, baseDate);
  }

  /// Helper untuk mem-parsing jam check-out kehadiran menjadi [DateTime].
  DateTime? parsedCheckOutDateTime(DateTime baseDate) {
    final raw = attendance?.checkOut;
    return _parseTimeToDateTime(raw, baseDate);
  }

  /// Helper internal parsing string jam (HH:mm:ss atau ISO 8601).
  static DateTime? _parseTimeToDateTime(String? raw, DateTime baseDate) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();

    // 1. Coba parsing langsung sebagai ISO 8601 lengkap (misal 2026-09-12T17:00:00Z)
    final direct = DateTime.tryParse(trimmed);
    if (direct != null && trimmed.contains('T')) {
      return direct.toLocal();
    }

    // 2. Format jam: HH:mm:ss atau HH:mm
    final parts = trimmed.split(':');
    if (parts.isNotEmpty) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final second = parts.length > 2 ? (int.tryParse(parts[2].split('.')[0]) ?? 0) : 0;
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute, second);
    }

    return null;
  }

  @override
  List<Object?> get props => [
        isGenerated,
        isDayOff,
        requiresCheckOut,
        workScheduleId,
        schedule,
        attendance,
        message,
      ];
}

/// Pembungkus respons API dari `GET /overtime/schedule`.
class OvertimeScheduleResponse extends Equatable {
  final bool success;
  final String message;
  final OvertimeScheduleData data;

  const OvertimeScheduleResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OvertimeScheduleResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return OvertimeScheduleResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: OvertimeScheduleData.fromJson(dataMap),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Model respons hasil pengiriman pengajuan lembur dari `POST /overtime`.
class CreateOvertimeResultModel extends Equatable {
  final bool success;
  final String message;
  final String id;

  const CreateOvertimeResultModel({
    required this.success,
    required this.message,
    this.id = '',
  });

  factory CreateOvertimeResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return CreateOvertimeResultModel(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      id: data['id']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [success, message, id];
}
