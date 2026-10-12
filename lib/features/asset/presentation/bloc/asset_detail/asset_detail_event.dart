import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';

abstract class AssetDetailEvent extends Equatable {
  const AssetDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman detail aset dibuka
class AssetDetailStarted extends AssetDetailEvent {
  final String assetId;

  const AssetDetailStarted(this.assetId);

  @override
  List<Object?> get props => [assetId];
}

/// Event refresh detail aset
class AssetDetailRefreshed extends AssetDetailEvent {
  const AssetDetailRefreshed();
}

/// Event penerima konfirmasi persetujuan alih tangan (Approve)
class AssetDetailAssignmentApproved extends AssetDetailEvent {
  final String assignmentId;
  final String? conditionOnCheckin;
  final String? notes;
  final String? signatureUrl;
  final String? handoverPhotoUrl;

  const AssetDetailAssignmentApproved({
    required this.assignmentId,
    this.conditionOnCheckin,
    this.notes,
    this.signatureUrl,
    this.handoverPhotoUrl,
  });

  @override
  List<Object?> get props => [
        assignmentId,
        conditionOnCheckin,
        notes,
        signatureUrl,
        handoverPhotoUrl,
      ];
}

/// Event penerima menolak penyerahan fasilitas (Reject)
class AssetDetailAssignmentRejected extends AssetDetailEvent {
  final String assignmentId;
  final String reason;

  const AssetDetailAssignmentRejected({
    required this.assignmentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [assignmentId, reason];
}

/// Event pemegang aktif mengoper fasilitas ke rekan kerja (Direct Transfer)
class AssetDetailDirectTransferred extends AssetDetailEvent {
  final DirectTransferAssetPayload payload;

  const AssetDetailDirectTransferred(this.payload);

  @override
  List<Object?> get props => [payload];
}

/// Event serah terima unit dari gudang pool ke karyawan (Handover)
class AssetDetailPoolHandedOver extends AssetDetailEvent {
  final HandoverAssetPayload payload;

  const AssetDetailPoolHandedOver(this.payload);

  @override
  List<Object?> get props => [payload];
}
