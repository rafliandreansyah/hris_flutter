import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_response.dart';
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

  /// Melakukan Start/End Break kehadiran.
  Future<AttendanceTodayData> toggleBreak();

  /// Mengirim laporan kendala lokasi (Report Location Issue).
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
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

  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId});

  /// Mengambil detail presensi berdasarkan id.
  Future<AttendanceDetailModel> getAttendanceDetail(String id);
}
