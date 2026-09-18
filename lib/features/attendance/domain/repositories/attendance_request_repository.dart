import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';

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

  /// Mengambil detail permohonan presensi luar kantor dari backend.
  Future<AttendanceRequestDetailData> getAttendanceRequestDetail(String id);

  /// Menyetujui atau menolak permohonan presensi luar kantor.
  Future<void> approveAttendanceRequest({
    required String id,
    required bool isApproved,
    String? approverNotes,
  });

  /// Menghapus permohonan presensi luar kantor.
  Future<void> deleteAttendanceRequest(String id);

  /// Mengirimkan permohonan live attendance ke backend.
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  );

  /// Mengirimkan permohonan schedule attendance ke backend.
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  );
}
