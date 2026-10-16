import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_break.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:image_picker/image_picker.dart';

abstract class AttendanceRepository {
  /// Mengambil status absensi hari ini termasuk jadwal, info kantor, geofence, dan shift.
  Future<AttendanceTodayData> getTodayAttendance();

  /// Mencatat presensi kehadiran ke API `POST /attendances` (metode foto atau biometrik).
  Future<CreateAttendanceResponse> recordAttendance(CreateAttendanceRequest request);

  /// Melakukan Clock In kehadiran.
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
    String attendanceMethod = 'photo',
    String? workLocationId,
    XFile? photoFile,
  });

  /// Melakukan Clock Out kehadiran.
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
    String attendanceMethod = 'photo',
    String? workLocationId,
    XFile? photoFile,
  });

  /// Status & daftar istirahat hari ini (`GET /attendances/break/today`).
  Future<AttendanceBreakStatus> getBreakStatus();

  /// Memulai istirahat (`POST /attendances/break/start`). Mengembalikan status terbaru.
  Future<AttendanceBreakStatus> startBreak({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? address,
    String? note,
    String? workLocationId,
  });

  /// Mengakhiri istirahat (`POST /attendances/break/end`). Mengembalikan status terbaru.
  Future<AttendanceBreakStatus> endBreak({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? address,
    String? note,
    String? workLocationId,
  });

  Future<AttendanceLogListResponse> getAttendanceLogs({
    String? employeeId,
    bool lastMonth = false,
    int page = 1,
    int size = 20,
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  });

  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees();


  /// Mengambil detail presensi berdasarkan id.
  Future<AttendanceDetailModel> getAttendanceDetail(String id);

  /// Mengupdate lokasi kerja default karyawan via API.
  Future<String> setDefaultWorkLocation({
    String? workLocationId,
    String? employeeWorkLocationId,
  });
}
