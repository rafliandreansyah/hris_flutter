import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';

enum AssetDetailStatus { initial, loading, success, failure }

enum AssetDetailActionStatus { idle, loading, success, failure }

class AssetDetailState extends Equatable {
  final AssetDetailStatus status;
  final AssetDetailActionStatus actionStatus;
  final AssetDetailData? asset;
  final String? errorMessage;
  final String? actionMessage;
  final bool canHandover;
  final bool canCreate;
  final String? currentEmployeeId;

  const AssetDetailState({
    this.status = AssetDetailStatus.initial,
    this.actionStatus = AssetDetailActionStatus.idle,
    this.asset,
    this.errorMessage,
    this.actionMessage,
    this.canHandover = false,
    this.canCreate = false,
    this.currentEmployeeId,
  });

  /// Apakah user yang login adalah pemegang aktif saat ini
  bool get isCurrentHolder {
    if (asset == null || currentEmployeeId == null) return false;
    final active = asset!.activeAssignment;
    return active != null && active.employeeId == currentEmployeeId;
  }

  /// Apakah user yang login adalah penerima penugasan pending
  bool get isPendingRecipient {
    if (asset == null || currentEmployeeId == null) return false;
    final pending = asset!.pendingAssignment;
    return pending != null && pending.employeeId == currentEmployeeId;
  }

  /// Apakah aset siap diserahterimakan dari gudang
  bool get isAvailableInWarehouse => asset?.isAvailableInWarehouse ?? false;

  AssetDetailState copyWith({
    AssetDetailStatus? status,
    AssetDetailActionStatus? actionStatus,
    AssetDetailData? asset,
    String? errorMessage,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
    bool? canHandover,
    bool? canCreate,
    String? currentEmployeeId,
  }) {
    return AssetDetailState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      asset: asset ?? this.asset,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      canHandover: canHandover ?? this.canHandover,
      canCreate: canCreate ?? this.canCreate,
      currentEmployeeId: currentEmployeeId ?? this.currentEmployeeId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        asset,
        errorMessage,
        actionMessage,
        canHandover,
        canCreate,
        currentEmployeeId,
      ];
}
