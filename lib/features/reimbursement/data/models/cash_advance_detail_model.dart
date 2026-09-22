import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';

/// Riwayat pengembalian / refund sisa dana kasbon.
class CashAdvanceRefundModel {
  final String id;
  final double amount;
  final String method;
  final String? refundDate;
  final String? proofUrl;
  final bool isConfirmedByFinance;
  final String? confirmedAt;
  final String? notes;
  final String createdAt;

  const CashAdvanceRefundModel({
    required this.id,
    required this.amount,
    required this.method,
    this.refundDate,
    this.proofUrl,
    required this.isConfirmedByFinance,
    this.confirmedAt,
    this.notes,
    required this.createdAt,
  });

  String? get resolvedProofUrl => resolveFileUrl(proofUrl);

  String get paymentMethod => method;
  String get formattedDate {
    final dt = DateTime.tryParse(refundDate ?? createdAt);
    return dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
        : (refundDate ?? createdAt);
  }

  factory CashAdvanceRefundModel.fromJson(Map<String, dynamic> json) {
    return CashAdvanceRefundModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method']?.toString() ??
          json['refundMethod']?.toString() ??
          'bank_transfer_refund',
      refundDate: json['refundDate']?.toString(),
      proofUrl: json['proofUrl']?.toString(),
      isConfirmedByFinance: json['isConfirmedByFinance'] as bool? ?? false,
      confirmedAt: json['confirmedAt']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

/// Rincian laporan pertanggungjawaban (settlement reimbursement) yang terhubung ke kasbon.
class CashAdvanceSettlementReportModel {
  final String id;
  final String claimNumber;
  final String title;
  final double totalRequestedAmount;
  final double? totalApprovedAmount;
  final String? balanceType;
  final double? balanceAmount;
  final String status;

  const CashAdvanceSettlementReportModel({
    required this.id,
    required this.claimNumber,
    required this.title,
    required this.totalRequestedAmount,
    this.totalApprovedAmount,
    this.balanceType,
    this.balanceAmount,
    required this.status,
  });

  factory CashAdvanceSettlementReportModel.fromJson(Map<String, dynamic> json) {
    return CashAdvanceSettlementReportModel(
      id: json['id']?.toString() ?? '',
      claimNumber: json['claimNumber']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      totalRequestedAmount:
          (json['totalRequestedAmount'] as num?)?.toDouble() ?? 0.0,
      totalApprovedAmount:
          (json['totalApprovedAmount'] as num?)?.toDouble(),
      balanceType: json['balanceType']?.toString(),
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'requested',
    );
  }
}

/// Model detail lengkap pengajuan kasbon (Cash Advance).
class CashAdvanceDetailModel {
  final String id;
  final String advanceNumber;
  final String title;
  final String purpose;
  final double requestedAmount;
  final double? approvedAmount;
  final String status;
  final String? disbursementMethod;
  final String? disbursedAt;
  final String? disbursementProofUrl;
  final String? disbursementNotes;
  final String? settlementDeadline;
  final String createdAt;
  final ExpenseEmployeeModel employee;
  final ExpenseEmployeeModel? createdBy;
  final List<CashAdvanceRefundModel> refunds;
  final CashAdvanceSettlementReportModel? settlementReport;

  const CashAdvanceDetailModel({
    required this.id,
    required this.advanceNumber,
    required this.title,
    required this.purpose,
    required this.requestedAmount,
    this.approvedAmount,
    required this.status,
    this.disbursementMethod,
    this.disbursedAt,
    this.disbursementProofUrl,
    this.disbursementNotes,
    this.settlementDeadline,
    required this.createdAt,
    required this.employee,
    this.createdBy,
    this.refunds = const [],
    this.settlementReport,
  });

  String? get resolvedDisbursementProofUrl =>
      resolveFileUrl(disbursementProofUrl);

  DateTime? get submittedAt => DateTime.tryParse(createdAt);
  double get disbursedAmount => approvedAmount ?? requestedAmount;
  double get settledAmount =>
      settlementReport?.totalApprovedAmount ??
      settlementReport?.totalRequestedAmount ??
      0.0;
  double get refundedAmount =>
      refunds.fold(0.0, (acc, r) => acc + r.amount);
  double get remainingAmount =>
      (disbursedAmount - settledAmount - refundedAmount)
          .clamp(0.0, double.infinity);
  double get settlementProgress => disbursedAmount > 0
      ? ((settledAmount + refundedAmount) / disbursedAmount).clamp(0.0, 1.0)
      : 0.0;
  DateTime? get deadlineDateTime => settlementDeadline != null
      ? DateTime.tryParse(settlementDeadline!)
      : null;
  bool get isOverdue =>
      deadlineDateTime != null &&
      DateTime.now().isAfter(deadlineDateTime!) &&
      remainingAmount > 0;
  String? get approverNotes => disbursementNotes;

  factory CashAdvanceDetailModel.fromJson(Map<String, dynamic> json) {
    final rawRefunds = json['refunds'] as List<dynamic>? ?? [];
    final refunds = rawRefunds
        .whereType<Map<String, dynamic>>()
        .map(CashAdvanceRefundModel.fromJson)
        .toList();

    return CashAdvanceDetailModel(
      id: json['id']?.toString() ?? '',
      advanceNumber: json['advanceNumber']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      requestedAmount: (json['requestedAmount'] as num?)?.toDouble() ?? 0.0,
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'requested',
      disbursementMethod: json['disbursementMethod']?.toString(),
      disbursedAt: json['disbursedAt']?.toString(),
      disbursementProofUrl: json['disbursementProofUrl']?.toString(),
      disbursementNotes: json['disbursementNotes']?.toString(),
      settlementDeadline: json['settlementDeadline']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      employee: ExpenseEmployeeModel.fromJson(
        json['employee'] is Map<String, dynamic>
            ? json['employee'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? ExpenseEmployeeModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      refunds: refunds,
      settlementReport: json['settlementReport'] is Map<String, dynamic>
          ? CashAdvanceSettlementReportModel.fromJson(
              json['settlementReport'] as Map<String, dynamic>)
          : null,
    );
  }
}
