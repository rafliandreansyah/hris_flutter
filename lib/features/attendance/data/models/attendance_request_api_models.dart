import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';

/// Metadata paginasi respons dari endpoint `/attendances/requests`.
class AttendanceRequestPaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AttendanceRequestPaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory AttendanceRequestPaginationMeta.fromJson(Map<String, dynamic> json) {
    return AttendanceRequestPaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ??
          (json['size'] as num?)?.toInt() ??
          20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ??
          (json['totalPage'] as num?)?.toInt() ??
          1,
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
      };
}

/// Objek perusahaan pada pengajuan presensi.
class AttendanceRequestCompanyModel {
  final String id;
  final String name;

  const AttendanceRequestCompanyModel({required this.id, required this.name});

  factory AttendanceRequestCompanyModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRequestCompanyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Objek departemen pada pengajuan presensi.
class AttendanceRequestDepartmentModel {
  final String id;
  final String name;

  const AttendanceRequestDepartmentModel({required this.id, required this.name});

  factory AttendanceRequestDepartmentModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRequestDepartmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Objek jabatan/posisi pada pengajuan presensi.
class AttendanceRequestPositionModel {
  final String id;
  final String name;

  const AttendanceRequestPositionModel({required this.id, required this.name});

  factory AttendanceRequestPositionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRequestPositionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// Model pegawai pada pengajuan presensi.
class AttendanceRequestEmployeeModel {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? employeeNumber;
  final AttendanceRequestCompanyModel? company;
  final AttendanceRequestDepartmentModel? department;
  final AttendanceRequestPositionModel? position;
  final String? photoUrl;

  const AttendanceRequestEmployeeModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.employeeNumber,
    this.company,
    this.department,
    this.position,
    this.photoUrl,
  });

  factory AttendanceRequestEmployeeModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRequestEmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ??
          json['name']?.toString() ??
          '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? AttendanceRequestCompanyModel.fromJson(
              json['company'] as Map<String, dynamic>)
          : (json['company'] is String
              ? AttendanceRequestCompanyModel(
                  id: '', name: json['company'].toString())
              : null),
      department: json['department'] is Map<String, dynamic>
          ? AttendanceRequestDepartmentModel.fromJson(
              json['department'] as Map<String, dynamic>)
          : (json['department'] is String
              ? AttendanceRequestDepartmentModel(
                  id: '', name: json['department'].toString())
              : null),
      position: json['position'] is Map<String, dynamic>
          ? AttendanceRequestPositionModel.fromJson(
              json['position'] as Map<String, dynamic>)
          : (json['position'] is String
              ? AttendanceRequestPositionModel(
                  id: '', name: json['position'].toString())
              : null),
      photoUrl: resolveFileUrl(json['photoUrl']?.toString()),
    );
  }

  String get fullName {
    final last = lastName?.trim() ?? '';
    return last.isNotEmpty ? '${firstName.trim()} $last' : firstName.trim();
  }

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

/// Model data API tunggal dari endpoint `/attendances/requests`.
class AttendanceRequestApiModel {
  final String id;
  final AttendanceRequestEmployeeModel? employee;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? workHours;
  final String notes;
  final String status;
  final DateTime? createdAt;
  final String? attendanceType;
  final String? approverNotes;

  const AttendanceRequestApiModel({
    required this.id,
    this.employee,
    this.date,
    this.startTime,
    this.endTime,
    this.workHours,
    this.notes = '',
    this.status = '',
    this.createdAt,
    this.attendanceType,
    this.approverNotes,
  });

  factory AttendanceRequestApiModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    String? parseTime(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      // Jika format ISO datetime, ambil jam:menit
      if (str.contains('T') || str.contains(' ')) {
        final dt = DateTime.tryParse(str);
        if (dt != null) {
          final h = dt.hour.toString().padLeft(2, '0');
          final m = dt.minute.toString().padLeft(2, '0');
          return '$h:$m';
        }
      }
      return str;
    }

    return AttendanceRequestApiModel(
      id: json['id']?.toString() ?? '',
      employee: json['employee'] is Map<String, dynamic>
          ? AttendanceRequestEmployeeModel.fromJson(
              json['employee'] as Map<String, dynamic>)
          : null,
      date: parseDate(json['date'] ??
          json['attendanceDate'] ??
          json['startDate'] ??
          json['workDate']),
      startTime: parseTime(json['startTime'] ?? json['start_time'] ?? json['clockIn'] ?? json['checkInTime']),
      endTime: parseTime(json['endTime'] ?? json['end_time'] ?? json['clockOut'] ?? json['checkOutTime']),
      workHours: json['workHours']?.toString() ?? json['shiftHours']?.toString(),
      notes: json['notes']?.toString() ??
          json['reason']?.toString() ??
          json['description']?.toString() ??
          json['note']?.toString() ??
          '',
      status: json['status']?.toString() ?? json['statusApprove']?.toString() ?? '',
      createdAt: parseDate(json['createdAt'] ?? json['created_at'] ?? json['submittedAt']),
      attendanceType: json['type']?.toString() ?? json['attendanceType']?.toString(),
      approverNotes: json['approverNotes']?.toString() ?? json['approver_note']?.toString(),
    );
  }
}

/// Pembungkus respons list API dari endpoint `/attendances/requests`.
class AttendanceRequestListResponse {
  final bool success;
  final String message;
  final List<AttendanceRequestItem> data;
  final AttendanceRequestPaginationMeta meta;

  const AttendanceRequestListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory AttendanceRequestListResponse.fromJson(
    Map<String, dynamic> json, {
    bool isApprover = false,
  }) {
    final rawList = json['data'] is List ? json['data'] as List : [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => attendanceRequestItemFromApiJson(item, isApprover: isApprover))
        .toList();

    final metaMap = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : (json['pagination'] is Map<String, dynamic>
            ? json['pagination'] as Map<String, dynamic>
            : <String, dynamic>{});

    return AttendanceRequestListResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: items,
      meta: AttendanceRequestPaginationMeta.fromJson(metaMap),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.map((e) => {'id': e.id}).toList(),
        'meta': meta.toJson(),
      };
}

/// Helper mapping JSON response backend ke model [AttendanceRequestItem]
AttendanceRequestItem attendanceRequestItemFromApiJson(
  Map<String, dynamic> json, {
  bool isApprover = false,
}) {
  final model = AttendanceRequestApiModel.fromJson(json);
  final emp = model.employee;

  final name = emp != null && emp.fullName.trim().isNotEmpty
      ? emp.fullName.trim()
      : (isApprover ? 'Pegawai' : 'Saya');

  final rawStatus = model.status.toLowerCase().trim();
  AttendanceRequestStatus status;
  if (rawStatus.contains('approv') || rawStatus.contains('terima') || rawStatus.contains('setuju')) {
    status = AttendanceRequestStatus.approved;
  } else if (rawStatus.contains('reject') || rawStatus.contains('tolak')) {
    status = AttendanceRequestStatus.rejected;
  } else {
    status = AttendanceRequestStatus.requested;
  }

  return AttendanceRequestItem(
    id: model.id,
    employeeId: emp?.id ?? '',
    name: name,
    role: emp?.position?.name ?? '',
    department: emp?.department?.name ?? '',
    company: emp?.company?.name ?? '',
    employeeNumber: emp?.employeeNumber,
    avatarUrl: emp?.photoUrl,
    initials: emp?.initials ?? '?',
    date: model.date,
    startTime: model.startTime,
    endTime: model.endTime,
    workHours: model.workHours,
    notes: model.notes,
    status: status,
    createdAt: model.createdAt,
    isSelf: !isApprover,
    attendanceType: model.attendanceType,
    approverNotes: model.approverNotes,
  );
}
