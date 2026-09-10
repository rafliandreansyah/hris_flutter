import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';

/// Metadata paginasi respons dari endpoint `/leave-request`.
class LeavePaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const LeavePaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory LeavePaginationMeta.fromJson(Map<String, dynamic> json) {
    return LeavePaginationMeta(
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

/// Objek perusahaan pada entitas leave request.
class LeaveCompanyModel {
  final String id;
  final String name;

  const LeaveCompanyModel({required this.id, required this.name});

  factory LeaveCompanyModel.fromJson(Map<String, dynamic> json) {
    return LeaveCompanyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Objek departemen pada entitas leave request.
class LeaveDepartmentModel {
  final String id;
  final String name;

  const LeaveDepartmentModel({required this.id, required this.name});

  factory LeaveDepartmentModel.fromJson(Map<String, dynamic> json) {
    return LeaveDepartmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Objek jabatan/posisi pada entitas leave request.
class LeavePositionModel {
  final String id;
  final String name;

  const LeavePositionModel({required this.id, required this.name});

  factory LeavePositionModel.fromJson(Map<String, dynamic> json) {
    return LeavePositionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Objek jenis cuti (`leaveType`) pada entitas leave request.
class LeaveTypeModel {
  final String id;
  final String name;

  const LeaveTypeModel({required this.id, required this.name});

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Data pegawai lengkap pada entitas leave request.
class LeaveEmployeeModel {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? idNumber;
  final String? employeeNumber;
  final LeaveCompanyModel? company;
  final LeaveDepartmentModel? department;
  final LeavePositionModel? position;
  final String? photoUrl;

  const LeaveEmployeeModel({
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

  factory LeaveEmployeeModel.fromJson(Map<String, dynamic> json) {
    return LeaveEmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      idNumber: json['idNumber']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? LeaveCompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? LeaveDepartmentModel.fromJson(
              json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? LeavePositionModel.fromJson(json['position'] as Map<String, dynamic>)
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

/// Model entitas API dari satu pengajuan cuti/izin.
class LeaveRequestApiModel {
  final String id;
  final LeaveEmployeeModel? employee;
  final LeaveTypeModel? leaveType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int days;
  final String note;
  final String statusApprove;
  final String? timezone;

  const LeaveRequestApiModel({
    required this.id,
    this.employee,
    this.leaveType,
    this.startDate,
    this.endDate,
    this.days = 1,
    this.note = '',
    this.statusApprove = '',
    this.timezone,
  });

  factory LeaveRequestApiModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    return LeaveRequestApiModel(
      id: json['id']?.toString() ?? '',
      employee: json['employee'] is Map<String, dynamic>
          ? LeaveEmployeeModel.fromJson(json['employee'] as Map<String, dynamic>)
          : null,
      leaveType: json['leaveType'] is Map<String, dynamic>
          ? LeaveTypeModel.fromJson(json['leaveType'] as Map<String, dynamic>)
          : null,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      days: (json['days'] as num?)?.toInt() ?? 1,
      note: json['note']?.toString() ?? json['reason']?.toString() ?? '',
      statusApprove: json['statusApprove']?.toString() ?? '',
      timezone: json['timezone']?.toString(),
    );
  }
}

/// Pembungkus respons API dari endpoint `/leave-request`.
class LeaveRequestListResponse {
  final bool success;
  final String message;
  final List<LeaveRequestItem> data;
  final LeavePaginationMeta meta;

  const LeaveRequestListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory LeaveRequestListResponse.fromJson(
    Map<String, dynamic> json, {
    bool isApprover = false,
  }) {
    final rawList = json['data'] is List ? json['data'] as List : [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => leaveRequestItemFromApiJson(item, isApprover: isApprover))
        .toList();

    final metaMap = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : <String, dynamic>{};

    return LeaveRequestListResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: LeavePaginationMeta.fromJson(metaMap),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.map((e) => {'id': e.id}).toList(),
        'meta': meta.toJson(),
      };
}

/// Helper mengonversi JSON API leave-request menjadi [LeaveRequestItem]
/// siap render. [isApprover] menandai tab: `true` = Team Requests (pegawai
/// lain), `false` = My Requests (pengajuan milik sendiri).
LeaveRequestItem leaveRequestItemFromApiJson(
  Map<String, dynamic> json, {
  bool isApprover = false,
}) {
  final model = LeaveRequestApiModel.fromJson(json);
  final emp = model.employee;

  // Nama: dari data pegawai; tab My Requests fallback 'Saya'.
  final name = emp != null && emp.fullName.trim().isNotEmpty
      ? emp.fullName.trim()
      : (isApprover ? 'Pegawai' : 'Saya');

  // Status mapping dari field `statusApprove` backend.
  final rawStatus = model.statusApprove.toLowerCase().trim();
  LeaveStatus status;
  if (rawStatus.contains('approv') || rawStatus.contains('terima')) {
    status = LeaveStatus.approved;
  } else if (rawStatus.contains('reject') || rawStatus.contains('tolak')) {
    status = LeaveStatus.rejected;
  } else if (rawStatus.contains('request')) {
    status = LeaveStatus.requested;
  } else {
    status = LeaveStatus.pending;
  }

  return LeaveRequestItem(
    id: model.id,
    employeeId: emp?.id ?? '',
    name: name,
    role: emp?.position?.name ?? 'Staff',
    department: emp?.department?.name ?? 'Umum',
    company: emp?.company?.name ?? '',
    employeeNumber: emp?.employeeNumber,
    avatarUrl: resolveFileUrl(emp?.photoUrl),
    initials: emp?.initials ?? '?',
    leaveType: model.leaveType?.name ?? 'Leave',
    days: model.days,
    startDate: model.startDate,
    endDate: model.endDate,
    note: model.note,
    status: status,
    timezone: model.timezone ?? 'WIB',
    isSelf: !isApprover,
  );
}
