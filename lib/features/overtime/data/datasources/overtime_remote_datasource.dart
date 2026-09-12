import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';

abstract class OvertimeRemoteDataSource {
  /// Mengambil daftar permintaan lembur dari endpoint `GET /overtime`.
  ///
  /// [approver] `false` = My Overtime (permintaan milik sendiri),
  /// `true` = Team Overtime (butuh otoritas approver — backend bisa
  /// membalas HTTP 403 jika user bukan approver).
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    required int size,
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

  /// Mengambil informasi jadwal kerja dan status presensi untuk waktu mulai lembur.
  /// Dipanggil ke endpoint `GET /overtime/schedule?dateTimeStart=...`.
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  });

  /// Mengirimkan permohonan lembur baru ke endpoint `POST /overtime` (multipart/form-data).
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  });

  /// Mengambil data detail pengajuan lembur dari `GET /overtime/{id}`.
  Future<OvertimeDetailData> getOvertimeDetail(String id);

  /// Menyetujui atau menolak pengajuan lembur pada `PATCH /overtime/{id}/approve`.
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  });

  /// Menghapus permohonan lembur pada `DELETE /overtime/{id}`.
  Future<void> deleteOvertime(String id);
}

class OvertimeRemoteDataSourceImpl implements OvertimeRemoteDataSource {
  final ApiClient _apiClient;

  OvertimeRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
    @Deprecated('Gunakan status') String? statusApprove,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'approver': approver,
    };

    if (companyId != null && companyId.trim().isNotEmpty) {
      queryParams['companyId'] = companyId.trim();
    }
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      queryParams['departmentId'] = departmentId.trim();
    }
    if (positionId != null && positionId.trim().isNotEmpty) {
      queryParams['positionId'] = positionId.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    final effectiveStatus = status ?? statusApprove;
    final resolvedStatus = _resolveOvertimeStatus(effectiveStatus);
    queryParams['status'] = resolvedStatus;
    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParams['startDate'] = startDate.trim();
    }
    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParams['endDate'] = endDate.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.overtime,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return OvertimeRequestListResponse.fromJson(rawData, isApprover: approver);
    }

    throw ApiException(
      message: 'Gagal memuat data permintaan lembur.',
    );
  }

  @override
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.overtimeSchedule,
      queryParameters: {'dateTimeStart': dateTimeStart.trim()},
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final res = OvertimeScheduleResponse.fromJson(rawData);
      return res.data;
    }

    throw ApiException(
      message: 'Gagal memuat informasi jadwal lembur.',
    );
  }

  @override
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  }) async {
    final map = <String, dynamic>{
      'startOvertime': startOvertime.trim(),
      'endOvertime': endOvertime.trim(),
      'notes': notes.trim(),
    };

    if (workScheduleId != null && workScheduleId.trim().isNotEmpty) {
      map['workScheduleId'] = workScheduleId.trim();
    }

    final fileName = file.name.isNotEmpty
        ? file.name
        : file.path.split(RegExp(r'[/\\]')).last;
    map['file'] = await MultipartFile.fromFile(
      file.path,
      filename: fileName,
    );

    final formData = FormData.fromMap(map);

    final response = await _apiClient.post(
      ApiEndpoints.overtime,
      data: formData,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return CreateOvertimeResultModel.fromJson(rawData);
    }

    throw ApiException(
      message: 'Gagal mengirim pengajuan lembur.',
    );
  }

  @override
  Future<OvertimeDetailData> getOvertimeDetail(String id) async {
    final response = await _apiClient.get(
      ApiEndpoints.overtimeDetail(id),
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final res = OvertimeDetailResponse.fromJson(rawData);
      return res.data;
    }

    throw ApiException(
      message: 'Gagal memuat detail pengajuan lembur.',
    );
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    final payload = OvertimeApprovePayload(
      isApproved: isApproved,
      approverNotes: approverNotes,
    );

    await _apiClient.patch(
      ApiEndpoints.overtimeApprove(id),
      data: payload.toJson(),
    );
  }

  @override
  Future<void> deleteOvertime(String id) async {
    await _apiClient.delete(
      ApiEndpoints.overtimeDetail(id),
    );
  }

  static String _resolveOvertimeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return 'all';
    final s = status.trim().toLowerCase();
    if (s == 'all' || s == 'semua') return 'all';
    if (s == 'pending' || s == 'requested') return 'requested';
    if (s == 'approved') return 'approved';
    if (s == 'rejected') return 'rejected';
    return s;
  }
}
