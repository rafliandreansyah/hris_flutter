import 'package:equatable/equatable.dart';

/// Satu sesi istirahat dari API `GET /attendances/break/today`.
class AttendanceBreakItem extends Equatable {
  final String id;
  final String attendanceId;

  /// Waktu mulai (instan absolut, sudah di-parse dari ISO-8601 beroffset).
  final DateTime startTime;

  /// Waktu selesai; `null` bila istirahat masih berjalan.
  final DateTime? endTime;
  final int? durationMinutes;
  final String? note;

  const AttendanceBreakItem({
    required this.id,
    required this.attendanceId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.note,
  });

  bool get isOngoing => endTime == null;

  /// Durasi efektif pada [now] (menit utuh). Sesi selesai memakai nilai server.
  int minutesAt(DateTime now) {
    if (!isOngoing) return durationMinutes ?? endTime!.difference(startTime).inMinutes;
    final diff = now.difference(startTime).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  factory AttendanceBreakItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? raw) {
      final text = raw?.toString();
      if (text == null || text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return AttendanceBreakItem(
      id: json['id']?.toString() ?? '',
      attendanceId: json['attendanceId']?.toString() ?? '',
      startTime: parse(json['startTime']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      endTime: parse(json['endTime']),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      note: json['note']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, attendanceId, startTime, endTime, durationMinutes, note];
}

/// Ringkasan istirahat hari ini (`GET /attendances/break/today`).
class AttendanceBreakStatus extends Equatable {
  final String? attendanceId;
  final bool isOnBreak;
  final AttendanceBreakItem? activeBreak;
  final int totalBreakMinutes;
  final int overbreakMinutes;

  /// Jatah istirahat shift (menit); `null` bila tidak ada jatah.
  final int? allocatedBreakMinutes;
  final bool isFlexibleBreak;
  final List<AttendanceBreakItem> breaks;

  const AttendanceBreakStatus({
    this.attendanceId,
    this.isOnBreak = false,
    this.activeBreak,
    this.totalBreakMinutes = 0,
    this.overbreakMinutes = 0,
    this.allocatedBreakMinutes,
    this.isFlexibleBreak = false,
    this.breaks = const [],
  });

  static const empty = AttendanceBreakStatus();

  /// Total istirahat termasuk sesi yang sedang berjalan pada [now].
  int totalMinutesAt(DateTime now) {
    final closed = breaks
        .where((b) => !b.isOngoing)
        .fold<int>(0, (sum, b) => sum + b.minutesAt(now));
    final active = activeBreak;
    return closed + (active == null ? 0 : active.minutesAt(now));
  }

  /// Sisa jatah (menit, minimal 0); `null` bila tidak ada jatah.
  int? remainingMinutesAt(DateTime now) {
    final allocated = allocatedBreakMinutes;
    if (allocated == null) return null;
    final left = allocated - totalMinutesAt(now);
    return left < 0 ? 0 : left;
  }

  /// Menit melebihi jatah pada [now]; 0 bila tidak ada jatah atau belum lewat.
  int overbreakMinutesAt(DateTime now) {
    final allocated = allocatedBreakMinutes;
    if (allocated == null) return 0;
    final over = totalMinutesAt(now) - allocated;
    return over < 0 ? 0 : over;
  }

  factory AttendanceBreakStatus.fromJson(Map<String, dynamic> json) {
    final rawBreaks = json['breaks'] is List ? json['breaks'] as List : const [];
    final items = rawBreaks
        .whereType<Map<String, dynamic>>()
        .map(AttendanceBreakItem.fromJson)
        .toList();
    final active = json['activeBreak'] is Map<String, dynamic>
        ? AttendanceBreakItem.fromJson(json['activeBreak'] as Map<String, dynamic>)
        : null;

    return AttendanceBreakStatus(
      attendanceId: json['attendanceId']?.toString(),
      isOnBreak: json['isOnBreak'] == true,
      activeBreak: active,
      totalBreakMinutes: (json['totalBreakMinutes'] as num?)?.toInt() ?? 0,
      overbreakMinutes: (json['overbreakMinutes'] as num?)?.toInt() ?? 0,
      allocatedBreakMinutes: (json['allocatedBreakMinutes'] as num?)?.toInt(),
      isFlexibleBreak: json['isFlexibleBreak'] == true,
      breaks: items,
    );
  }

  @override
  List<Object?> get props => [
        attendanceId,
        isOnBreak,
        activeBreak,
        totalBreakMinutes,
        overbreakMinutes,
        allocatedBreakMinutes,
        isFlexibleBreak,
        breaks,
      ];
}
