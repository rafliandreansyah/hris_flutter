import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

/// Metadata paginasi respons dari endpoint `/employee`.
class EmployeePaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const EmployeePaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory EmployeePaginationMeta.fromJson(Map<String, dynamic> json) {
    return EmployeePaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 30,
      total: (json['total'] as num?)?.toInt() ?? 0,
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

/// Pembungkus respons API dari endpoint `/employee`.
class EmployeeListResponse {
  final bool success;
  final String message;
  final List<EmployeeDirectoryItem> data;
  final EmployeePaginationMeta meta;

  const EmployeeListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory EmployeeListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] is List ? json['data'] as List : [];
    final items = dataList
        .whereType<Map<String, dynamic>>()
        .map((item) => EmployeeDirectoryItem.fromJson(item))
        .toList();

    final metaMap = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return EmployeeListResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: EmployeePaginationMeta.fromJson(metaMap),
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
