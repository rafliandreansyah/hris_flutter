enum AttendanceLogType { clockIn, clockOut }

enum AttendanceLogPunctuality { onTime, late }

class AttendanceLogItem {
  final String id;
  final DateTime dateTime;
  final AttendanceLogType type;
  final String? locationName;
  final String? locationId;
  final String? method;
  final int? lateMinutes;
  final String? timezone;
  final String? date;

  const AttendanceLogItem({
    required this.id,
    required this.dateTime,
    required this.type,
    this.locationName,
    this.locationId,
    this.method,
    this.lateMinutes,
    this.timezone,
    this.date,
  });

  bool get isLate => (lateMinutes ?? 0) > 0;

  AttendanceLogPunctuality get punctuality =>
      isLate ? AttendanceLogPunctuality.late : AttendanceLogPunctuality.onTime;

  String get timezoneAbbreviation {
    final tz = (timezone ?? '').toLowerCase();
    if (tz.contains('jakarta') || tz.contains('wib')) return 'WIB';
    if (tz.contains('makassar') || tz.contains('wita')) return 'WITA';
    if (tz.contains('jayapura') || tz.contains('wit')) return 'WIT';
    if (tz.isNotEmpty) return timezone!.toUpperCase();
    return 'WIB';
  }

  AttendanceLogItem copyWith({
    String? id,
    DateTime? dateTime,
    AttendanceLogType? type,
    String? locationName,
    String? locationId,
    String? method,
    int? lateMinutes,
    String? timezone,
    String? date,
  }) {
    return AttendanceLogItem(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      locationName: locationName ?? this.locationName,
      locationId: locationId ?? this.locationId,
      method: method ?? this.method,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      timezone: timezone ?? this.timezone,
      date: date ?? this.date,
    );
  }

  factory AttendanceLogItem.fromJson(
    Map<String, dynamic> json, {
    int index = 0,
  }) {
    final workLoc = json['workLocation'];
    String? locName;
    String? locId;
    if (workLoc is Map<String, dynamic>) {
      locName = workLoc['name']?.toString();
      locId = workLoc['id']?.toString();
    } else if (workLoc is String && workLoc.trim().isNotEmpty) {
      locName = workLoc.trim();
    }

    return AttendanceLogItem(
      id: (json['id'] ?? json['attendanceId'] ?? 'LOG-$index').toString(),
      dateTime: _parseDateTime(json) ?? DateTime.now(),
      type: _parseType(json),
      locationName: locName ??
          _firstString(json, const [
            'locationName',
            'location',
            'address',
            'officeName',
          ]),
      locationId: locId ?? json['workLocationId']?.toString(),
      method: _firstString(json, const [
        'attendanceMethod',
        'method',
        'clockMethod',
        'source',
      ]),
      lateMinutes: _firstInt(json, const [
        'lateInMinutes',
        'lateMinutes',
        'lateBy',
        'minutesLate',
      ]),
      timezone: _firstString(json, const ['timezone', 'timeZone', 'tz']),
      date: json['date']?.toString(),
    );
  }

  static DateTime? _parseDateTime(Map<String, dynamic> json) {
    const keys = [
      'attendanceTime',
      'dateTime',
      'datetime',
      'time',
      'clockTime',
      'attendanceDate',
      'date',
      'createdAt',
    ];
    for (final key in keys) {
      final raw = json[key];
      if (raw is String && raw.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return parsed.isUtc ? parsed.toLocal() : parsed;
        }
      }
      if (raw is num) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      }
    }
    final datePart = json['date'] is String ? json['date'] as String : null;
    final timePart = json['time'] is String ? json['time'] as String : null;
    if (datePart != null && timePart != null) {
      final parsed = DateTime.tryParse('$datePart $timePart');
      if (parsed != null) return parsed.isUtc ? parsed.toLocal() : parsed;
    }
    return null;
  }

  static AttendanceLogType _parseType(Map<String, dynamic> json) {
    final raw = (json['attendanceType'] ??
            json['type'] ??
            json['logType'] ??
            json['clockType'] ??
            '')
        .toString()
        .toUpperCase()
        .trim();
    if (raw.contains('OUT') || raw == 'O') {
      return AttendanceLogType.clockOut;
    }
    if (raw.contains('IN') || raw == 'I') {
      return AttendanceLogType.clockIn;
    }
    if (json['clockOutTime'] != null && json['clockInTime'] == null) {
      return AttendanceLogType.clockOut;
    }
    return AttendanceLogType.clockIn;
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is String && raw.trim().isNotEmpty) return raw;
    }
    return null;
  }

  static int? _firstInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'dateTime': dateTime.toIso8601String(),
      'attendanceTime': dateTime.toIso8601String(),
      'type': type == AttendanceLogType.clockIn ? 'IN' : 'OUT',
      'attendanceType':
          type == AttendanceLogType.clockIn ? 'CLOCK_IN' : 'CLOCK_OUT',
      'locationName': locationName,
      'method': method,
      'attendanceMethod': method,
      'lateMinutes': lateMinutes,
      'lateInMinutes': lateMinutes,
      'timezone': timezone,
      if (locationId != null || locationName != null)
        'workLocation': {
          if (locationId != null) 'id': locationId,
          if (locationName != null) 'name': locationName,
        },
    };
  }
}
