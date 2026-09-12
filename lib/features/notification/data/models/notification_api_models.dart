import 'package:equatable/equatable.dart';

/// Model item notifikasi individu dari response backend HRIS.
class NotificationItemModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? readAt;
  final String? createdAt;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedData;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      parsedData = json['data'] as Map<String, dynamic>;
    }

    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      data: parsedData,
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      if (data != null) 'data': data,
      'isRead': isRead,
      'readAt': readAt,
      'createdAt': createdAt,
    };
  }

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    String? readAt,
    String? createdAt,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime? get createdAtDateTime {
    if (createdAt == null || createdAt!.isEmpty) return null;
    return DateTime.tryParse(createdAt!);
  }

  DateTime? get readAtDateTime {
    if (readAt == null || readAt!.isEmpty) return null;
    return DateTime.tryParse(readAt!);
  }

  /// Label waktu relatif yang ramah pengguna (contoh: "5m lalu", "2j lalu", "Kemarin", "12 Sep 2026")
  String get timeAgoLabel {
    final dt = createdAtDateTime;
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin, ${_pad(dt.hour)}:${_pad(dt.minute)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}h lalu';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final month = months[dt.month - 1];
      return '${dt.day} $month ${dt.year}';
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        data,
        isRead,
        readAt,
        createdAt,
      ];
}

/// Metadata pagination untuk daftar notifikasi
class NotificationPaginationMeta extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const NotificationPaginationMeta({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });

  factory NotificationPaginationMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPaginationMeta();
    return NotificationPaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
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

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}

/// Response payload dari `GET /api/v1/notifications`
class NotificationListResponse extends Equatable {
  final bool success;
  final String message;
  final List<NotificationItemModel> data;
  final NotificationPaginationMeta meta;

  const NotificationListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final List<NotificationItemModel> items = [];
    if (rawList is List) {
      for (final element in rawList) {
        if (element is Map<String, dynamic>) {
          items.add(NotificationItemModel.fromJson(element));
        }
      }
    }

    return NotificationListResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: NotificationPaginationMeta.fromJson(
        json['meta'] is Map<String, dynamic>
            ? json['meta'] as Map<String, dynamic>
            : null,
      ),
    );
  }

  @override
  List<Object?> get props => [success, message, data, meta];
}

/// Response payload dari `GET /api/v1/notifications/unread-count`
class NotificationUnreadCountResponse extends Equatable {
  final bool success;
  final String message;
  final int unreadCount;

  const NotificationUnreadCountResponse({
    required this.success,
    required this.message,
    required this.unreadCount,
  });

  factory NotificationUnreadCountResponse.fromJson(Map<String, dynamic> json) {
    int count = 0;
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      count = (data['unreadCount'] as num?)?.toInt() ?? 0;
    } else if (data is num) {
      count = data.toInt();
    }

    return NotificationUnreadCountResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      unreadCount: count,
    );
  }

  @override
  List<Object?> get props => [success, message, unreadCount];
}

/// Response payload dari `PATCH /api/v1/notifications/read-all`
class NotificationMarkReadAllResponse extends Equatable {
  final bool success;
  final String message;
  final int updatedCount;

  const NotificationMarkReadAllResponse({
    required this.success,
    required this.message,
    required this.updatedCount,
  });

  factory NotificationMarkReadAllResponse.fromJson(Map<String, dynamic> json) {
    int count = 0;
    String msg = json['message']?.toString() ?? '';
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      count = (data['updatedCount'] as num?)?.toInt() ?? 0;
      if (data['message'] != null) {
        msg = data['message'].toString();
      }
    }

    return NotificationMarkReadAllResponse(
      success: json['success'] == true,
      message: msg,
      updatedCount: count,
    );
  }

  @override
  List<Object?> get props => [success, message, updatedCount];
}

/// Response payload dari `PATCH /api/v1/notifications/{id}/read`
class NotificationMarkReadResponse extends Equatable {
  final bool success;
  final String message;
  final String id;

  const NotificationMarkReadResponse({
    required this.success,
    required this.message,
    required this.id,
  });

  factory NotificationMarkReadResponse.fromJson(Map<String, dynamic> json) {
    String notificationId = '';
    String msg = json['message']?.toString() ?? '';
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      notificationId = data['id']?.toString() ?? '';
      if (data['message'] != null) {
        msg = data['message'].toString();
      }
    }

    return NotificationMarkReadResponse(
      success: json['success'] == true,
      message: msg,
      id: notificationId,
    );
  }

  @override
  List<Object?> get props => [success, message, id];
}
