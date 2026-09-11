import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;

/// Model representasi item organisasi (perusahaan/departemen/posisi) pada detail leave.
class LeaveOrgItemModel extends Equatable {
  final String id;
  final String name;
  final String? code;

  const LeaveOrgItemModel({
    required this.id,
    required this.name,
    this.code,
  });

  factory LeaveOrgItemModel.fromJson(Map<String, dynamic> json) {
    return LeaveOrgItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (code != null) 'code': code,
      };

  @override
  List<Object?> get props => [id, name, code];
}

/// Model jenis cuti pada respons detail cuti.
class LeaveTypeDetailModel extends Equatable {
  final String id;
  final String name;

  const LeaveTypeDetailModel({
    required this.id,
    required this.name,
  });

  factory LeaveTypeDetailModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeDetailModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  List<Object?> get props => [id, name];
}

/// Model data karyawan pengaju pada detail cuti.
class LeaveEmployeeDetailModel extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? idNumber;
  final String? employeeNumber;
  final LeaveOrgItemModel? company;
  final LeaveOrgItemModel? department;
  final LeaveOrgItemModel? position;
  final String? photoUrl;

  const LeaveEmployeeDetailModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email = '',
    this.phone,
    this.idNumber,
    this.employeeNumber,
    this.company,
    this.department,
    this.position,
    this.photoUrl,
  });

  factory LeaveEmployeeDetailModel.fromJson(Map<String, dynamic> json) {
    return LeaveEmployeeDetailModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      idNumber: json['idNumber']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? LeaveOrgItemModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? LeaveOrgItemModel.fromJson(
              json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? LeaveOrgItemModel.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'idNumber': idNumber,
        'employeeNumber': employeeNumber,
        'company': company?.toJson(),
        'department': department?.toJson(),
        'position': position?.toJson(),
        'photoUrl': photoUrl,
      };

  String get fullName {
    final last = lastName?.trim() ?? '';
    return last.isNotEmpty ? '${firstName.trim()} $last' : firstName.trim();
  }

  String get initials {
    final name = fullName;
    final parts = name.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '?';
  }

  String? get resolvedAvatarUrl => resolveFileUrl(photoUrl);

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

/// Model data approver (bisa null jika pengajuan belum/tidak memiliki approver).
class LeaveApproverDetailModel extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? idNumber;
  final String? employeeNumber;
  final LeaveOrgItemModel? company;
  final LeaveOrgItemModel? department;
  final LeaveOrgItemModel? position;
  final String? photoUrl;

  const LeaveApproverDetailModel({
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

  factory LeaveApproverDetailModel.fromJson(Map<String, dynamic> json) {
    return LeaveApproverDetailModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      idNumber: json['idNumber']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? LeaveOrgItemModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? LeaveOrgItemModel.fromJson(
              json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? LeaveOrgItemModel.fromJson(json['position'] as Map<String, dynamic>)
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'idNumber': idNumber,
        'employeeNumber': employeeNumber,
        'company': company?.toJson(),
        'department': department?.toJson(),
        'position': position?.toJson(),
        'photoUrl': photoUrl,
      };

  String get fullName {
    final last = lastName?.trim() ?? '';
    return last.isNotEmpty ? '${firstName.trim()} $last' : firstName.trim();
  }

  String get initials {
    final name = fullName;
    final parts = name.split(' ').where((p) => p.trim().isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '?';
  }

  String? get resolvedAvatarUrl => resolveFileUrl(photoUrl);

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

/// Model inti entitas data pengajuan cuti lengkap dari `GET /leave-request/{id}`.
class LeaveRequestDetailData extends Equatable {
  final String id;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalDays;
  final String? notes;
  final String status;
  final LeaveTypeDetailModel leaveType;
  final LeaveEmployeeDetailModel employee;
  final LeaveApproverDetailModel? approver;
  final String? filePath;
  final String? approverNotes;

  const LeaveRequestDetailData({
    required this.id,
    this.startDate,
    this.endDate,
    this.totalDays = 1,
    this.notes,
    required this.status,
    required this.leaveType,
    required this.employee,
    this.approver,
    this.filePath,
    this.approverNotes,
  });

  factory LeaveRequestDetailData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    return LeaveRequestDetailData(
      id: json['id']?.toString() ?? '',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 1,
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'requested',
      leaveType: LeaveTypeDetailModel.fromJson(
        (json['leaveType'] as Map<String, dynamic>?) ?? {},
      ),
      employee: LeaveEmployeeDetailModel.fromJson(
        (json['employee'] as Map<String, dynamic>?) ?? {},
      ),
      approver: json['approver'] is Map<String, dynamic>
          ? LeaveApproverDetailModel.fromJson(
              json['approver'] as Map<String, dynamic>)
          : null,
      filePath: json['filePath']?.toString(),
      approverNotes: json['approverNotes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate?.toIso8601String().substring(0, 10),
        'endDate': endDate?.toIso8601String().substring(0, 10),
        'totalDays': totalDays,
        'notes': notes,
        'status': status,
        'leaveType': leaveType.toJson(),
        'employee': employee.toJson(),
        'approver': approver?.toJson(),
        'filePath': filePath,
        'approverNotes': approverNotes,
      };

  LeaveRequestDetailData copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    String? notes,
    String? status,
    LeaveTypeDetailModel? leaveType,
    LeaveEmployeeDetailModel? employee,
    LeaveApproverDetailModel? approver,
    bool clearApprover = false,
    String? filePath,
    bool clearFilePath = false,
    String? approverNotes,
    bool clearApproverNotes = false,
  }) {
    return LeaveRequestDetailData(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      leaveType: leaveType ?? this.leaveType,
      employee: employee ?? this.employee,
      approver: clearApprover ? null : (approver ?? this.approver),
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      approverNotes: clearApproverNotes
          ? null
          : (approverNotes ?? this.approverNotes),
    );
  }

  String? get resolvedFilePath => resolveFileUrl(filePath);

  bool get isPending {
    final s = status.toLowerCase();
    return s == 'requested' || s == 'pending';
  }

  bool get isApproved {
    return status.toLowerCase() == 'approved';
  }

  bool get isRejected {
    return status.toLowerCase() == 'rejected';
  }

  String get statusLabel {
    if (isApproved) return 'Approved';
    if (isRejected) return 'Rejected';
    return 'Pending Approval';
  }

  String get durationLabel =>
      totalDays == 1 ? '1 Work Day(s)' : '$totalDays Work Day(s)';

  static const List<String> _months = [
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

  /// Format tanggal sesuai desain Stitch (misal: "28 Agustus 2026"
  /// atau "28 Agustus 2026 - 30 Agustus 2026").
  String get formattedDateRange {
    final start = startDate;
    final end = endDate;
    if (start == null && end == null) return '-';

    String fmt(DateTime d) =>
        '${d.day} ${_months[d.month - 1]} ${d.year}';

    if (start == null) return fmt(end!);
    if (end == null) return fmt(start);

    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    return sameDay ? fmt(start) : '${fmt(start)} - ${fmt(end)}';
  }

  @override
  List<Object?> get props => [
        id,
        startDate,
        endDate,
        totalDays,
        notes,
        status,
        leaveType,
        employee,
        approver,
        filePath,
        approverNotes,
      ];
}

/// Model pembungkus respons dari `GET /leave-request/{id}`.
class LeaveRequestDetailResponse extends Equatable {
  final bool success;
  final String message;
  final LeaveRequestDetailData data;

  const LeaveRequestDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory LeaveRequestDetailResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestDetailResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: LeaveRequestDetailData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data.toJson(),
      };

  @override
  List<Object?> get props => [success, message, data];
}
