import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';

/// Lampiran bukti nota pengeluaran.
class ReimbursementAttachmentModel {
  final String id;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final String createdAt;

  const ReimbursementAttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.createdAt,
  });

  String? get resolvedFileUrl => resolveFileUrl(fileUrl);

  factory ReimbursementAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementAttachmentModel(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

/// Rincian satu baris nota biaya (Line Item).
class ReimbursementLineItemModel {
  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryCode;
  final String transactionDate;
  final String? merchantName;
  final String description;
  final double requestedAmount;
  final double? approvedAmount;
  final String status;
  final String? rejectionReason;
  final List<ReimbursementAttachmentModel> attachments;

  const ReimbursementLineItemModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryCode,
    required this.transactionDate,
    this.merchantName,
    required this.description,
    required this.requestedAmount,
    this.approvedAmount,
    required this.status,
    this.rejectionReason,
    this.attachments = const [],
  });

  String? get merchant => merchantName;
  String get formattedDate {
    final dt = DateTime.tryParse(transactionDate);
    return dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
        : transactionDate;
  }

  factory ReimbursementLineItemModel.fromJson(Map<String, dynamic> json) {
    final catMap = json['category'] is Map<String, dynamic>
        ? json['category'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawAtts = json['attachments'] as List<dynamic>? ?? [];
    final attachments = rawAtts
        .whereType<Map<String, dynamic>>()
        .map(ReimbursementAttachmentModel.fromJson)
        .toList();

    return ReimbursementLineItemModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: catMap['name']?.toString() ?? '',
      categoryCode: catMap['code']?.toString() ?? '',
      transactionDate: json['transactionDate']?.toString() ?? '',
      merchantName: json['merchantName']?.toString(),
      description: json['description']?.toString() ?? '',
      requestedAmount: (json['requestedAmount'] as num?)?.toDouble() ?? 0.0,
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'pending',
      rejectionReason: json['rejectionReason']?.toString(),
      attachments: attachments,
    );
  }
}

/// Riwayat persetujuan atau penolakan pengajuan.
class ReimbursementApprovalHistoryModel {
  final String id;
  final String stepRole;
  final String action;
  final String? notes;
  final String createdAt;
  final ExpenseEmployeeModel approver;

  const ReimbursementApprovalHistoryModel({
    required this.id,
    required this.stepRole,
    required this.action,
    this.notes,
    required this.createdAt,
    required this.approver,
  });

  String get status => action;
  String get approverName => approver.fullName;
  DateTime? get createdAtDateTime => DateTime.tryParse(createdAt);

  factory ReimbursementApprovalHistoryModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementApprovalHistoryModel(
      id: json['id']?.toString() ?? '',
      stepRole: json['stepRole']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      approver: ExpenseEmployeeModel.fromJson(
        json['approver'] is Map<String, dynamic>
            ? json['approver'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
    );
  }
}

/// Model detail lengkap pengajuan reimbursement.
class ReimbursementDetailModel {
  final String id;
  final String claimNumber;
  final String type;
  final String title;
  final String? description;
  final double totalRequestedAmount;
  final double? totalApprovedAmount;
  final String? balanceType;
  final double? balanceAmount;
  final String status;
  final String? disbursementMethod;
  final String? disbursedAt;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? disbursementProofUrl;
  final String? paymentReference;
  final String? rejectionReason;
  final String createdAt;
  final ExpenseEmployeeModel employee;
  final ExpenseEmployeeModel? createdBy;
  final Map<String, dynamic>? cashAdvance;
  final List<ReimbursementLineItemModel> items;
  final List<ReimbursementApprovalHistoryModel> approvalHistories;

  const ReimbursementDetailModel({
    required this.id,
    required this.claimNumber,
    required this.type,
    required this.title,
    this.description,
    required this.totalRequestedAmount,
    this.totalApprovedAmount,
    this.balanceType,
    this.balanceAmount,
    required this.status,
    this.disbursementMethod,
    this.disbursedAt,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.disbursementProofUrl,
    this.paymentReference,
    this.rejectionReason,
    required this.createdAt,
    required this.employee,
    this.createdBy,
    this.cashAdvance,
    this.items = const [],
    this.approvalHistories = const [],
  });

  String? get resolvedDisbursementProofUrl =>
      resolveFileUrl(disbursementProofUrl);

  double get requestedAmount => totalRequestedAmount;
  double? get approvedAmount => totalApprovedAmount;
  String? get paymentMethod => disbursementMethod;
  DateTime? get submittedAt => DateTime.tryParse(createdAt);
  String? get approverNotes {
    for (final h in approvalHistories) {
      if (h.notes != null && h.notes!.isNotEmpty) {
        return h.notes;
      }
    }
    return null;
  }
  List<ReimbursementAttachmentModel> get attachments =>
      items.expand((it) => it.attachments).toList();

  factory ReimbursementDetailModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(ReimbursementLineItemModel.fromJson)
        .toList();

    final rawHistory = json['approvalHistories'] as List<dynamic>? ?? [];
    final approvalHistories = rawHistory
        .whereType<Map<String, dynamic>>()
        .map(ReimbursementApprovalHistoryModel.fromJson)
        .toList();

    return ReimbursementDetailModel(
      id: json['id']?.toString() ?? '',
      claimNumber: json['claimNumber']?.toString() ?? '',
      type: json['type']?.toString() ?? 'out_of_pocket',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      totalRequestedAmount:
          (json['totalRequestedAmount'] as num?)?.toDouble() ?? 0.0,
      totalApprovedAmount:
          (json['totalApprovedAmount'] as num?)?.toDouble(),
      balanceType: json['balanceType']?.toString(),
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'requested',
      disbursementMethod: json['disbursementMethod']?.toString(),
      disbursedAt: json['disbursedAt']?.toString(),
      bankName: json['bankName']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      bankAccountHolder: json['bankAccountHolder']?.toString(),
      disbursementProofUrl: json['disbursementProofUrl']?.toString(),
      paymentReference: json['paymentReference']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      employee: ExpenseEmployeeModel.fromJson(
        json['employee'] is Map<String, dynamic>
            ? json['employee'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? ExpenseEmployeeModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      cashAdvance: json['cashAdvance'] is Map<String, dynamic>
          ? json['cashAdvance'] as Map<String, dynamic>
          : null,
      items: items,
      approvalHistories: approvalHistories,
    );
  }
}
