import 'package:equatable/equatable.dart';

/// DTO Model untuk detail pengumuman (Announcement Detail)
class AnnouncementDetailModel extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final String content;
  final String? imageUrl;
  final String priority;
  final String category;
  final bool isPinned;
  final bool requiresAcknowledgment;
  final String? scope;
  final AnnouncementUserReadStatus? userReadStatus;
  final List<AnnouncementAttachment> attachments;
  final AnnouncementAuthor? author;
  final String? publishedAt;
  final String? createdAt;

  const AnnouncementDetailModel({
    required this.id,
    required this.title,
    this.summary,
    this.content = '',
    this.imageUrl,
    this.priority = 'low',
    this.category = 'general',
    this.isPinned = false,
    this.requiresAcknowledgment = false,
    this.scope,
    this.userReadStatus,
    this.attachments = const [],
    this.author,
    this.publishedAt,
    this.createdAt,
  });

  factory AnnouncementDetailModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final List<AnnouncementAttachment> parsedAttachments = [];
    if (rawAttachments is List) {
      for (final item in rawAttachments) {
        if (item is Map<String, dynamic>) {
          parsedAttachments.add(AnnouncementAttachment.fromJson(item));
        }
      }
    }

    return AnnouncementDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      priority: json['priority']?.toString() ?? 'low',
      category: json['category']?.toString() ?? 'general',
      isPinned: json['isPinned'] == true,
      requiresAcknowledgment: json['requiresAcknowledgment'] == true,
      scope: json['scope']?.toString(),
      userReadStatus: json['userReadStatus'] is Map<String, dynamic>
          ? AnnouncementUserReadStatus.fromJson(
              json['userReadStatus'] as Map<String, dynamic>,
            )
          : null,
      attachments: parsedAttachments,
      author: json['author'] is Map<String, dynamic>
          ? AnnouncementAuthor.fromJson(
              json['author'] as Map<String, dynamic>,
            )
          : null,
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
      'scope': scope,
      if (userReadStatus != null) 'userReadStatus': userReadStatus!.toJson(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      if (author != null) 'author': author!.toJson(),
      'publishedAt': publishedAt,
      'createdAt': createdAt,
    };
  }

  AnnouncementDetailModel copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? priority,
    String? category,
    bool? isPinned,
    bool? requiresAcknowledgment,
    String? scope,
    AnnouncementUserReadStatus? userReadStatus,
    List<AnnouncementAttachment>? attachments,
    AnnouncementAuthor? author,
    String? publishedAt,
    String? createdAt,
  }) {
    return AnnouncementDetailModel(
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
      scope: scope ?? this.scope,
      userReadStatus: userReadStatus ?? this.userReadStatus,
      attachments: attachments ?? this.attachments,
      author: author ?? this.author,
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

  /// Label tanggal lengkap & jam publikasi (contoh: "28 Agustus 2026, 10:11 WIB")
  String get formattedDateTime {
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
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute WIB';
  }

  /// Label badge kategori (uppercase)
  String get categoryBadgeText {
    switch (category.toLowerCase()) {
      case 'hr_policy':
        return 'POLICY';
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
        return 'URGENT NOTICE';
      case 'high':
        return 'HIGH PRIORITY';
      case 'medium':
        return 'MEDIUM';
      case 'low':
      default:
        return 'LOW';
    }
  }

  /// Label scope ramah pengguna
  String get scopeDisplayName {
    final s = scope?.toLowerCase() ?? '';
    if (s == 'company') return 'Company-Wide';
    if (s == 'department') return 'Department';
    if (s == 'branch') return 'Branch';
    return scope ?? 'Company-Wide';
  }

  /// Subtitle di Top App Bar
  String get scopeAndCategorySubtitle {
    final sc = (scope ?? 'Company').toUpperCase();
    return 'SCOPE: $sc • $categoryBadgeText';
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
        scope,
        userReadStatus,
        attachments,
        author,
        publishedAt,
        createdAt,
      ];
}

/// Status pembacaan dan konfirmasi pengguna terhadap pengumuman
class AnnouncementUserReadStatus extends Equatable {
  final bool isRead;
  final String? readAt;
  final bool isAcknowledged;
  final String? acknowledgedAt;

  const AnnouncementUserReadStatus({
    this.isRead = false,
    this.readAt,
    this.isAcknowledged = false,
    this.acknowledgedAt,
  });

  factory AnnouncementUserReadStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnnouncementUserReadStatus();
    return AnnouncementUserReadStatus(
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
      isAcknowledged: json['isAcknowledged'] == true,
      acknowledgedAt: json['acknowledgedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isRead': isRead,
      'readAt': readAt,
      'isAcknowledged': isAcknowledged,
      'acknowledgedAt': acknowledgedAt,
    };
  }

  AnnouncementUserReadStatus copyWith({
    bool? isRead,
    String? readAt,
    bool? isAcknowledged,
    String? acknowledgedAt,
  }) {
    return AnnouncementUserReadStatus(
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  DateTime? get acknowledgedAtDateTime {
    if (acknowledgedAt == null || acknowledgedAt!.isEmpty) return null;
    return DateTime.tryParse(acknowledgedAt!);
  }

  String get formattedAcknowledgedAt {
    final dt = acknowledgedAtDateTime;
    if (dt == null) return '';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute WIB';
  }

  @override
  List<Object?> get props => [isRead, readAt, isAcknowledged, acknowledgedAt];
}

/// DTO Dokumen Lampiran Pengumuman
class AnnouncementAttachment extends Equatable {
  final String id;
  final String fileName;
  final String fileUrl;
  final dynamic fileSize;
  final String? fileType;
  final String? createdAt;

  const AnnouncementAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.fileType,
    this.createdAt,
  });

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachment(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'Dokumen Lampiran',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileSize: json['fileSize'],
      fileType: json['fileType']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'fileType': fileType,
      'createdAt': createdAt,
    };
  }

  /// Menentukan apakah file merupakan PDF
  bool get isPdf {
    if (fileType != null && fileType!.toLowerCase().contains('pdf')) {
      return true;
    }
    return fileName.toLowerCase().endsWith('.pdf') ||
        fileUrl.toLowerCase().contains('.pdf');
  }

  /// Format ukuran file yang ramah pengguna
  String get formattedSize {
    if (fileSize == null) {
      return isPdf ? 'PDF Dokumen' : 'Berkas Lampiran';
    }

    num bytes = 0;
    if (fileSize is num) {
      bytes = fileSize as num;
    } else if (fileSize is String) {
      bytes = num.tryParse(fileSize as String) ?? 0;
    }

    if (bytes <= 0) {
      return isPdf ? 'PDF Dokumen' : 'Berkas Lampiran';
    }

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    }
  }

  /// Teks subtitle badge lampiran (contoh: "2.4 MB • PDF")
  String get subtitleLabel {
    final typeLabel = isPdf ? 'PDF' : (fileType?.toUpperCase() ?? 'FILE');
    return '$formattedSize • $typeLabel';
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        fileUrl,
        fileSize,
        fileType,
        createdAt,
      ];
}

/// DTO Penerbit / Author Pengumuman
class AnnouncementAuthor extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? idNumber;
  final String? employeeNumber;
  final AnnouncementOrgItem? company;
  final AnnouncementOrgItem? department;
  final AnnouncementOrgItem? position;
  final String? photoUrl;

  const AnnouncementAuthor({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.idNumber,
    this.employeeNumber,
    this.company,
    this.department,
    this.position,
    this.photoUrl,
  });

  factory AnnouncementAuthor.fromJson(Map<String, dynamic> json) {
    return AnnouncementAuthor(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      idNumber: json['idNumber']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? AnnouncementOrgItem.fromJson(
              json['company'] as Map<String, dynamic>,
            )
          : null,
      department: json['department'] is Map<String, dynamic>
          ? AnnouncementOrgItem.fromJson(
              json['department'] as Map<String, dynamic>,
            )
          : null,
      position: json['position'] is Map<String, dynamic>
          ? AnnouncementOrgItem.fromJson(
              json['position'] as Map<String, dynamic>,
            )
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'idNumber': idNumber,
      'employeeNumber': employeeNumber,
      if (company != null) 'company': company!.toJson(),
      if (department != null) 'department': department!.toJson(),
      if (position != null) 'position': position!.toJson(),
      'photoUrl': photoUrl,
    };
  }

  String get fullName {
    final list = [firstName, lastName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim());
    return list.isNotEmpty ? list.join(' ') : 'Pengurus HR';
  }

  String get initials {
    final parts = fullName.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'HR';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get positionAndDeptLabel {
    final pos = position?.name ?? '';
    final dept = department?.name ?? '';
    if (pos.isNotEmpty && dept.isNotEmpty) {
      return '$pos • $dept';
    }
    return pos.isNotEmpty ? pos : dept;
  }

  String get companyAndEmpNoLabel {
    final comp = company?.name ?? '';
    final empNo = employeeNumber ?? '';
    if (comp.isNotEmpty && empNo.isNotEmpty) {
      return '$comp • $empNo';
    }
    return comp.isNotEmpty ? comp : empNo;
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        idNumber,
        employeeNumber,
        company,
        department,
        position,
        photoUrl,
      ];
}

/// DTO Organisasi (Company, Department, Position)
class AnnouncementOrgItem extends Equatable {
  final String id;
  final String name;
  final String? code;

  const AnnouncementOrgItem({
    required this.id,
    required this.name,
    this.code,
  });

  factory AnnouncementOrgItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementOrgItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  @override
  List<Object?> get props => [id, name, code];
}

/// Response payload dari `GET /api/v1/announcement/{id}`
class AnnouncementDetailResponse extends Equatable {
  final bool success;
  final String message;
  final AnnouncementDetailModel data;

  const AnnouncementDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AnnouncementDetailResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementDetailResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: AnnouncementDetailModel.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Response data payload dari `POST /api/v1/announcement/{id}/acknowledge`
class AnnouncementAcknowledgeData extends Equatable {
  final String? message;
  final String? acknowledgedAt;

  const AnnouncementAcknowledgeData({
    this.message,
    this.acknowledgedAt,
  });

  factory AnnouncementAcknowledgeData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnnouncementAcknowledgeData();
    return AnnouncementAcknowledgeData(
      message: json['message']?.toString(),
      acknowledgedAt: json['acknowledgedAt']?.toString(),
    );
  }

  @override
  List<Object?> get props => [message, acknowledgedAt];
}

/// Response payload dari `POST /api/v1/announcement/{id}/acknowledge`
class AnnouncementAcknowledgeResponse extends Equatable {
  final bool success;
  final String message;
  final AnnouncementAcknowledgeData data;

  const AnnouncementAcknowledgeResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AnnouncementAcknowledgeResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementAcknowledgeResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: AnnouncementAcknowledgeData.fromJson(
        json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : null,
      ),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
