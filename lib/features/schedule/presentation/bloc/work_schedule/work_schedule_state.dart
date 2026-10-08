import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';

enum WorkScheduleStatus { initial, loading, success, failure }

class WorkScheduleState extends Equatable {
  final WorkScheduleStatus status;
  final WorkScheduleData? data;
  final DateTime selectedDate;
  final String? employeeId;
  final String? errorMessage;
  final int? statusCode;

  WorkScheduleState({
    this.status = WorkScheduleStatus.initial,
    this.data,
    DateTime? selectedDate,
    this.employeeId,
    this.errorMessage,
    this.statusCode,
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

  /// Menandakan resource tidak ditemukan (404 Not Found)
  bool get isNotFound => statusCode == 404;

  /// Menandakan bahwa pegawai belum memiliki jadwal sama sekali
  /// (baik karena 404 dari server, data null, atau daftar jadwal kosong)
  bool get hasNoSchedules {
    if (status == WorkScheduleStatus.failure && isNotFound) return true;
    if (status == WorkScheduleStatus.success) {
      return data == null || data!.workSchedules.isEmpty;
    }
    return false;
  }

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

  /// Jadwal aktif terdekat berikutnya untuk navigasi cerdas
  WorkScheduleItem? get nextClosestSchedule {
    final upcoming = upcomingSchedules;
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }
    return null;
  }

  WorkScheduleState copyWith({
    WorkScheduleStatus? status,
    WorkScheduleData? data,
    DateTime? selectedDate,
    String? employeeId,
    String? errorMessage,
    int? statusCode,
    bool clearStatusDetails = false,
  }) {
    return WorkScheduleState(
      status: status ?? this.status,
      data: data ?? this.data,
      selectedDate: selectedDate ?? this.selectedDate,
      employeeId: employeeId ?? this.employeeId,
      errorMessage: clearStatusDetails ? null : (errorMessage ?? this.errorMessage),
      statusCode: clearStatusDetails ? null : (statusCode ?? this.statusCode),
    );
  }

  @override
  List<Object?> get props => [
        status,
        data,
        selectedDate,
        employeeId,
        errorMessage,
        statusCode,
      ];
}
