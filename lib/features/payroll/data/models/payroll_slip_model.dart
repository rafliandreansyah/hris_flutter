import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';

class PayrollPaginationMeta extends Equatable {
  final int page;
  final int size;
  final int total;
  final int totalPages;

  const PayrollPaginationMeta({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
  });

  factory PayrollPaginationMeta.fromJson(Map<String, dynamic> json) {
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final size = (json['size'] as num?)?.toInt() ?? 10;
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final totalPages = (json['totalPages'] as num?)?.toInt() ??
        (size > 0 ? (total / size).ceil() : 1);

    return PayrollPaginationMeta(
      page: page,
      size: size,
      total: total,
      totalPages: totalPages,
    );
  }

  @override
  List<Object?> get props => [page, size, total, totalPages];
}

class PayrollEmployeeSummaryModel extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? employeeNumber;
  final String? photoUrl;
  final String? department;
  final String? position;

  const PayrollEmployeeSummaryModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.employeeNumber,
    this.photoUrl,
    this.department,
    this.position,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) return firstName;
    return '$firstName $lastName'.trim();
  }

  String? get resolvedPhotoUrl => resolveFileUrl(photoUrl);

  factory PayrollEmployeeSummaryModel.fromJson(Map<String, dynamic> json) {
    return PayrollEmployeeSummaryModel(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      employeeNumber: json['employeeNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'employeeNumber': employeeNumber,
      'photoUrl': photoUrl,
      'department': department,
      'position': position,
    };
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        employeeNumber,
        photoUrl,
        department,
        position,
      ];
}

class PayrollSlipModel extends Equatable {
  final String id;
  final String employeeId;
  final PayrollEmployeeSummaryModel employee;
  final PayrollPeriodModel period;
  final double basicSalary;
  final double? dailySalary;
  final double grossSalary;
  final double deductions;
  final double netSalary;
  final String status;
  final String? payslipUrl;
  final String? paidAt;
  final String createdAt;

  const PayrollSlipModel({
    required this.id,
    required this.employeeId,
    required this.employee,
    required this.period,
    this.basicSalary = 0.0,
    this.dailySalary,
    required this.grossSalary,
    required this.deductions,
    required this.netSalary,
    required this.status,
    this.payslipUrl,
    this.paidAt,
    required this.createdAt,
  });

  factory PayrollSlipModel.fromJson(Map<String, dynamic> json) {
    return PayrollSlipModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employee: json['employee'] is Map<String, dynamic>
          ? PayrollEmployeeSummaryModel.fromJson(
              json['employee'] as Map<String, dynamic>)
          : const PayrollEmployeeSummaryModel(id: '', firstName: '-'),
      period: json['period'] is Map<String, dynamic>
          ? PayrollPeriodModel.fromJson(json['period'] as Map<String, dynamic>)
          : PayrollPeriodModel(
              id: '',
              month: 1,
              year: DateTime.now().year,
              label: '',
              startDate: '',
              endDate: '',
              payDate: '',
              status: '',
            ),
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ??
          (json['grossSalary'] as num?)?.toDouble() ??
          0.0,
      dailySalary: (json['dailySalary'] as num?)?.toDouble(),
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'draft',
      payslipUrl: json['payslipUrl'] as String?,
      paidAt: json['paidAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employee': employee.toJson(),
      'period': period.toJson(),
      'basicSalary': basicSalary,
      'dailySalary': dailySalary,
      'grossSalary': grossSalary,
      'deductions': deductions,
      'netSalary': netSalary,
      'status': status,
      'payslipUrl': payslipUrl,
      'paidAt': paidAt,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        employee,
        period,
        basicSalary,
        dailySalary,
        grossSalary,
        deductions,
        netSalary,
        status,
        payslipUrl,
        paidAt,
        createdAt,
      ];
}

class PayrollListResponseModel extends Equatable {
  final List<PayrollSlipModel> data;
  final PayrollPaginationMeta meta;

  const PayrollListResponseModel({
    required this.data,
    required this.meta,
  });

  factory PayrollListResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) => PayrollSlipModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final meta = json['meta'] is Map<String, dynamic>
        ? PayrollPaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PayrollPaginationMeta(
            page: 1,
            size: list.length,
            total: list.length,
            totalPages: 1,
          );

    return PayrollListResponseModel(data: list, meta: meta);
  }

  @override
  List<Object?> get props => [data, meta];
}
