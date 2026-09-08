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
  String? activityTypeName,
  ActivityItem? existingItem,
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
  final levelMap = empMap?['level'] is Map<String, dynamic>
      ? empMap!['level'] as Map<String, dynamic>
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
  final displayName = fullName.isNotEmpty
      ? fullName
      : (existingItem?.userName ?? (isMyActivity ? 'Saya' : 'Pegawai'));

  // Role & Departemen & Perusahaan & Level
  final role = posMap?['name']?.toString() ?? existingItem?.userRole ?? 'Staff';
  final department =
      deptMap?['name']?.toString() ?? existingItem?.department ?? 'Umum';
  final company = compMap?['name']?.toString() ??
      existingItem?.company ??
      'PT Oasish Tech Nusantara';
  final userLevel = levelMap?['name']?.toString() ?? existingItem?.userLevel;
  final userEmail = empMap?['email']?.toString() ?? existingItem?.userEmail;
  final employeeNumber =
      empMap?['employeeNumber']?.toString() ?? existingItem?.employeeNumber;

  // Waktu & Tanggal
  DateTime? parseDate(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    return DateTime.tryParse(str)?.toLocal();
  }

  final parsedStartTime =
      parseDate(json['startTime']) ?? existingItem?.startTime;
  final parsedEndTime = parseDate(json['endTime']) ?? existingItem?.endTime;
  final parsedCreatedAt =
      parseDate(json['createdAt']) ?? existingItem?.createdAt;
  final parsedUpdatedAt =
      parseDate(json['updatedAt']) ?? existingItem?.updatedAt;

  final effectiveDate = parsedStartTime ??
      parsedCreatedAt ??
      existingItem?.date ??
      DateTime.now();
  final h = effectiveDate.hour.toString().padLeft(2, '0');
  final m = effectiveDate.minute.toString().padLeft(2, '0');
  final timeFormatted = (parsedStartTime != null || parsedCreatedAt != null)
      ? '$h:$m'
      : (existingItem?.time ?? '$h:$m');

  // Status mapping sesuai StatusEmployeeActivity: planned, ongoing, completed, canceled
  final rawStatus = json['status']?.toString().toLowerCase().trim() ??
      existingItem?.rawStatus ??
      '';
  ActivityStatus status = existingItem?.status ?? ActivityStatus.ongoing;
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
  } else if (rawStatus.contains('on') || rawStatus.contains('prog')) {
    status = ActivityStatus.ongoing;
  }

  // Activity Type & Title
  final actTypeName = activityTypeName ??
      actTypeMap?['name']?.toString() ??
      existingItem?.category;
  final actTypeCode = actTypeMap?['code']?.toString();
  final description =
      json['description']?.toString() ?? existingItem?.description ?? '';
  final title = actTypeName != null && actTypeName.isNotEmpty
      ? actTypeName
      : (existingItem?.title != null &&
              existingItem!.title.isNotEmpty &&
              existingItem.title != existingItem.description
          ? existingItem.title
          : (description.isNotEmpty ? description : 'Aktivitas Harian'));

  // Initials
  String initials = 'AC';
  final parts =
      displayName.split(' ').where((p) => p.trim().isNotEmpty).toList();
  if (parts.length >= 2) {
    initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
    initials =
        parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  } else if (existingItem != null) {
    initials = existingItem.initials;
  }

  final locationName = json['locationName']?.toString();
  final empId = json['employeeId']?.toString() ??
      empMap?['id']?.toString() ??
      existingItem?.employeeId;
  final actTypeId = json['activityTypeId']?.toString() ??
      actTypeMap?['id']?.toString() ??
      existingItem?.activityTypeId;

  final effectiveIsMyActivity = isMyActivity ||
      (currentEmployeeId != null &&
          empId != null &&
          currentEmployeeId.trim() == empId.trim());

  final double lat = (json['latitude'] as num?)?.toDouble() ??
      existingItem?.latitude ??
      -6.2253;
  final double lng = (json['longitude'] as num?)?.toDouble() ??
      existingItem?.longitude ??
      106.8097;

  return ActivityItem(
    id: json['id']?.toString() ??
        existingItem?.id ??
        'ACT-${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    description: description,
    userName: displayName,
    userRole: role,
    department: department,
    company: company,
    avatarUrl: resolveFileUrl(empMap?['photoUrl']?.toString()) ??
        existingItem?.avatarUrl,
    initials: initials,
    status: status,
    location: locationName != null && locationName.isNotEmpty
        ? locationName
        : (existingItem?.location ?? 'Kantor / Lokasi Kerja'),
    time: timeFormatted,
    date: effectiveDate,
    isMyActivity: effectiveIsMyActivity,
    category: actTypeCode ?? actTypeName,
    employeeId: empId,
    activityTypeId: actTypeId,
    filePath: resolveFileUrl(json['filePath']?.toString()) ??
        existingItem?.filePath,
    filePath2: resolveFileUrl(json['filePath2']?.toString()) ??
        existingItem?.filePath2,
    notes: json['notes']?.toString() ?? existingItem?.notes,
    startTime: parsedStartTime,
    endTime: parsedEndTime,
    createdAt: parsedCreatedAt,
    updatedAt: parsedUpdatedAt,
    rawStatus: rawStatus,
    userEmail: userEmail,
    employeeNumber: employeeNumber,
    userLevel: userLevel,
    latitude: lat,
    longitude: lng,
    fullAddress: existingItem?.fullAddress ??
        (locationName != null && locationName.isNotEmpty
            ? locationName
            : 'SCBD Lot 28, Jl. Jend. Sudirman Kav. 52-53'),
    districtCity: existingItem?.districtCity ??
        'Kec. Kebayoran Baru, Kota Jakarta Selatan, DKI Jakarta 12190',
    gpsAccuracy: existingItem?.gpsAccuracy ?? '±3m',
    isGpsVerified: existingItem?.isGpsVerified ?? true,
    phases: existingItem?.phases,
  );
}

/// Model item organisasi (Company, Department, Position, Level) pada aktivitas.
class ActivityOrgItem {
  final String id;
  final String name;

  const ActivityOrgItem({
    required this.id,
    required this.name,
  });

  factory ActivityOrgItem.fromJson(Map<String, dynamic> json) {
    return ActivityOrgItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// Model data detail karyawan pada respons aktivitas.
class ActivityEmployeeDetail {
  final String id;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? photoUrl;
  final String? employeeNumber;
  final ActivityOrgItem? company;
  final ActivityOrgItem? department;
  final ActivityOrgItem? position;
  final ActivityOrgItem? level;

  const ActivityEmployeeDetail({
    required this.id,
    this.userId,
    required this.firstName,
    this.lastName,
    this.email,
    this.photoUrl,
    this.employeeNumber,
    this.company,
    this.department,
    this.position,
    this.level,
  });

  String get fullName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return firstName.trim();
  }

  factory ActivityEmployeeDetail.fromJson(Map<String, dynamic> json) {
    return ActivityEmployeeDetail(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? ActivityOrgItem.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? ActivityOrgItem.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? ActivityOrgItem.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      level: json['level'] is Map<String, dynamic>
          ? ActivityOrgItem.fromJson(json['level'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'photoUrl': photoUrl,
      'employeeNumber': employeeNumber,
      'company': company?.toJson(),
      'department': department?.toJson(),
      'position': position?.toJson(),
      'level': level?.toJson(),
    };
  }
}

/// Model objek `data` dari respons `GET /activity/{id}`.
class ActivityDetailData {
  final String id;
  final String employeeId;
  final String activityTypeId;
  final String? locationName;
  final DateTime? startTime;
  final DateTime? endTime;
  final String description;
  final String status;
  final String? filePath;
  final String? filePath2;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ActivityEmployeeDetail? employee;
  final Map<String, dynamic> rawJson;

  const ActivityDetailData({
    required this.id,
    required this.employeeId,
    required this.activityTypeId,
    this.locationName,
    this.startTime,
    this.endTime,
    required this.description,
    required this.status,
    this.filePath,
    this.filePath2,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.employee,
    this.rawJson = const {},
  });

  factory ActivityDetailData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    return ActivityDetailData(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      activityTypeId: json['activityTypeId']?.toString() ?? '',
      locationName: json['locationName']?.toString(),
      startTime: parseDate(json['startTime']),
      endTime: parseDate(json['endTime']),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ongoing',
      filePath: json['filePath']?.toString(),
      filePath2: json['filePath2']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      employee: json['employee'] is Map<String, dynamic>
          ? ActivityEmployeeDetail.fromJson(
              json['employee'] as Map<String, dynamic>)
          : null,
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'activityTypeId': activityTypeId,
      'locationName': locationName,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'description': description,
      'status': status,
      'filePath': filePath,
      'filePath2': filePath2,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'employee': employee?.toJson(),
    };
  }

  /// Mengonversi detail data ke model [ActivityItem]
  ActivityItem toActivityItem({
    bool isMyActivity = false,
    String? currentEmployeeId,
    String? activityTypeName,
    ActivityItem? existingItem,
  }) {
    return activityItemFromApiJson(
      rawJson.isNotEmpty ? rawJson : toJson(),
      isMyActivity: isMyActivity,
      currentEmployeeId: currentEmployeeId,
      activityTypeName: activityTypeName,
      existingItem: existingItem,
    );
  }
}

/// Model pembungkus respons dari `GET /activity/{id}`
class ActivityDetailResponse {
  final bool success;
  final String message;
  final ActivityDetailData data;
  final Map<String, dynamic> rawData;

  const ActivityDetailResponse._internal({
    required this.success,
    required this.message,
    required this.data,
    required this.rawData,
  });

  /// Factory constructor fleksibel untuk mendukung objek [ActivityDetailData]
  /// ataupun Map JSON mock (seperti pada unit test).
  factory ActivityDetailResponse({
    required bool success,
    required String message,
    required dynamic data,
    Map<String, dynamic>? rawData,
  }) {
    ActivityDetailData detailData;
    Map<String, dynamic> raw;

    if (data is ActivityDetailData) {
      detailData = data;
      raw = rawData ?? data.toJson();
    } else if (data is Map<String, dynamic>) {
      detailData = ActivityDetailData.fromJson(data);
      raw = data;
    } else {
      detailData = ActivityDetailData.fromJson(const {});
      raw = const {};
    }

    return ActivityDetailResponse._internal(
      success: success,
      message: message,
      data: detailData,
      rawData: raw,
    );
  }

  factory ActivityDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ActivityDetailResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: ActivityDetailData.fromJson(rawData),
      rawData: rawData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }

  /// Mengonversi detail data JSON ke model [ActivityItem]
  ActivityItem toActivityItem({
    bool isMyActivity = false,
    String? currentEmployeeId,
    String? activityTypeName,
    ActivityItem? existingItem,
  }) {
    return data.toActivityItem(
      isMyActivity: isMyActivity,
      currentEmployeeId: currentEmployeeId,
      activityTypeName: activityTypeName,
      existingItem: existingItem,
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
