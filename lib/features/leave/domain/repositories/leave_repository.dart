import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';

/// Kontrak repositori leave request (domain layer) — memisahkan business
/// domain dari implementasi network.
abstract class LeaveRepository {
  /// Mengambil daftar pengajuan cuti/izin dari backend HRIS.
  ///
  /// `approver: false` untuk tab My Requests, `approver: true` untuk
  /// tab Team Requests (backend membalas 403 jika user bukan approver).
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  });
}
