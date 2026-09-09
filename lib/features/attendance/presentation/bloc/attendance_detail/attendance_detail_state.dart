import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';

enum AttendanceDetailStatus { initial, loading, success, failure }

class AttendanceDetailState extends Equatable {
  final AttendanceDetailStatus status;
  final AttendanceDetailModel? detail;
  final String? errorMessage;
  final int? statusCode;

  const AttendanceDetailState({
    this.status = AttendanceDetailStatus.initial,
    this.detail,
    this.errorMessage,
    this.statusCode,
  });

  bool get isNotFound => statusCode == 404;
  bool get isForbidden => statusCode == 403;

  AttendanceDetailState copyWith({
    AttendanceDetailStatus? status,
    AttendanceDetailModel? detail,
    String? errorMessage,
    int? statusCode,
    bool clearError = false,
  }) {
    return AttendanceDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusCode: clearError ? null : (statusCode ?? this.statusCode),
    );
  }

  @override
  List<Object?> get props => [status, detail, errorMessage, statusCode];
}
