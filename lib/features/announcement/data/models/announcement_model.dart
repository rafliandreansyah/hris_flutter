import 'package:equatable/equatable.dart';

/// DTO Model untuk item Pengumuman (Announcement)
class AnnouncementItem extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final String content;
  final String? imageUrl;
  final String priority;
  final String category;
  final bool isPinned;
  final bool requiresAcknowledgment;
  final bool isRead;
  final bool isAcknowledged;
  final String? publishedAt;
  final String? createdAt;

  const AnnouncementItem({
    required this.id,
    required this.title,
    this.summary,
    this.content = '',
    this.imageUrl,
    this.priority = 'low',
    this.category = 'general',
    this.isPinned = false,
    this.requiresAcknowledgment = false,
    this.isRead = false,
    this.isAcknowledged = false,
    this.publishedAt,
    this.createdAt,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      priority: json['priority']?.toString() ?? 'low',
      category: json['category']?.toString() ?? 'general',
      isPinned: json['isPinned'] == true,
      requiresAcknowledgment: json['requiresAcknowledgment'] == true,
      isRead: json['isRead'] == true,
      isAcknowledged: json['isAcknowledged'] == true,
      publishedAt: json['publishedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'priority': priority,
      'category': category,
      'isPinned': isPinned,
      'requiresAcknowledgment': requiresAcknowledgment,
      'isRead': isRead,
      'isAcknowledged': isAcknowledged,
      'publishedAt': publishedAt,
      'createdAt': createdAt,
    };
  }

  AnnouncementItem copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? priority,
    String? category,
    bool? isPinned,
    bool? requiresAcknowledgment,
    bool? isRead,
    bool? isAcknowledged,
    String? publishedAt,
    String? createdAt,
  }) {
    return AnnouncementItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      requiresAcknowledgment:
          requiresAcknowledgment ?? this.requiresAcknowledgment,
      isRead: isRead ?? this.isRead,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime? get publishedAtDateTime {
    if (publishedAt == null || publishedAt!.isEmpty) return null;
    return DateTime.tryParse(publishedAt!);
  }

  DateTime? get createdAtDateTime {
    if (createdAt == null || createdAt!.isEmpty) return null;
    return DateTime.tryParse(createdAt!);
  }

  DateTime? get effectiveDateTime => publishedAtDateTime ?? createdAtDateTime;

  /// Label tanggal yang diformat ramah pengguna (contoh: "18 September 2026")
  String get formattedDate {
    final dt = effectiveDateTime;
    if (dt == null) return '';

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final month = months[dt.month - 1];
    return '${dt.day} $month ${dt.year}';
  }

  /// Label nama kategori ramah pengguna
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'hr_policy':
        return 'Kebijakan HR';
      case 'event':
        return 'Kegiatan';
      case 'holiday':
        return 'Hari Libur';
      case 'maintenance':
        return 'Pemeliharaan';
      case 'emergency':
        return 'Darurat';
      case 'general':
      default:
        return 'Umum';
    }
  }

  /// Label badge kategori (uppercase)
  String get categoryBadgeText {
    switch (category.toLowerCase()) {
      case 'hr_policy':
        return 'HR POLICY';
      case 'event':
        return 'EVENT';
      case 'holiday':
        return 'HOLIDAY';
      case 'maintenance':
        return 'MAINTENANCE';
      case 'emergency':
        return 'EMERGENCY';
      case 'general':
      default:
        return 'GENERAL';
    }
  }

  /// Label prioritas ramah pengguna
  String get priorityDisplayName {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Mendesak';
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Menengah';
      case 'low':
      default:
        return 'Rendah';
    }
  }

  /// Mengambil deskripsi tampilan (summary diutamakan, fallback ke content polos tanpa tag HTML)
  String? get displayDescription {
    if (summary != null && summary!.trim().isNotEmpty) {
      return summary!.trim();
    }
    if (content.trim().isNotEmpty) {
      final stripped = content
          .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return stripped.isNotEmpty ? stripped : null;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        content,
        imageUrl,
        priority,
        category,
        isPinned,
        requiresAcknowledgment,
        isRead,
        isAcknowledged,
        publishedAt,
        createdAt,
      ];
}

/// Metadata pagination untuk daftar pengumuman
class AnnouncementPaginationMeta extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AnnouncementPaginationMeta({
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 1,
  });

  factory AnnouncementPaginationMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnnouncementPaginationMeta();
    return AnnouncementPaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
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

/// Response payload dari `GET /api/v1/announcement`
class AnnouncementListResponse extends Equatable {
  final bool success;
  final String message;
  final List<AnnouncementItem> data;
  final AnnouncementPaginationMeta meta;

  const AnnouncementListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory AnnouncementListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final List<AnnouncementItem> items = [];
    if (rawList is List) {
      for (final element in rawList) {
        if (element is Map<String, dynamic>) {
          items.add(AnnouncementItem.fromJson(element));
        }
      }
    }

    return AnnouncementListResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: AnnouncementPaginationMeta.fromJson(
        json['meta'] is Map<String, dynamic>
            ? json['meta'] as Map<String, dynamic>
            : null,
      ),
    );
  }

  @override
  List<Object?> get props => [success, message, data, meta];
}
