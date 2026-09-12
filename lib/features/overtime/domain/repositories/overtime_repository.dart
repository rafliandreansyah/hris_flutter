import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:image_picker/image_picker.dart';

/// Kontrak repositori overtime request (domain layer) — memisahkan business
/// domain dari implementasi network.
abstract class OvertimeRepository {
  /// Mengambil daftar permintaan lembur dari backend HRIS.
  ///
  /// `approver: false` untuk tab My Overtime, `approver: true` untuk
  /// tab Team Overtime (backend membalas 403 jika user bukan approver).
  ///
  /// [status] filter status pengajuan: 'requested', 'approved',
  /// atau 'rejected' (null = semua status).
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
    @Deprecated('Gunakan status') String? statusApprove,
  });

  /// Mengambil informasi jadwal dan presensi untuk waktu mulai lembur.
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  });

  /// Mengirimkan formulir pengajuan lembur baru.
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  });

  /// Mengambil rincian lengkap pengajuan lembur.
  Future<OvertimeDetailData> getOvertimeDetail(String id);

  /// Menyetujui atau menolak permohonan lembur dengan catatan approver.
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  });

  /// Menghapus permohonan lembur milik sendiri yang berstatus pending/requested.
  Future<void> deleteOvertime(String id);
}
