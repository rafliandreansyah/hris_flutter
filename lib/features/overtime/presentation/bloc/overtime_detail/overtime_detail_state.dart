import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';

enum OvertimeDetailStatus {
  initial,
  loading,
  success,
  failure,
  submittingAction,
  actionSuccess,
  deleteSuccess,
  actionFailure,
}

class OvertimeDetailState extends Equatable {
  final OvertimeDetailStatus status;
  final String id;
  final bool isApprover;
  final OvertimeDetailData? detail;
  final String? actionMessage;
  final String? errorMessage;
  final int? statusCode;

  const OvertimeDetailState({
    this.status = OvertimeDetailStatus.initial,
    this.id = '',
    this.isApprover = false,
    this.detail,
    this.actionMessage,
    this.errorMessage,
    this.statusCode,
  });

  OvertimeDetailState copyWith({
    OvertimeDetailStatus? status,
    String? id,
    bool? isApprover,
    OvertimeDetailData? detail,
    String? actionMessage,
    String? errorMessage,
    int? statusCode,
  }) {
    return OvertimeDetailState(
      status: status ?? this.status,
      id: id ?? this.id,
      isApprover: isApprover ?? this.isApprover,
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
        detail,
        actionMessage,
        errorMessage,
        statusCode,
      ];
}
