import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';

enum WorkScheduleStatus { initial, loading, success, failure }

class WorkScheduleState extends Equatable {
  final WorkScheduleStatus status;
  final WorkScheduleData? data;
  final DateTime selectedDate;
  final String? employeeId;
  final String? errorMessage;

  WorkScheduleState({
    this.status = WorkScheduleStatus.initial,
    this.data,
    DateTime? selectedDate,
    this.employeeId,
    this.errorMessage,
  }) : selectedDate = selectedDate != null
            ? DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              )
            : DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              );

  bool get isViewingOtherEmployee =>
      employeeId != null && employeeId!.trim().isNotEmpty;

  /// Jadwal yang cocok tepat dengan tanggal terpilih
  WorkScheduleItem? get selectedSchedule {
    if (data == null) return null;
    for (final item in data!.workSchedules) {
      if (item.isSameDay(selectedDate)) {
        return item;
      }
    }
    return null;
  }

  /// Daftar jadwal setelah tanggal terpilih secara kronologis
  List<WorkScheduleItem> get upcomingSchedules {
    if (data == null) return const [];
    final selectedStartOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final upcoming = data!.workSchedules.where((item) {
      final dt = item.parsedDate;
      if (dt == null) return false;
      final itemStartOfDay = DateTime(dt.year, dt.month, dt.day);
      return itemStartOfDay.isAfter(selectedStartOfDay);
    }).toList();

    upcoming.sort((a, b) {
      final da = a.parsedDate;
      final db = b.parsedDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return upcoming;
  }

  WorkScheduleState copyWith({
    WorkScheduleStatus? status,
    WorkScheduleData? data,
    DateTime? selectedDate,
    String? employeeId,
    String? errorMessage,
  }) {
    return WorkScheduleState(
      status: status ?? this.status,
      data: data ?? this.data,
      selectedDate: selectedDate ?? this.selectedDate,
      employeeId: employeeId ?? this.employeeId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        selectedDate,
        employeeId,
        errorMessage,
      ];
}
