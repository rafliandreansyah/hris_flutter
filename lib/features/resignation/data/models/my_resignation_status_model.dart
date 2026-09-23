import 'package:equatable/equatable.dart';

class MyResignationStatusModel extends Equatable {
  final bool hasActiveResignation;
  final int daysRemaining;
  final ResignationDetailModel? resignation;
  final bool canCancel;
  final bool canSubmitExitInterview;
  final bool hasSubmittedExitInterview;

  const MyResignationStatusModel({
    required this.hasActiveResignation,
    this.daysRemaining = 0,
    this.resignation,
    this.canCancel = false,
    this.canSubmitExitInterview = false,
    this.hasSubmittedExitInterview = false,
  });

  factory MyResignationStatusModel.fromJson(Map<String, dynamic> json) {
    return MyResignationStatusModel(
      hasActiveResignation: json['hasActiveResignation'] as bool? ?? false,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      resignation: json['resignation'] != null
          ? ResignationDetailModel.fromJson(
              json['resignation'] as Map<String, dynamic>,
            )
          : null,
      canCancel: json['canCancel'] as bool? ?? false,
      canSubmitExitInterview:
          json['canSubmitExitInterview'] as bool? ?? false,
      hasSubmittedExitInterview:
          json['hasSubmittedExitInterview'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        hasActiveResignation,
        daysRemaining,
        resignation,
        canCancel,
        canSubmitExitInterview,
        hasSubmittedExitInterview,
      ];
}

class ResignationDetailModel extends Equatable {
  final String id;
  final String companyId;
  final String employeeId;
  final ResignationEmployeeModel? employee;
  final DateTime? resignationDate;
  final DateTime? effectiveDate;
  final DateTime? actualResignDate;
  final int requiredNoticePeriodDays;
  final int actualNoticePeriodDays;
  final bool isEarlyNotice;
  final String? earlyNoticeReason;
  final bool isEarlyNoticeApproved;
  final String reasonCategory;
  final String reason;
  final String? resignationLetterUrl;
  final String? handoverToEmployeeId;
  final ResignationHandoverToModel? handoverTo;
  final String? handoverNotes;
  final String? handoverDocumentUrl;
  final int remainingLeaveDays;
  final String? leaveEncashmentStatus;
  final bool isLeaveEncashed;
  final int? encashedLeaveDays;
  final double? encashedLeaveAmount;
  final String status;
  final String? rejectionReason;
  final ResignationApproverModel? managerApprover;
  final String? managerNotes;
  final DateTime? managerApprovedAt;
  final ResignationApproverModel? hrApprover;
  final String? hrNotes;
  final DateTime? hrApprovedAt;
  final bool isPayrollHold;
  final String? paklaringNumber;
  final String? paklaringUrl;
  final DateTime? paklaringIssuedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ResignationTimelineItemModel> timeline;
  final ResignationClearanceSnapshotModel? clearanceSnapshot;
  final bool hasExitInterview;

  const ResignationDetailModel({
    required this.id,
    required this.companyId,
    required this.employeeId,
    this.employee,
    this.resignationDate,
    this.effectiveDate,
    this.actualResignDate,
    this.requiredNoticePeriodDays = 30,
    this.actualNoticePeriodDays = 30,
    this.isEarlyNotice = false,
    this.earlyNoticeReason,
    this.isEarlyNoticeApproved = false,
    this.reasonCategory = 'CAREER_GROWTH',
    this.reason = '',
    this.resignationLetterUrl,
    this.handoverToEmployeeId,
    this.handoverTo,
    this.handoverNotes,
    this.handoverDocumentUrl,
    this.remainingLeaveDays = 0,
    this.leaveEncashmentStatus,
    this.isLeaveEncashed = false,
    this.encashedLeaveDays,
    this.encashedLeaveAmount,
    this.status = 'submitted',
    this.rejectionReason,
    this.managerApprover,
    this.managerNotes,
    this.managerApprovedAt,
    this.hrApprover,
    this.hrNotes,
    this.hrApprovedAt,
    this.isPayrollHold = false,
    this.paklaringNumber,
    this.paklaringUrl,
    this.paklaringIssuedAt,
    this.createdAt,
    this.updatedAt,
    this.timeline = const [],
    this.clearanceSnapshot,
    this.hasExitInterview = false,
  });

  factory ResignationDetailModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    final employeeJson = json['employee'] as Map<String, dynamic>?;
    final handoverJson = (json['handoverTo'] ?? json['handoverEmployee'])
        as Map<String, dynamic>?;

    final managerJson = json['managerApprover'] as Map<String, dynamic>?;
    final hrJson = json['hrApprover'] as Map<String, dynamic>?;

    final timelineRaw = json['timeline'] as List<dynamic>?;
    final timelineList = timelineRaw != null
        ? timelineRaw
            .whereType<Map<String, dynamic>>()
            .map(ResignationTimelineItemModel.fromJson)
            .toList()
        : <ResignationTimelineItemModel>[];

    final clearanceJson = json['clearanceSnapshot'] as Map<String, dynamic>?;

    return ResignationDetailModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employee: employeeJson != null
          ? ResignationEmployeeModel.fromJson(employeeJson)
          : null,
      resignationDate:
          parseDate(json['resignationDate'] ?? json['submittedDate']),
      effectiveDate:
          parseDate(json['effectiveDate'] ?? json['requestedResignDate']),
      actualResignDate: parseDate(json['actualResignDate']),
      requiredNoticePeriodDays:
          (json['requiredNoticePeriodDays'] as num?)?.toInt() ?? 30,
      actualNoticePeriodDays:
          (json['actualNoticePeriodDays'] as num?)?.toInt() ?? 30,
      isEarlyNotice: json['isEarlyNotice'] as bool? ?? false,
      earlyNoticeReason: json['earlyNoticeReason']?.toString(),
      isEarlyNoticeApproved:
          json['isEarlyNoticeApproved'] as bool? ?? false,
      reasonCategory:
          json['reasonCategory']?.toString() ?? 'CAREER_GROWTH',
      reason: (json['reason'] ?? json['reasonNotes'])?.toString() ?? '',
      resignationLetterUrl: json['resignationLetterUrl']?.toString(),
      handoverToEmployeeId: json['handoverToEmployeeId']?.toString(),
      handoverTo: handoverJson != null
          ? ResignationHandoverToModel.fromJson(handoverJson)
          : null,
      handoverNotes: json['handoverNotes']?.toString(),
      handoverDocumentUrl: json['handoverDocumentUrl']?.toString(),
      remainingLeaveDays:
          (json['remainingLeaveDays'] as num?)?.toInt() ?? 0,
      leaveEncashmentStatus: json['leaveEncashmentStatus']?.toString(),
      isLeaveEncashed: json['isLeaveEncashed'] as bool? ?? false,
      encashedLeaveDays: (json['encashedLeaveDays'] as num?)?.toInt(),
      encashedLeaveAmount:
          (json['encashedLeaveAmount'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'submitted',
      rejectionReason: json['rejectionReason']?.toString(),
      managerApprover: managerJson != null
          ? ResignationApproverModel.fromJson(managerJson)
          : null,
      managerNotes: json['managerNotes']?.toString(),
      managerApprovedAt: parseDate(json['managerApprovedAt']),
      hrApprover:
          hrJson != null ? ResignationApproverModel.fromJson(hrJson) : null,
      hrNotes: json['hrNotes']?.toString(),
      hrApprovedAt: parseDate(json['hrApprovedAt']),
      isPayrollHold: json['isPayrollHold'] as bool? ?? false,
      paklaringNumber: json['paklaringNumber']?.toString(),
      paklaringUrl: json['paklaringUrl']?.toString(),
      paklaringIssuedAt: parseDate(json['paklaringIssuedAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      timeline: timelineList,
      clearanceSnapshot: clearanceJson != null
          ? ResignationClearanceSnapshotModel.fromJson(clearanceJson)
          : null,
      hasExitInterview: json['hasExitInterview'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        employeeId,
        status,
        effectiveDate,
        resignationDate,
        reasonCategory,
        reason,
        daysRemainingValue,
        managerNotes,
      ];

  int get daysRemainingValue {
    if (effectiveDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      effectiveDate!.year,
      effectiveDate!.month,
      effectiveDate!.day,
    );
    final diff = target.difference(today).inDays;
    return diff > 0 ? diff : 0;
  }
}

class ResignationEmployeeModel extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? nik;
  final String? email;
  final String? avatarUrl;
  final String? departmentName;
  final String? positionName;

  const ResignationEmployeeModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.nik,
    this.email,
    this.avatarUrl,
    this.departmentName,
    this.positionName,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) return firstName;
    return '$firstName $lastName'.trim();
  }

  factory ResignationEmployeeModel.fromJson(Map<String, dynamic> json) {
    String? dept;
    if (json['department'] is Map) {
      dept = json['department']['name']?.toString();
    } else {
      dept = json['department']?.toString() ?? json['departmentName']?.toString();
    }

    String? pos;
    if (json['position'] is Map) {
      pos = json['position']['name']?.toString();
    } else {
      pos = json['position']?.toString() ??
          json['designation']?.toString() ??
          json['positionName']?.toString();
    }

    return ResignationEmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ??
          json['name']?.toString() ??
          'Karyawan',
      lastName: json['lastName']?.toString(),
      nik: json['nik']?.toString() ?? json['employeeNik']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      departmentName: dept,
      positionName: pos,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        nik,
        email,
        avatarUrl,
        departmentName,
        positionName,
      ];
}

class ResignationApproverModel extends Equatable {
  final String id;
  final String name;

  const ResignationApproverModel({
    required this.id,
    required this.name,
  });

  factory ResignationApproverModel.fromJson(Map<String, dynamic> json) {
    return ResignationApproverModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['firstName']?.toString() ??
          '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class ResignationHandoverToModel extends Equatable {
  final String id;
  final String firstName;
  final String? lastName;
  final String? departmentName;
  final String? positionName;

  const ResignationHandoverToModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.departmentName,
    this.positionName,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) return firstName;
    return '$firstName $lastName'.trim();
  }

  factory ResignationHandoverToModel.fromJson(Map<String, dynamic> json) {
    return ResignationHandoverToModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ??
          json['name']?.toString() ??
          '',
      lastName: json['lastName']?.toString(),
      departmentName: json['departmentName']?.toString(),
      positionName: json['positionName']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        departmentName,
        positionName,
      ];
}

class ResignationTimelineItemModel extends Equatable {
  final String stage;
  final String title;
  final String? actorName;
  final DateTime? timestamp;
  final bool isCompleted;
  final String? notes;

  const ResignationTimelineItemModel({
    required this.stage,
    required this.title,
    this.actorName,
    this.timestamp,
    this.isCompleted = false,
    this.notes,
  });

  factory ResignationTimelineItemModel.fromJson(Map<String, dynamic> json) {
    return ResignationTimelineItemModel(
      stage: json['stage']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      actorName: json['actorName']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        stage,
        title,
        actorName,
        timestamp,
        isCompleted,
        notes,
      ];
}

class ResignationClearanceSnapshotModel extends Equatable {
  final ClearanceItAssetsModel? itAssets;
  final ClearanceFinanceModel? finance;
  final ClearanceTeamDelegationModel? teamDelegation;
  final bool isAllCleared;

  const ResignationClearanceSnapshotModel({
    this.itAssets,
    this.finance,
    this.teamDelegation,
    this.isAllCleared = false,
  });

  factory ResignationClearanceSnapshotModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResignationClearanceSnapshotModel(
      itAssets: json['itAssets'] != null
          ? ClearanceItAssetsModel.fromJson(
              json['itAssets'] as Map<String, dynamic>,
            )
          : null,
      finance: json['finance'] != null
          ? ClearanceFinanceModel.fromJson(
              json['finance'] as Map<String, dynamic>,
            )
          : null,
      teamDelegation: json['teamDelegation'] != null
          ? ClearanceTeamDelegationModel.fromJson(
              json['teamDelegation'] as Map<String, dynamic>,
            )
          : null,
      isAllCleared: json['isAllCleared'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        itAssets,
        finance,
        teamDelegation,
        isAllCleared,
      ];
}

class ClearanceItAssetsModel extends Equatable {
  final bool isCleared;
  final int count;
  final List<ClearanceAssetItemModel> items;

  const ClearanceItAssetsModel({
    required this.isCleared,
    required this.count,
    this.items = const [],
  });

  factory ClearanceItAssetsModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    return ClearanceItAssetsModel(
      isCleared: json['isCleared'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 0,
      items: rawItems != null
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(ClearanceAssetItemModel.fromJson)
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [isCleared, count, items];
}

class ClearanceAssetItemModel extends Equatable {
  final String assignmentId;
  final String assetCode;
  final String assetName;
  final String? serialNumber;

  const ClearanceAssetItemModel({
    required this.assignmentId,
    required this.assetCode,
    required this.assetName,
    this.serialNumber,
  });

  factory ClearanceAssetItemModel.fromJson(Map<String, dynamic> json) {
    return ClearanceAssetItemModel(
      assignmentId: json['assignmentId']?.toString() ?? '',
      assetCode: json['assetCode']?.toString() ?? '',
      assetName: json['assetName']?.toString() ?? '',
      serialNumber: json['serialNumber']?.toString(),
    );
  }

  @override
  List<Object?> get props => [assignmentId, assetCode, assetName, serialNumber];
}

class ClearanceFinanceModel extends Equatable {
  final bool isCleared;
  final int openCashAdvanceCount;
  final double totalUnsettledCashAdvance;
  final int pendingReimbursementCount;

  const ClearanceFinanceModel({
    required this.isCleared,
    required this.openCashAdvanceCount,
    required this.totalUnsettledCashAdvance,
    required this.pendingReimbursementCount,
  });

  factory ClearanceFinanceModel.fromJson(Map<String, dynamic> json) {
    return ClearanceFinanceModel(
      isCleared: json['isCleared'] as bool? ?? false,
      openCashAdvanceCount:
          (json['openCashAdvanceCount'] as num?)?.toInt() ?? 0,
      totalUnsettledCashAdvance:
          (json['totalUnsettledCashAdvance'] as num?)?.toDouble() ?? 0.0,
      pendingReimbursementCount:
          (json['pendingReimbursementCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        isCleared,
        openCashAdvanceCount,
        totalUnsettledCashAdvance,
        pendingReimbursementCount,
      ];
}

class ClearanceTeamDelegationModel extends Equatable {
  final bool isCleared;
  final int subordinateCount;

  const ClearanceTeamDelegationModel({
    required this.isCleared,
    required this.subordinateCount,
  });

  factory ClearanceTeamDelegationModel.fromJson(Map<String, dynamic> json) {
    return ClearanceTeamDelegationModel(
      isCleared: json['isCleared'] as bool? ?? false,
      subordinateCount:
          (json['subordinateCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [isCleared, subordinateCount];
}
