import 'package:equatable/equatable.dart';

class ResignationInitialFormModel extends Equatable {
  final ResignationCompanyPolicyModel companyPolicy;
  final ResignationFormEmployeeModel employee;
  final String minSuggestedDate;
  final List<ResignationColleagueModel> colleagues;

  const ResignationInitialFormModel({
    required this.companyPolicy,
    required this.employee,
    required this.minSuggestedDate,
    required this.colleagues,
  });

  factory ResignationInitialFormModel.fromJson(Map<String, dynamic> json) {
    return ResignationInitialFormModel(
      companyPolicy: json['companyPolicy'] is Map<String, dynamic>
          ? ResignationCompanyPolicyModel.fromJson(
              json['companyPolicy'] as Map<String, dynamic>,
            )
          : const ResignationCompanyPolicyModel(),
      employee: json['employee'] is Map<String, dynamic>
          ? ResignationFormEmployeeModel.fromJson(
              json['employee'] as Map<String, dynamic>,
            )
          : const ResignationFormEmployeeModel(id: '', name: ''),
      minSuggestedDate: json['minSuggestedDate']?.toString() ?? '',
      colleagues: json['colleagues'] is List
          ? (json['colleagues'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ResignationColleagueModel.fromJson)
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [
        companyPolicy,
        employee,
        minSuggestedDate,
        colleagues,
      ];
}

class ResignationCompanyPolicyModel extends Equatable {
  final bool isNoticePeriodRequired;
  final int defaultNoticePeriodDays;
  final bool useLevelNoticePeriodPolicy;
  final bool allowEarlyNoticeWaiver;
  final bool allowLeaveEncashmentOnResign;
  final bool enableExitInterview;
  final bool isExitInterviewMandatory;
  final int effectiveNoticePeriodDays;

  const ResignationCompanyPolicyModel({
    this.isNoticePeriodRequired = true,
    this.defaultNoticePeriodDays = 30,
    this.useLevelNoticePeriodPolicy = true,
    this.allowEarlyNoticeWaiver = true,
    this.allowLeaveEncashmentOnResign = true,
    this.enableExitInterview = true,
    this.isExitInterviewMandatory = true,
    this.effectiveNoticePeriodDays = 30,
  });

  factory ResignationCompanyPolicyModel.fromJson(Map<String, dynamic> json) {
    return ResignationCompanyPolicyModel(
      isNoticePeriodRequired: json['isNoticePeriodRequired'] == true,
      defaultNoticePeriodDays:
          (json['defaultNoticePeriodDays'] as num?)?.toInt() ?? 30,
      useLevelNoticePeriodPolicy: json['useLevelNoticePeriodPolicy'] == true,
      allowEarlyNoticeWaiver: json['allowEarlyNoticeWaiver'] != false,
      allowLeaveEncashmentOnResign:
          json['allowLeaveEncashmentOnResign'] == true,
      enableExitInterview: json['enableExitInterview'] != false,
      isExitInterviewMandatory: json['isExitInterviewMandatory'] == true,
      effectiveNoticePeriodDays:
          (json['effectiveNoticePeriodDays'] as num?)?.toInt() ?? 30,
    );
  }

  @override
  List<Object?> get props => [
        isNoticePeriodRequired,
        defaultNoticePeriodDays,
        useLevelNoticePeriodPolicy,
        allowEarlyNoticeWaiver,
        allowLeaveEncashmentOnResign,
        enableExitInterview,
        isExitInterviewMandatory,
        effectiveNoticePeriodDays,
      ];
}

class ResignationFormEmployeeModel extends Equatable {
  final String id;
  final String name;
  final String? departmentId;
  final String? departmentName;
  final String? positionName;
  final String? levelName;
  final int remainingLeaveDays;

  const ResignationFormEmployeeModel({
    required this.id,
    required this.name,
    this.departmentId,
    this.departmentName,
    this.positionName,
    this.levelName,
    this.remainingLeaveDays = 0,
  });

  factory ResignationFormEmployeeModel.fromJson(Map<String, dynamic> json) {
    return ResignationFormEmployeeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
      positionName: json['positionName']?.toString(),
      levelName: json['levelName']?.toString(),
      remainingLeaveDays:
          (json['remainingLeaveDays'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        departmentId,
        departmentName,
        positionName,
        levelName,
        remainingLeaveDays,
      ];
}

class ResignationColleagueModel extends Equatable {
  final String id;
  final String name;
  final String? departmentName;
  final String? positionName;

  const ResignationColleagueModel({
    required this.id,
    required this.name,
    this.departmentName,
    this.positionName,
  });

  factory ResignationColleagueModel.fromJson(Map<String, dynamic> json) {
    return ResignationColleagueModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      departmentName: json['departmentName']?.toString(),
      positionName: json['positionName']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, departmentName, positionName];
}
