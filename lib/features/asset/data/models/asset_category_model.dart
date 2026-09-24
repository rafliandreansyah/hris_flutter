import 'package:equatable/equatable.dart';

/// Model representasi kategori aset dari endpoint GET /api/v1/assets/categories.
class AssetCategoryModel extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String code;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssetCategoryModel({
    required this.id,
    this.companyId = '',
    required this.name,
    required this.code,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory AssetCategoryModel.fromJson(Map<String, dynamic> json) {
    return AssetCategoryModel(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'code': code,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, companyId, name, code, description];
}
