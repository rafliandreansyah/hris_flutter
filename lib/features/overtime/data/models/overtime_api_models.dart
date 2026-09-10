import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/overtime/presentation/models/overtime_request_item.dart';

/// Metadata paginasi respons dari endpoint `/overtime`.
class OvertimePaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const OvertimePaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory OvertimePaginationMeta.fromJson(Map<String, dynamic> json) {
    return OvertimePaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 30,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
      };
}

/// Objek perusahaan pada entitas overtime request.
class OvertimeCompanyModel {
  final String id;
  final String name;

  const OvertimeCompanyModel({required this.id, required this.name});

  factory OvertimeCompanyModel.fromJson(Map<String, dynamic> json) {
    return OvertimeCompanyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Objek departemen pada entitas overtime request.
class OvertimeDepartmentModel {
  final String id;
  final String name;

  const OvertimeDepartmentModel({required this.id, required this.name});

  factory OvertimeDepartmentModel.fromJson(Map<String, dynamic> json) {
    return OvertimeDepartmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Objek jabatan/posisi pada entitas overtime request.
class OvertimePositionModel {
  final String id;
  final String name;

  const OvertimePositionModel({required this.id, required this.name});

  factory OvertimePositionModel.fromJson(Map<String, dynamic> json) {
    return OvertimePositionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Data pegawai pada entitas overtime request.
class OvertimeEmployeeModel {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? idNumber;
  final String? employeeNumber;
  final OvertimeCompanyModel? company;
  final OvertimeDepartmentModel? department;
  final OvertimePositionModel? position;
  final String? photoUrl;

  const OvertimeEmployeeModel({
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

  factory OvertimeEmployeeModel.fromJson(Map<String, dynamic> json) {
    return OvertimeEmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      idNumber: json['idNumber']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? OvertimeCompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? OvertimeDepartmentModel.fromJson(
              json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? OvertimePositionModel.fromJson(
              json['position'] as Map<String, dynamic>)
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  /// Nama lengkap gabungan firstName + lastName.
  String get fullName {
    final last = lastName?.trim() ?? '';
    return last.isNotEmpty ? '${firstName.trim()} $last' : firstName.trim();
  }

  /// Inisial dua huruf dari nama.
  String get initials {
    final parts = fullName.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0]
          .substring(0, parts[0].length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '?';
  }
}

/// Model entitas API dari satu permintaan lembur (`/overtime`).
class OvertimeApiModel {
  final String id;
  final OvertimeEmployeeModel? employee;
  final DateTime? startOvertime;
  final DateTime? endOvertime;
  final String? notes;
  final String? approverNotes;
  final String? timezone;
  final String status;

  const OvertimeApiModel({
    required this.id,
    this.employee,
    this.startOvertime,
    this.endOvertime,
    this.notes,
    this.approverNotes,
    this.timezone,
    this.status = '',
  });

  factory OvertimeApiModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    return OvertimeApiModel(
      id: json['id']?.toString() ?? '',
      employee: json['employee'] is Map<String, dynamic>
          ? OvertimeEmployeeModel.fromJson(
              json['employee'] as Map<String, dynamic>)
          : null,
      startOvertime: parseDate(json['startOvertime']),
      endOvertime: parseDate(json['endOvertime']),
      notes: json['notes']?.toString(),
      approverNotes: json['approverNotes']?.toString(),
      timezone: json['timezone']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Pembungkus respons API dari endpoint `/overtime`.
class OvertimeRequestListResponse {
  final bool success;
  final String message;
  final List<OvertimeRequestItem> data;
  final OvertimePaginationMeta meta;

  const OvertimeRequestListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory OvertimeRequestListResponse.fromJson(
    Map<String, dynamic> json, {
    bool isApprover = false,
  }) {
    final rawList = json['data'] is List ? json['data'] as List : [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => overtimeRequestItemFromApiJson(item, isApprover: isApprover))
        .toList();

    final metaMap = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return OvertimeRequestListResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: OvertimePaginationMeta.fromJson(metaMap),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.map((e) => {'id': e.id}).toList(),
        'meta': meta.toJson(),
      };
}

/// Helper mengonversi JSON API overtime menjadi [OvertimeRequestItem]
/// siap render. [isApprover] menandai tab: `true` = Team Overtime (pegawai
/// lain, `approver=true`), `false` = My Overtime (permintaan milik sendiri).
OvertimeRequestItem overtimeRequestItemFromApiJson(
  Map<String, dynamic> json, {
  bool isApprover = false,
}) {
  final model = OvertimeApiModel.fromJson(json);
  final emp = model.employee;

  // Nama: dari data pegawai; tab My Overtime fallback 'Saya'.
  final name = emp != null && emp.fullName.trim().isNotEmpty
      ? emp.fullName.trim()
      : (isApprover ? 'Pegawai' : 'Saya');

  // Status mapping dari field `status` backend ("requested", "approved",
  // "rejected", dst).
  final rawStatus = model.status.toLowerCase().trim();
  OvertimeStatus status;
  if (rawStatus.contains('approv') || rawStatus.contains('terima')) {
    status = OvertimeStatus.approved;
  } else if (rawStatus.contains('reject') || rawStatus.contains('tolak')) {
    status = OvertimeStatus.rejected;
  } else if (rawStatus.contains('request')) {
    status = OvertimeStatus.requested;
  } else {
    status = OvertimeStatus.pending;
  }

  return OvertimeRequestItem(
    id: model.id,
    employeeId: emp?.id ?? '',
    name: name,
    role: emp?.position?.name ?? 'Staff',
    department: emp?.department?.name ?? 'Umum',
    company: emp?.company?.name ?? '',
    employeeNumber: emp?.employeeNumber,
    avatarUrl: resolveFileUrl(emp?.photoUrl),
    initials: emp?.initials ?? '?',
    startTime: model.startOvertime,
    endTime: model.endOvertime,
    note: model.notes ?? '',
    approverNotes: model.approverNotes ?? '',
    status: status,
    timezone: model.timezone ?? 'WIB',
    isSelf: !isApprover,
  );
}
