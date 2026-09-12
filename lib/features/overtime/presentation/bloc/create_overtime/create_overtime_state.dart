import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';

enum CreateOvertimeStatus {
  initial,
  loadingSchedule,
  scheduleLoaded,
  submitting,
  success,
  failure,
}

enum OvertimeTypeCategory {
  preShift,
  postShift,
  dayOff,
}

class CreateOvertimeState extends Equatable {
  final CreateOvertimeStatus status;
  final DateTime? startOvertime;
  final DateTime? endOvertime;
  final OvertimeTypeCategory category;
  final bool isEndTimeLocked;
  final bool isCheckOutRequiredBlocked;
  final OvertimeScheduleData? scheduleData;
  final String successMessage;
  final String errorMessage;
  final int? statusCode;
  final String createdId;

  const CreateOvertimeState({
    this.status = CreateOvertimeStatus.initial,
    this.startOvertime,
    this.endOvertime,
    this.category = OvertimeTypeCategory.postShift,
    this.isEndTimeLocked = false,
    this.isCheckOutRequiredBlocked = false,
    this.scheduleData,
    this.successMessage = '',
    this.errorMessage = '',
    this.statusCode,
    this.createdId = '',
  });

  /// Durasi selisih antara waktu mulai dan waktu selesai.
  Duration get duration {
    final start = startOvertime;
    final end = endOvertime;
    if (start != null && end != null && end.isAfter(start)) {
      return end.difference(start);
    }
    return Duration.zero;
  }

  /// Label durasi terformat, misal: "4 Jam (4.0 Hours)" atau "2 Jam 30 Menit (2.5 Hours)".
  String get durationLabel {
    final diff = duration;
    if (diff == Duration.zero) return '0 Jam (0.0 Hours)';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final fraction = (diff.inMinutes / 60.0).toStringAsFixed(1);
    if (minutes == 0) {
      return '$hours Jam ($fraction Hours)';
    }
    return '$hours Jam $minutes Menit ($fraction Hours)';
  }

  /// Validasi apakah formulir siap disubmit dari sisi jadwal & status blokir.
  bool get canSubmit {
    if (status == CreateOvertimeStatus.submitting) return false;
    if (isCheckOutRequiredBlocked) return false;
    final start = startOvertime;
    final end = endOvertime;
    if (start == null || end == null) return false;
    return end.isAfter(start);
  }

  CreateOvertimeState copyWith({
    CreateOvertimeStatus? status,
    DateTime? startOvertime,
    DateTime? endOvertime,
    OvertimeTypeCategory? category,
    bool? isEndTimeLocked,
    bool? isCheckOutRequiredBlocked,
    OvertimeScheduleData? scheduleData,
    bool clearScheduleData = false,
    String? successMessage,
    String? errorMessage,
    int? statusCode,
    String? createdId,
  }) {
    return CreateOvertimeState(
      status: status ?? this.status,
      startOvertime: startOvertime ?? this.startOvertime,
      endOvertime: endOvertime ?? this.endOvertime,
      category: category ?? this.category,
      isEndTimeLocked: isEndTimeLocked ?? this.isEndTimeLocked,
      isCheckOutRequiredBlocked:
          isCheckOutRequiredBlocked ?? this.isCheckOutRequiredBlocked,
      scheduleData:
          clearScheduleData ? null : (scheduleData ?? this.scheduleData),
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCode: statusCode ?? this.statusCode,
      createdId: createdId ?? this.createdId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        startOvertime,
        endOvertime,
        category,
        isEndTimeLocked,
        isCheckOutRequiredBlocked,
        scheduleData,
        successMessage,
        errorMessage,
        statusCode,
        createdId,
      ];
}
