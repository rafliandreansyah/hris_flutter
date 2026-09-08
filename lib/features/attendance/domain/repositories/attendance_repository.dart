import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';

abstract class AttendanceRepository {
  /// Mengambil status absensi hari ini termasuk jadwal, info kantor, geofence, dan shift.
  Future<AttendanceTodayData> getTodayAttendance();

  /// Melakukan Clock In kehadiran.
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  });

  /// Melakukan Clock Out kehadiran.
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  });

  /// Melakukan Start/End Break kehadiran.
  Future<AttendanceTodayData> toggleBreak();

  /// Mengirim laporan kendala lokasi (Report Location Issue).
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  });
}
