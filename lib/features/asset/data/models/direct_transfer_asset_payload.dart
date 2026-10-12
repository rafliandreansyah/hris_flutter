import 'package:equatable/equatable.dart';

/// Payload data untuk alih tangan / direct handover ke rekan kerja (POST /api/v1/assets/:id/transfer)
class DirectTransferAssetPayload extends Equatable {
  final String targetEmployeeId;
  final DateTime assignedDate;
  final DateTime? expectedReturnDate;
  final String conditionOnCheckout;
  final String? checkoutNotes;
  final String? agreementUrl;
  final bool requireApproval;

  const DirectTransferAssetPayload({
    required this.targetEmployeeId,
    required this.assignedDate,
    this.expectedReturnDate,
    this.conditionOnCheckout = 'GOOD',
    this.checkoutNotes,
    this.agreementUrl,
    this.requireApproval = true,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'targetEmployeeId': targetEmployeeId,
      'assignedDate': assignedDate.toIso8601String(),
      'conditionOnCheckout': conditionOnCheckout,
      'requireApproval': requireApproval,
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
        requireApproval,
      ];
}
