/// Model master kategori biaya reimbursement.
class ReimbursementCategoryModel {
  final String id;
  final String companyId;
  final String name;
  final String code;
  final String? description;
  final String limitType;
  final double? defaultLimit;
  final int? receiptMaxAgeDays;
  final bool isActive;

  const ReimbursementCategoryModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    this.description,
    required this.limitType,
    this.defaultLimit,
    this.receiptMaxAgeDays,
    required this.isActive,
  });

  factory ReimbursementCategoryModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementCategoryModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      limitType: json['limitType']?.toString() ?? 'unlimited',
      defaultLimit: (json['defaultLimit'] as num?)?.toDouble(),
      receiptMaxAgeDays: (json['receiptMaxAgeDays'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
