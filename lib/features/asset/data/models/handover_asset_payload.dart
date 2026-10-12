import 'package:equatable/equatable.dart';

/// Payload data untuk serah terima unit dari gudang ke karyawan (POST /api/v1/assets/:id/handover)
class HandoverAssetPayload extends Equatable {
  final String employeeId;
  final DateTime assignedDate;
  final DateTime? expectedReturnDate;
  final String conditionOnCheckout;
  final String? checkoutNotes;
  final String? agreementUrl;

  const HandoverAssetPayload({
    required this.employeeId,
    required this.assignedDate,
    this.expectedReturnDate,
    this.conditionOnCheckout = 'GOOD',
    this.checkoutNotes,
    this.agreementUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'employeeId': employeeId,
      'assignedDate': assignedDate.toIso8601String(),
      'conditionOnCheckout': conditionOnCheckout,
    };

    if (expectedReturnDate != null) {
      map['expectedReturnDate'] = expectedReturnDate!.toIso8601String();
    }
    if (checkoutNotes != null && checkoutNotes!.trim().isNotEmpty) {
      map['checkoutNotes'] = checkoutNotes!.trim();
    }
    if (agreementUrl != null && agreementUrl!.trim().isNotEmpty) {
      map['agreementUrl'] = agreementUrl!.trim();
    }

    return map;
  }

  @override
  List<Object?> get props => [
        employeeId,
        assignedDate,
        expectedReturnDate,
        conditionOnCheckout,
        checkoutNotes,
        agreementUrl,
      ];
}
