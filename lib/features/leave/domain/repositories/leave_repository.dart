import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

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

  /// Mengambil detail pengajuan cuti/izin berdasarkan ID.
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id);

  /// Menyetujui atau menolak pengajuan cuti.
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  });

  /// Menghapus pengajuan cuti milik sendiri.
  Future<void> deleteLeaveRequest(String id);

  /// Mengambil daftar opsi jenis cuti/izin.
  Future<List<LeaveTypeOptionModel>> getLeaveTypes();

  /// Mengirim pengajuan cuti/izin baru.
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  });
}
