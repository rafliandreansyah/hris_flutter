import 'package:equatable/equatable.dart';

/// Payload data untuk mendaftarkan unit master aset baru (POST /api/v1/assets)
class CreateAssetPayload extends Equatable {
  final String categoryId;
  final String assetCode;
  final String name;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchaseCost;
  final DateTime? warrantyExpiry;
  final String? vendor;
  final String? location;
  final String condition;
  final String? photoUrl;
  final String? notes;
  final String? assignedToEmployeeId;

  const CreateAssetPayload({
    required this.categoryId,
    required this.assetCode,
    required this.name,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchaseCost,
    this.warrantyExpiry,
    this.vendor,
    this.location,
    this.condition = 'GOOD',
    this.photoUrl,
    this.notes,
    this.assignedToEmployeeId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'categoryId': categoryId,
      'assetCode': assetCode.trim(),
      'name': name.trim(),
      'condition': condition,
    };

    if (brand != null && brand!.trim().isNotEmpty) {
      map['brand'] = brand!.trim();
    }
    if (model != null && model!.trim().isNotEmpty) {
      map['model'] = model!.trim();
    }
    if (serialNumber != null && serialNumber!.trim().isNotEmpty) {
      map['serialNumber'] = serialNumber!.trim();
    }
    if (purchaseDate != null) {
      map['purchaseDate'] = purchaseDate!.toIso8601String();
    }
    if (purchaseCost != null) {
      map['purchaseCost'] = purchaseCost;
    }
    if (warrantyExpiry != null) {
      map['warrantyExpiry'] = warrantyExpiry!.toIso8601String();
    }
    if (vendor != null && vendor!.trim().isNotEmpty) {
      map['vendor'] = vendor!.trim();
    }
    if (location != null && location!.trim().isNotEmpty) {
      map['location'] = location!.trim();
    }
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      map['photoUrl'] = photoUrl!.trim();
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      map['notes'] = notes!.trim();
    }
    if (assignedToEmployeeId != null && assignedToEmployeeId!.trim().isNotEmpty) {
      map['assignedToEmployeeId'] = assignedToEmployeeId!.trim();
    }

    return map;
  }

  @override
  List<Object?> get props => [
        categoryId,
        assetCode,
        name,
        brand,
        model,
        serialNumber,
        purchaseDate,
        purchaseCost,
        warrantyExpiry,
        vendor,
        location,
        condition,
        photoUrl,
        notes,
        assignedToEmployeeId,
      ];
}
