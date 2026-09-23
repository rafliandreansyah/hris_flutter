import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';

class ResignationPaginationMeta extends Equatable {
  final int page;
  final int size;
  final int total;
  final int totalPages;

  const ResignationPaginationMeta({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
  });

  factory ResignationPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ResignationPaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [page, size, total, totalPages];
}

class SubordinateResignationResponseModel extends Equatable {
  final bool success;
  final String message;
  final List<SubordinateResignationItemModel> data;
  final ResignationPaginationMeta meta;

  const SubordinateResignationResponseModel({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory SubordinateResignationResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final list = (json['data'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(SubordinateResignationItemModel.fromJson)
            .toList() ??
        [];

    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};

    return SubordinateResignationResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: list,
      meta: ResignationPaginationMeta.fromJson(metaJson),
    );
  }

  @override
  List<Object?> get props => [success, message, data, meta];
}

class SubordinateResignationItemModel extends Equatable {
  final String id;
  final String companyId;
  final String employeeId;
  final ResignationEmployeeModel? employee;
  final String employeeName;
  final String? employeeNik;
  final String? departmentName;
  final String? positionName;
  final String? avatarUrl;
  final DateTime? submittedDate;
  final DateTime? effectiveDate;
  final DateTime? actualResignDate;
  final int requiredNoticePeriodDays;
  final int actualNoticePeriodDays;
  final bool isEarlyNotice;
  final String? earlyNoticeReason;
  final String reasonCategory;
  final String reason;
  final String status;
  final String? managerNotes;
  final String? handoverToName;
  final DateTime? createdAt;

  const SubordinateResignationItemModel({
    required this.id,
    required this.companyId,
    required this.employeeId,
    this.employee,
    required this.employeeName,
    this.employeeNik,
    this.departmentName,
    this.positionName,
    this.avatarUrl,
    this.submittedDate,
    this.effectiveDate,
    this.actualResignDate,
    this.requiredNoticePeriodDays = 30,
    this.actualNoticePeriodDays = 30,
    this.isEarlyNotice = false,
    this.earlyNoticeReason,
    this.reasonCategory = 'CAREER_GROWTH',
    this.reason = '',
    this.status = 'submitted',
    this.managerNotes,
    this.handoverToName,
    this.createdAt,
  });

  factory SubordinateResignationItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    final empJson = json['employee'] as Map<String, dynamic>?;
    final empModel =
        empJson != null ? ResignationEmployeeModel.fromJson(empJson) : null;

    final resolvedName = empModel?.fullName ??
        json['employeeName']?.toString() ??
        'Karyawan';

    final handoverJson =
        (json['handoverTo'] ?? json['handoverEmployee']) as Map<String, dynamic>?;
    final resolvedHandover = handoverJson != null
        ? ResignationHandoverToModel.fromJson(handoverJson).fullName
        : json['handoverToEmployeeName']?.toString();

    return SubordinateResignationItemModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employee: empModel,
      employeeName: resolvedName,
      employeeNik: empModel?.nik ?? json['employeeNik']?.toString(),
      departmentName:
          empModel?.departmentName ?? json['departmentName']?.toString(),
      positionName:
          empModel?.positionName ?? json['positionName']?.toString(),
      avatarUrl: empModel?.avatarUrl ?? json['avatarUrl']?.toString(),
      submittedDate:
          parseDate(json['submittedDate'] ?? json['resignationDate']),
      effectiveDate:
          parseDate(json['requestedResignDate'] ?? json['effectiveDate']),
      actualResignDate: parseDate(json['actualResignDate']),
      requiredNoticePeriodDays:
          (json['requiredNoticePeriodDays'] as num?)?.toInt() ?? 30,
      actualNoticePeriodDays:
          (json['actualNoticePeriodDays'] as num?)?.toInt() ?? 30,
      isEarlyNotice: json['isEarlyNotice'] as bool? ?? false,
      earlyNoticeReason: json['earlyNoticeReason']?.toString(),
      reasonCategory:
          json['reasonCategory']?.toString() ?? 'CAREER_GROWTH',
      reason: (json['reason'] ?? json['reasonNotes'])?.toString() ?? '',
      status: json['status']?.toString() ?? 'submitted',
      managerNotes: json['managerNotes']?.toString(),
      handoverToName: resolvedHandover,
      createdAt: parseDate(json['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        employeeId,
        employeeName,
        status,
        effectiveDate,
        submittedDate,
        isEarlyNotice,
        reasonCategory,
      ];
}
