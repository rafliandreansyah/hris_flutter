import 'package:equatable/equatable.dart';
import 'warning_letter_item_model.dart';

/// Metadata paginasi untuk response daftar surat peringatan.
class WarningLetterPaginationMeta extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const WarningLetterPaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory WarningLetterPaginationMeta.fromJson(Map<String, dynamic> json) {
    return WarningLetterPaginationMeta(
      page: (json['page'] is num) ? (json['page'] as num).toInt() : 1,
      limit: (json['limit'] is num) ? (json['limit'] as num).toInt() : 10,
      total: (json['total'] is num) ? (json['total'] as num).toInt() : 0,
      totalPages:
          (json['totalPages'] is num) ? (json['totalPages'] as num).toInt() : 1,
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

  bool get hasNextPage => page < totalPages;

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}

/// Response lengkap dari API `GET /warning-letter`.
class WarningLetterListResponse extends Equatable {
  final bool success;
  final String message;
  final List<WarningLetterItem> data;
  final WarningLetterPaginationMeta meta;

  const WarningLetterListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory WarningLetterListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<WarningLetterItem> items = [];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          items.add(WarningLetterItem.fromJson(item));
        }
      }
    }

    final rawMeta = json['meta'];
    final metaObj = rawMeta is Map<String, dynamic>
        ? WarningLetterPaginationMeta.fromJson(rawMeta)
        : const WarningLetterPaginationMeta(
            page: 1,
            limit: 10,
            total: 0,
            totalPages: 1,
          );

    return WarningLetterListResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: metaObj,
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

  @override
  List<Object?> get props => [success, message, data, meta];
}
