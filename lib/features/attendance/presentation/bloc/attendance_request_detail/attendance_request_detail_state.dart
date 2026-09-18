import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';

enum AttendanceRequestDetailStatus {
  initial,
  loading,
  success,
  failure,
  submittingAction,
  actionSuccess,
  deleteSuccess,
  actionFailure,
}

class AttendanceRequestDetailState extends Equatable {
  final AttendanceRequestDetailStatus status;
  final String id;
  final bool isApprover;
  final AttendanceRequestDetailData? detail;
  final String? actionMessage;
  final String? errorMessage;
  final int? statusCode;

  const AttendanceRequestDetailState({
    this.status = AttendanceRequestDetailStatus.initial,
    this.id = '',
    this.isApprover = false,
    this.detail,
    this.actionMessage,
    this.errorMessage,
    this.statusCode,
  });

  AttendanceRequestDetailState copyWith({
    AttendanceRequestDetailStatus? status,
    String? id,
    bool? isApprover,
    AttendanceRequestDetailData? detail,
    String? actionMessage,
    String? errorMessage,
    int? statusCode,
  }) {
    return AttendanceRequestDetailState(
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
