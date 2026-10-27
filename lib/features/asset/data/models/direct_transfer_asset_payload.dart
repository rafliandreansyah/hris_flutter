import 'package:equatable/equatable.dart';

/// Payload data untuk alih tangan ke pegawai lain (POST /api/v1/assets/:id/transfer).
/// Selalu membutuhkan konfirmasi penerima.
class DirectTransferAssetPayload extends Equatable {
  final String targetEmployeeId;
  final DateTime assignedDate;
  final DateTime? expectedReturnDate;
  final String conditionOnCheckout;
  final String? checkoutNotes;
  final String? agreementUrl;

  const DirectTransferAssetPayload({
    required this.targetEmployeeId,
    required this.assignedDate,
    this.expectedReturnDate,
    this.conditionOnCheckout = 'GOOD',
    this.checkoutNotes,
    this.agreementUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'targetEmployeeId': targetEmployeeId,
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
        targetEmployeeId,
        assignedDate,
        expectedReturnDate,
        conditionOnCheckout,
        checkoutNotes,
        agreementUrl,
      ];
}
