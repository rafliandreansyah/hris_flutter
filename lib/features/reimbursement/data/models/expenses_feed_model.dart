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
  final String firstName;
  final String? lastName;
  final String email;
  final String? photoUrl;
  final String? jobPosition;
  final String? department;
  final String? company;

  const ExpenseEmployeeModel({
    required this.id,
    this.employeeId,
    required this.firstName,
    this.lastName,
    required this.email,
    this.photoUrl,
    this.jobPosition,
    this.department,
    this.company,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) return firstName;
    return '$firstName $lastName'.trim();
  }

  String? get resolvedPhotoUrl => resolveFileUrl(photoUrl);
  String? get position => jobPosition;

  factory ExpenseEmployeeModel.fromJson(Map<String, dynamic> json) {
    return ExpenseEmployeeModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? json['employee_id']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      email: json['email']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      jobPosition: json['jobPosition']?.toString(),
      department: json['department']?.toString(),
      company: json['company']?.toString(),
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
      employee: ExpenseEmployeeModel.fromJson(
        json['employee'] is Map<String, dynamic>
            ? json['employee'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
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
