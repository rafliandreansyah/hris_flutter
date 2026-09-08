import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';

class AttendanceLogPaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AttendanceLogPaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory AttendanceLogPaginationMeta.fromJson(
    Map<String, dynamic> json, {
    int? fallbackTotal,
  }) {
    return AttendanceLogPaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ??
          (fallbackTotal != null && fallbackTotal > 0 ? fallbackTotal : 20),
      total: (json['total'] as num?)?.toInt() ?? (fallbackTotal ?? 0),
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

class AttendanceLogListResponse {
  final bool success;
  final String message;
  final List<AttendanceLogItem> data;
  final AttendanceLogPaginationMeta meta;

  const AttendanceLogListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory AttendanceLogListResponse.fromJson(Map<String, dynamic> json) {
    final rawSource = json['data'] is Map<String, dynamic>
        ? ((json['data'] as Map<String, dynamic>)['logs'] is List
              ? (json['data'] as Map<String, dynamic>)['logs'] as List
              : (json['data'] as Map<String, dynamic>)['data'] is List
              ? (json['data'] as Map<String, dynamic>)['data'] as List
              : const [])
        : (json['data'] is List ? json['data'] as List : const []);

    final items = <AttendanceLogItem>[];
    for (var i = 0; i < rawSource.length; i++) {
      final entry = rawSource[i];
      if (entry is Map<String, dynamic>) {
        items.add(AttendanceLogItem.fromJson(entry, index: i));
      }
    }

    final metaSource = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> &&
                  (json['data'] as Map<String, dynamic>)['meta']
                      is Map<String, dynamic>
              ? (json['data'] as Map<String, dynamic>)['meta']
                    as Map<String, dynamic>
              : <String, dynamic>{});

    return AttendanceLogListResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: AttendanceLogPaginationMeta.fromJson(
        metaSource,
        fallbackTotal: items.length,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }
}

class AttendanceLogSummary {
  final int totalInDays;
  final double presentPercentage;
  final int lateMinutes;
  final int lateCount;

  const AttendanceLogSummary({
    required this.totalInDays,
    required this.presentPercentage,
    required this.lateMinutes,
    required this.lateCount,
  });

  static const AttendanceLogSummary empty = AttendanceLogSummary(
    totalInDays: 0,
    presentPercentage: 0,
    lateMinutes: 0,
    lateCount: 0,
  );

  factory AttendanceLogSummary.fromJson(Map<String, dynamic> json) {
    final source = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return AttendanceLogSummary(
      totalInDays: _firstInt(source, const [
        'totalInDays',
        'totalIn',
        'presentDays',
        'totalPresent',
      ]) ??
          0,
      presentPercentage: _firstDouble(source, const [
        'presentPercentage',
        'attendancePercentage',
        'presentPercent',
        'percentage',
      ]) ??
          0,
      lateMinutes: _firstInt(source, const [
        'lateMinutes',
        'totalLateMinutes',
        'totalLate',
      ]) ??
          0,
      lateCount: _firstInt(source, const [
        'lateCount',
        'lateRecords',
        'totalLateCount',
      ]) ??
          0,
    );
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

  static double? _firstDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) {
        final parsed = double.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalInDays': totalInDays,
      'presentPercentage': presentPercentage,
      'lateMinutes': lateMinutes,
      'lateCount': lateCount,
    };
  }
}
