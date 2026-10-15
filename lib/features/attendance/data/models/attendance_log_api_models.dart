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
    final parentTimezone = (json['data'] is Map<String, dynamic>
            ? (json['data'] as Map<String, dynamic>)['timezone'] ??
                (json['data'] as Map<String, dynamic>)['timeZone']
            : null) ??
        json['timezone'] ??
        json['timeZone'];

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
        items.add(AttendanceLogItem.fromJson(
          entry,
          index: i,
          fallbackTimezone: parentTimezone?.toString(),
        ));
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
