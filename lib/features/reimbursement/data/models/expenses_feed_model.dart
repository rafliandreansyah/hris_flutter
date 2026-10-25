import 'package:hris_flutter/core/utils/level_name_util.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;

/// Model metadata paginasi untuk feed pengeluaran.
class ExpensesPaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const ExpensesPaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ExpensesPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ExpensesPaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Model pegawai ringkas dalam entitas pengeluaran.
class ExpenseEmployeeModel {
  final String id;
  final String? employeeId;
  final String? employeeNumber;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? jobPosition;
  final String? department;
  final String? company;
  final String? levelName;

  const ExpenseEmployeeModel({
    required this.id,
    this.employeeId,
    this.employeeNumber,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.jobPosition,
    this.department,
    this.company,
    this.levelName,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) return firstName;
    return '$firstName $lastName'.trim();
  }

  String? get resolvedPhotoUrl => resolveFileUrl(photoUrl);
  String? get position => jobPosition;

  /// Mengembalikan nomor induk pegawai resmi (employeeNumber atau employeeId non-DB).
  /// Tidak pernah mengembalikan internal primary key `id`.
  String? get displayEmployeeNumber {
    final num = employeeNumber?.trim();
    if (num != null && num.isNotEmpty) return num;
    final empId = employeeId?.trim();
    if (empId != null &&
        empId.isNotEmpty &&
        empId != id.trim() &&
        !_uuidPattern.hasMatch(empId)) {
      return empId;
    }
    return null;
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

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

  ExpenseEmployeeModel copyWith({
    String? id,
    String? employeeId,
    String? employeeNumber,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? photoUrl,
    String? jobPosition,
    String? department,
    String? company,
    String? levelName,
  }) {
    return ExpenseEmployeeModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      jobPosition: jobPosition ?? this.jobPosition,
      department: department ?? this.department,
      company: company ?? this.company,
      levelName: levelName ?? this.levelName,
    );
  }

  /// Ekstraksi nama dari String maupun Map objek (seperti company/department/position).
  static String? extractName(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    }
    if (value is Map) {
      final name = value['name'] ??
          value['title'] ??
          value['companyName'] ??
          value['departmentName'] ??
          value['positionName'];
      if (name != null) {
        final trimmed = name.toString().trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return null;
  }

  /// Ekstraksi employeeNumber dari berbagai variasi kunci backend.
  static String? extractEmployeeNumber(Map<String, dynamic> json) {
    final raw = json['employeeNumber'] ??
        json['employee_number'] ??
        json['idNumber'] ??
        json['id_number'] ??
        json['nip'] ??
        json['nik'];
    if (raw != null) {
      final str = raw.toString().trim();
      if (str.isNotEmpty) return str;
    }
    final rawEmpId = json['employeeId'] ?? json['employee_id'];
    if (rawEmpId != null) {
      final str = rawEmpId.toString().trim();
      if (str.isNotEmpty &&
          str != json['id']?.toString().trim() &&
          !_uuidPattern.hasMatch(str)) {
        return str;
      }
    }
    return null;
  }

  factory ExpenseEmployeeModel.fromJson(Map<String, dynamic> json) {
    return ExpenseEmployeeModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? json['employee_id']?.toString(),
      employeeNumber: extractEmployeeNumber(json),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      jobPosition: extractName(json['jobPosition']) ??
          extractName(json['position']) ??
          extractName(json['role']),
      department: extractName(json['department']) ??
          extractName(json['departmentName']),
      company: extractName(json['company']) ??
          extractName(json['companyName']) ??
          extractName(json['company_name']),
      levelName: parseLevelName(json['level']),
    );
  }
}

/// Model item transaksi pengeluaran (reimbursement atau kasbon).
class ExpenseFeedItemModel {
  final String id;
  final String referenceNumber;
  final String expenseType; // 'reimbursement' | 'cash_advance'
  final String title;
  final String? description;
  final double requestedAmount;
  final double? approvedAmount;
  final String status;
  final String? disbursementMethod;
  final String? disbursedAt;
  final String createdAt;
  final ExpenseEmployeeModel employee;
  final int itemsCount;
  final String? settlementStatus;

  const ExpenseFeedItemModel({
    required this.id,
    required this.referenceNumber,
    required this.expenseType,
    required this.title,
    this.description,
    required this.requestedAmount,
    this.approvedAmount,
    required this.status,
    this.disbursementMethod,
    this.disbursedAt,
    required this.createdAt,
    required this.employee,
    this.itemsCount = 0,
    this.settlementStatus,
  });

  bool get isReimbursement => expenseType.toLowerCase() == 'reimbursement';
  bool get isCashAdvance => expenseType.toLowerCase() == 'cash_advance';

  factory ExpenseFeedItemModel.fromJson(Map<String, dynamic> json) {
    var emp = ExpenseEmployeeModel.fromJson(
      json['employee'] is Map<String, dynamic>
          ? json['employee'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
    final rootCompany = ExpenseEmployeeModel.extractName(json['company']) ??
        ExpenseEmployeeModel.extractName(json['companyName']);
    if ((emp.company == null || emp.company!.isEmpty) && rootCompany != null) {
      emp = emp.copyWith(company: rootCompany);
    }

    return ExpenseFeedItemModel(
      id: json['id']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      expenseType: json['expenseType']?.toString() ?? 'reimbursement',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      requestedAmount: (json['requestedAmount'] as num?)?.toDouble() ?? 0.0,
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'requested',
      disbursementMethod: json['disbursementMethod']?.toString(),
      disbursedAt: json['disbursedAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      employee: emp,
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      settlementStatus: json['settlementStatus']?.toString(),
    );
  }
}

/// Model respons feed pengeluaran lengkap dengan metadata.
class ExpensesFeedResponseModel {
  final List<ExpenseFeedItemModel> items;
  final ExpensesPaginationMeta meta;

  const ExpensesFeedResponseModel({
    required this.items,
    required this.meta,
  });

  List<ExpenseFeedItemModel> get data => items;

  factory ExpensesFeedResponseModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(ExpenseFeedItemModel.fromJson)
        .toList();

    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};
    final meta = ExpensesPaginationMeta.fromJson(metaJson);

    return ExpensesFeedResponseModel(items: items, meta: meta);
  }
}
