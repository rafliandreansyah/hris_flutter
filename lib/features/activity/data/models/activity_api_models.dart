import 'package:hris_flutter/features/activity/data/models/activity_item.dart';

/// Metadata paginasi respons dari endpoint `/activity`.
class ActivityPaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const ActivityPaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ActivityPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ActivityPaginationMeta(
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
}

/// Pembungkus respons API dari endpoint `/activity`.
class ActivityListResponse {
  final bool success;
  final String message;
  final List<ActivityItem> data;
  final ActivityPaginationMeta meta;

  const ActivityListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory ActivityListResponse.fromJson(
    Map<String, dynamic> json, {
    bool isMyActivity = false,
  }) {
    final rawList = json['data'] is List ? json['data'] as List : [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => activityItemFromApiJson(item, isMyActivity: isMyActivity))
        .toList();

    final metaMap = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ActivityListResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: ActivityPaginationMeta.fromJson(metaMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((e) => {
        'id': e.id,
        'description': e.description,
      }).toList(),
      'meta': meta.toJson(),
    };
  }
}

/// Helper untuk menyelesaikan URL file relatif atau absolut dari backend API.
String? resolveFileUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final trimmed = path.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  // Hapus /api/v1 jika base url memuatnya untuk file statis / uploads
  final cleanBase = 'https://apidev.hroasish.com';
  final normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$cleanBase$normalizedPath';
}

/// Helper untuk mengonversi JSON objek aktivitas API ke model UI [ActivityItem].
ActivityItem activityItemFromApiJson(
  Map<String, dynamic> json, {
  bool isMyActivity = false,
  String? currentEmployeeId,
}) {
  final empMap = json['employee'] is Map<String, dynamic>
      ? json['employee'] as Map<String, dynamic>
      : null;
  final compMap = empMap?['company'] is Map<String, dynamic>
      ? empMap!['company'] as Map<String, dynamic>
      : null;
  final deptMap = empMap?['department'] is Map<String, dynamic>
      ? empMap!['department'] as Map<String, dynamic>
      : null;
  final posMap = empMap?['position'] is Map<String, dynamic>
      ? empMap!['position'] as Map<String, dynamic>
      : null;
  final actTypeMap = json['activityType'] is Map<String, dynamic>
      ? json['activityType'] as Map<String, dynamic>
      : null;

  // Nama Pegawai
  final firstName = empMap?['firstName']?.toString() ?? '';
  final lastName = empMap?['lastName']?.toString();
  final fullName = (lastName != null && lastName.trim().isNotEmpty)
      ? '$firstName $lastName'.trim()
      : firstName.trim();
  final displayName = fullName.isNotEmpty ? fullName : (isMyActivity ? 'Saya' : 'Pegawai');

  // Role & Departemen & Perusahaan
  final role = posMap?['name']?.toString() ?? 'Staff';
  final department = deptMap?['name']?.toString() ?? 'Umum';
  final company = compMap?['name']?.toString() ?? 'PT Oasish Tech Nusantara';

  // Waktu & Tanggal
  final startTimeRaw = json['startTime']?.toString();
  DateTime? parsedStartTime;
  DateTime parsedDate = DateTime.now();
  String timeFormatted = '09:00';
  if (startTimeRaw != null && startTimeRaw.isNotEmpty) {
    final parsed = DateTime.tryParse(startTimeRaw);
    if (parsed != null) {
      parsedStartTime = parsed.toLocal();
      parsedDate = parsedStartTime;
      final h = parsedDate.hour.toString().padLeft(2, '0');
      final m = parsedDate.minute.toString().padLeft(2, '0');
      timeFormatted = '$h:$m';
    }
  }

  final endTimeRaw = json['endTime']?.toString();
  final parsedEndTime =
      (endTimeRaw != null && endTimeRaw.isNotEmpty) ? DateTime.tryParse(endTimeRaw)?.toLocal() : null;

  final updatedAtRaw = json['updatedAt']?.toString();
  final parsedUpdatedAt =
      (updatedAtRaw != null && updatedAtRaw.isNotEmpty) ? DateTime.tryParse(updatedAtRaw)?.toLocal() : null;

  // Status mapping sesuai StatusEmployeeActivity: planned, ongoing, completed, canceled
  final rawStatus = json['status']?.toString().toLowerCase().trim() ?? '';
  ActivityStatus status = ActivityStatus.ongoing;
  if (rawStatus.contains('cancel')) {
    status = ActivityStatus.canceled;
  } else if (rawStatus.contains('comp') ||
      rawStatus.contains('done') ||
      rawStatus.contains('finish') ||
      rawStatus.contains('approved')) {
    status = ActivityStatus.completed;
  } else if (rawStatus.contains('plan')) {
    status = ActivityStatus.planned;
  } else if (rawStatus.contains('pend') || rawStatus.contains('review')) {
    status = ActivityStatus.pendingReview;
  } else {
    status = ActivityStatus.ongoing;
  }

  // Activity Type & Title
  final actTypeName = actTypeMap?['name']?.toString();
  final actTypeCode = actTypeMap?['code']?.toString();
  final description = json['description']?.toString() ?? '';
  final title = actTypeName != null && actTypeName.isNotEmpty
      ? actTypeName
      : (description.isNotEmpty ? description : 'Aktivitas Harian');

  // Initials
  String initials = 'AC';
  final parts = displayName.split(' ').where((p) => p.trim().isNotEmpty).toList();
  if (parts.length >= 2) {
    initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
    initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  final locationName = json['locationName']?.toString();
  final empId = json['employeeId']?.toString() ?? empMap?['id']?.toString();

  final effectiveIsMyActivity = isMyActivity ||
      (currentEmployeeId != null && empId != null && currentEmployeeId == empId);

  return ActivityItem(
    id: json['id']?.toString() ?? 'ACT-${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    description: description,
    userName: displayName,
    userRole: role,
    department: department,
    company: company,
    avatarUrl: resolveFileUrl(empMap?['photoUrl']?.toString()),
    initials: initials,
    status: status,
    location: locationName != null && locationName.isNotEmpty
        ? locationName
        : 'Kantor / Lokasi Kerja',
    time: timeFormatted,
    date: parsedDate,
    isMyActivity: effectiveIsMyActivity,
    category: actTypeCode ?? actTypeName,
    employeeId: empId,
    filePath: resolveFileUrl(json['filePath']?.toString()),
    filePath2: resolveFileUrl(json['filePath2']?.toString()),
    notes: json['notes']?.toString(),
    startTime: parsedStartTime,
    endTime: parsedEndTime,
    updatedAt: parsedUpdatedAt,
    rawStatus: rawStatus,
  );
}

/// Model pembungkus respons dari `GET /activity/{id}`
class ActivityDetailResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> data;

  const ActivityDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ActivityDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ActivityDetailResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: rawData,
    );
  }

  /// Mengonversi detail data JSON ke model [ActivityItem]
  ActivityItem toActivityItem({
    bool isMyActivity = false,
    String? currentEmployeeId,
  }) {
    return activityItemFromApiJson(
      data,
      isMyActivity: isMyActivity,
      currentEmployeeId: currentEmployeeId,
    );
  }
}

/// Model pembungkus respons dari aksi `PATCH /activity/{id}/finish` atau `cancel`
class ActivityActionResponse {
  final bool success;
  final String message;

  const ActivityActionResponse({
    required this.success,
    required this.message,
  });

  factory ActivityActionResponse.fromJson(Map<String, dynamic> json) {
    return ActivityActionResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Model untuk jenis aktivitas dari `GET /activity/types`.
class ActivityTypeModel {
  final String id;
  final String name;
  final String? code;

  const ActivityTypeModel({
    required this.id,
    required this.name,
    this.code,
  });

  factory ActivityTypeModel.fromJson(Map<String, dynamic> json) {
    return ActivityTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
    );
  }
}

/// Pembungkus respons API dari endpoint `GET /activity/types`.
class ActivityTypesResponse {
  final bool success;
  final String message;
  final List<ActivityTypeModel> data;

  const ActivityTypesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ActivityTypesResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] is List ? json['data'] as List : [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => ActivityTypeModel.fromJson(item))
        .toList();

    return ActivityTypesResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: items,
    );
  }
}

/// Pembungkus respons API dari endpoint `POST /activity` (create activity).
class CreateActivityResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> data;

  const CreateActivityResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CreateActivityResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return CreateActivityResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: rawData,
    );
  }

  /// Mengonversi data response ke [ActivityItem].
  ActivityItem toActivityItem({bool isMyActivity = true}) {
    return activityItemFromApiJson(data, isMyActivity: isMyActivity);
  }
}
