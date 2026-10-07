import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

enum LeaveDetailStatus {
  initial,
  loading,
  success,
  failure,
  submittingAction,
  actionSuccess,
  deleteSuccess,
  actionFailure,
}

class LeaveDetailState extends Equatable {
  final LeaveDetailStatus status;
  final String id;
  final bool isApprover;
  final bool canApproveAction;
  final LeaveRequestDetailData? detail;
  final String? actionMessage;
  final String? errorMessage;
  final int? statusCode;

  const LeaveDetailState({
    this.status = LeaveDetailStatus.initial,
    this.id = '',
    this.isApprover = false,
    this.canApproveAction = false,
    this.detail,
    this.actionMessage,
    this.errorMessage,
    this.statusCode,
  });

  LeaveDetailState copyWith({
    LeaveDetailStatus? status,
    String? id,
    bool? isApprover,
    bool? canApproveAction,
    LeaveRequestDetailData? detail,
    String? actionMessage,
    String? errorMessage,
    int? statusCode,
  }) {
    return LeaveDetailState(
      status: status ?? this.status,
      id: id ?? this.id,
      isApprover: isApprover ?? this.isApprover,
      canApproveAction: canApproveAction ?? this.canApproveAction,
      detail: detail ?? this.detail,
      actionMessage: actionMessage,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        id,
        isApprover,
        canApproveAction,
        detail,
        actionMessage,
        errorMessage,
        statusCode,
      ];
}
