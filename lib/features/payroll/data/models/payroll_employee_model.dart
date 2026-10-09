import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';

class PayrollCompanySummaryModel extends Equatable {
  final String id;
  final String name;

  const PayrollCompanySummaryModel({
    required this.id,
    required this.name,
  });

  factory PayrollCompanySummaryModel.fromJson(Map<String, dynamic> json) {
    return PayrollCompanySummaryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

class PayrollDepartmentSummaryModel extends Equatable {
  final String id;
  final String name;

  const PayrollDepartmentSummaryModel({
    required this.id,
    required this.name,
  });

  factory PayrollDepartmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PayrollDepartmentSummaryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

class PayrollPositionSummaryModel extends Equatable {
  final String id;
  final String name;

  const PayrollPositionSummaryModel({
    required this.id,
    required this.name,
  });

  factory PayrollPositionSummaryModel.fromJson(Map<String, dynamic> json) {
    return PayrollPositionSummaryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}

class PayrollEmployeeItemModel extends Equatable {
  final String id;
  final String name;
  final String firstName;
  final String? lastName;
  final String? employeeNumber;
  final String email;
  final String? phone;
  final String? photoUrl;
  final bool status;
  final PayrollCompanySummaryModel company;
  final PayrollDepartmentSummaryModel? department;
  final PayrollPositionSummaryModel? position;

  const PayrollEmployeeItemModel({
    required this.id,
    required this.name,
    required this.firstName,
    this.lastName,
    this.employeeNumber,
    required this.email,
    this.phone,
    this.photoUrl,
    this.status = true,
    required this.company,
    this.department,
    this.position,
  });

  String get displayName => name.isNotEmpty ? name : firstName;

  String? get resolvedPhotoUrl => resolveFileUrl(photoUrl);

  String get departmentName => department?.name ?? '-';

  String get positionName => position?.name ?? '-';

  factory PayrollEmployeeItemModel.fromJson(Map<String, dynamic> json) {
    return PayrollEmployeeItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['firstName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      employeeNumber: json['employeeNumber'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      status: json['status'] as bool? ?? true,
      company: json['company'] is Map<String, dynamic>
          ? PayrollCompanySummaryModel.fromJson(
              json['company'] as Map<String, dynamic>)
          : const PayrollCompanySummaryModel(id: '', name: '-'),
      department: json['department'] is Map<String, dynamic>
          ? PayrollDepartmentSummaryModel.fromJson(
              json['department'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? PayrollPositionSummaryModel.fromJson(
              json['position'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'employeeNumber': employeeNumber,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'status': status,
      'company': company.toJson(),
      'department': department?.toJson(),
      'position': position?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        firstName,
        lastName,
        employeeNumber,
        email,
        phone,
        photoUrl,
        status,
        company,
        department,
        position,
      ];
}

class PayrollEmployeeListResponseModel extends Equatable {
  final List<PayrollEmployeeItemModel> data;
  final PayrollPaginationMeta meta;

  const PayrollEmployeeListResponseModel({
    required this.data,
    required this.meta,
  });

  factory PayrollEmployeeListResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) =>
                PayrollEmployeeItemModel.fromJson(e as Map<String, dynamic>))
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

    return PayrollEmployeeListResponseModel(data: list, meta: meta);
  }

  @override
  List<Object?> get props => [data, meta];
}
