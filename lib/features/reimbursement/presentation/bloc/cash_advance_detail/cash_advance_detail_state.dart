import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';

enum CashAdvanceDetailStatus { initial, loading, success, failure }

class CashAdvanceDetailState extends Equatable {
  final CashAdvanceDetailStatus status;
  final CashAdvanceDetailModel? detail;
  final bool isActionLoading;
  final String? actionSuccessMessage;
  final String? errorMessage;

  const CashAdvanceDetailState({
    this.status = CashAdvanceDetailStatus.initial,
    this.detail,
    this.isActionLoading = false,
    this.actionSuccessMessage,
    this.errorMessage,
  });

  bool get isActionSuccess => actionSuccessMessage != null;

  CashAdvanceDetailState copyWith({
    CashAdvanceDetailStatus? status,
    CashAdvanceDetailModel? detail,
    bool? isActionLoading,
    String? actionSuccessMessage,
    String? errorMessage,
    bool clearActionMessage = false,
    bool clearErrorMessage = false,
  }) {
    return CashAdvanceDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionSuccessMessage: clearActionMessage
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        detail,
        isActionLoading,
        actionSuccessMessage,
        errorMessage,
      ];
}
