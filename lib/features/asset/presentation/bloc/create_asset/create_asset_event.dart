import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';

abstract class CreateAssetEvent extends Equatable {
  const CreateAssetEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman pendaftaran aset dibuka (muat kategori)
class CreateAssetStarted extends CreateAssetEvent {
  const CreateAssetStarted();
}

/// Event saat form pendaftaran aset disubmit
class CreateAssetSubmitted extends CreateAssetEvent {
  final CreateAssetPayload payload;

  const CreateAssetSubmitted(this.payload);

  @override
  List<Object?> get props => [payload];
}
