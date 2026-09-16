import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

abstract class AttendanceRequestRepository {
  /// Mengambil daftar pengajuan presensi luar kantor dari backend.
  Future<AttendanceRequestListResponse> getAttendanceRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    bool approver = false,
  });
}
