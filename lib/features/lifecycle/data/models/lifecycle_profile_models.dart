import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_json.dart';

class ActiveContractModel extends Equatable {
  final String id;
  final String contractNumber;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? probationEndDate;
  final int? daysUntilExpiry;
  final bool isNearExpiry;

  const ActiveContractModel({
    required this.id,
    required this.contractNumber,
    required this.type,
    this.startDate,
    this.endDate,
    this.probationEndDate,
    this.daysUntilExpiry,
    this.isNearExpiry = false,
  });

  factory ActiveContractModel.fromJson(Map<String, dynamic> j) =>
      ActiveContractModel(
        id: j['id']?.toString() ?? '',
        contractNumber: j['contractNumber']?.toString() ?? '-',
        type: j['type']?.toString() ?? '',
        startDate: lcDate(j['startDate']),
        endDate: lcDate(j['endDate']),
        probationEndDate: lcDate(j['probationEndDate']),
        daysUntilExpiry: (j['daysUntilExpiry'] as num?)?.toInt(),
        isNearExpiry: j['isNearExpiry'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, endDate, daysUntilExpiry];
}

class ContractHistoryItem extends Equatable {
  final String id;
  final String contractNumber;
  final int sequence;
  final String type;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  const ContractHistoryItem({
    required this.id,
    required this.contractNumber,
    required this.sequence,
    required this.type,
    required this.status,
    this.startDate,
    this.endDate,
  });

  factory ContractHistoryItem.fromJson(Map<String, dynamic> j) =>
      ContractHistoryItem(
        id: j['id']?.toString() ?? '',
        contractNumber: j['contractNumber']?.toString() ?? '-',
        sequence: lcInt(j['sequence']),
        type: j['type']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        startDate: lcDate(j['startDate']),
        endDate: lcDate(j['endDate']),
      );

  @override
  List<Object?> get props => [id, status];
}

class PkwtSummary extends Equatable {
  final double totalPkwtMonths;
  final double maxContractMonths;
  final double pkwtMonthsRemaining;

  const PkwtSummary({
    this.totalPkwtMonths = 0,
    this.maxContractMonths = 60,
    this.pkwtMonthsRemaining = 60,
  });

  /// Rasio pemakaian batas PKWT (0..1) untuk bar progres.
  double get usedRatio => maxContractMonths <= 0
      ? 0
      : (totalPkwtMonths / maxContractMonths).clamp(0, 1).toDouble();

  factory PkwtSummary.fromJson(Map<String, dynamic>? j) => PkwtSummary(
        totalPkwtMonths: lcDouble(j?['totalPkwtMonths']) ?? 0,
        maxContractMonths: lcDouble(j?['maxContractMonths']) ?? 60,
        pkwtMonthsRemaining: lcDouble(j?['pkwtMonthsRemaining']) ?? 60,
      );

  @override
  List<Object?> get props =>
      [totalPkwtMonths, maxContractMonths, pkwtMonthsRemaining];
}

class ContractOverviewModel extends Equatable {
  final ActiveContractModel? activeContract;
  final List<ContractHistoryItem> contracts;
  final PkwtSummary pkwtSummary;

  const ContractOverviewModel({
    this.activeContract,
    this.contracts = const [],
    this.pkwtSummary = const PkwtSummary(),
  });

  factory ContractOverviewModel.fromJson(Map<String, dynamic> j) =>
      ContractOverviewModel(
        activeContract: j['activeContract'] is Map<String, dynamic>
            ? ActiveContractModel.fromJson(
                j['activeContract'] as Map<String, dynamic>,
              )
            : null,
        contracts:
            lcList(j['contracts']).map(ContractHistoryItem.fromJson).toList(),
        pkwtSummary:
            PkwtSummary.fromJson(j['pkwtSummary'] as Map<String, dynamic>?),
      );

  @override
  List<Object?> get props => [activeContract, contracts, pkwtSummary];
}

class CareerHistoryItem extends Equatable {
  final String id;
  final String changeType;
  final DateTime? effectiveDate;
  final String? reason;
  final String companyName;
  final String departmentName;
  final String? positionName;
  final String? levelName;
  final String prevCompanyName;
  final String prevDepartmentName;
  final String? prevPositionName;
  final String? prevLevelName;

  const CareerHistoryItem({
    required this.id,
    required this.changeType,
    this.effectiveDate,
    this.reason,
    required this.companyName,
    required this.departmentName,
    this.positionName,
    this.levelName,
    required this.prevCompanyName,
    required this.prevDepartmentName,
    this.prevPositionName,
    this.prevLevelName,
  });

  factory CareerHistoryItem.fromJson(Map<String, dynamic> j) => CareerHistoryItem(
        id: j['id']?.toString() ?? '',
        changeType: j['changeType']?.toString() ?? '',
        effectiveDate: lcDate(j['effectiveDate']),
        reason: j['reason'] as String?,
        companyName: j['companyName']?.toString() ?? '-',
        departmentName: j['departmentName']?.toString() ?? '-',
        positionName: j['positionName'] as String?,
        levelName: j['levelName'] as String?,
        prevCompanyName: j['prevCompanyName']?.toString() ?? '-',
        prevDepartmentName: j['prevDepartmentName']?.toString() ?? '-',
        prevPositionName: j['prevPositionName'] as String?,
        prevLevelName: j['prevLevelName'] as String?,
      );

  @override
  List<Object?> get props => [id, changeType, effectiveDate];
}
