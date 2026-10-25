import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';

enum ReimbursementDetailStatus { initial, loading, success, failure }

class ReimbursementDetailState extends Equatable {
  final ReimbursementDetailStatus status;
  final ReimbursementDetailModel? detail;
  final bool isActionLoading;
  final String? actionSuccessMessage;
  final String? errorMessage;

  /// True setelah pengajuan berhasil dihapus; layar menutup halaman detail.
  final bool isDeleted;

  const ReimbursementDetailState({
    this.status = ReimbursementDetailStatus.initial,
    this.detail,
    this.isActionLoading = false,
    this.actionSuccessMessage,
    this.errorMessage,
    this.isDeleted = false,
  });

  bool get isActionSuccess => actionSuccessMessage != null;

  ReimbursementDetailState copyWith({
    ReimbursementDetailStatus? status,
    ReimbursementDetailModel? detail,
    bool? isActionLoading,
    String? actionSuccessMessage,
    String? errorMessage,
    bool? isDeleted,
    bool clearActionMessage = false,
    bool clearErrorMessage = false,
  }) {
    return ReimbursementDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionSuccessMessage: clearActionMessage
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
        status,
        detail,
        isActionLoading,
        actionSuccessMessage,
        errorMessage,
        isDeleted,
      ];
}
