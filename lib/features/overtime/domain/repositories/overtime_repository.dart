import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

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
  });
}
