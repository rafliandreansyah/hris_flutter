import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

abstract class LeaveRemoteDataSource {
  /// Mengambil daftar pengajuan cuti/izin dari endpoint `GET /leave-request`.
  ///
  /// [approver] `false` = My Requests (pengajuan milik sendiri),
  /// `true` = Team Requests (butuh otoritas approver — backend bisa
  /// membalas HTTP 403 jika user bukan approver).
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  });

  /// Mengambil detail pengajuan cuti/izin berdasarkan ID dari `GET /leave-request/{id}`.
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id);

  /// Menyetujui atau menolak pengajuan cuti melalui `PATCH /leave-request/{id}/approve`.
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  });

  /// Menghapus pengajuan cuti milik sendiri melalui `DELETE /leave-request/{id}`.
  Future<void> deleteLeaveRequest(String id);

  /// Mengambil daftar opsi jenis cuti/izin dari `GET /leave-request/types`.
  Future<List<LeaveTypeOptionModel>> getLeaveTypes();

  /// Mengirim pengajuan cuti/izin baru ke `POST /leave-request` (multipart/form-data).
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  });
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final ApiClient _apiClient;

  LeaveRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
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
    if (statusApprove != null && statusApprove.trim().isNotEmpty) {
      queryParams['statusApprove'] = statusApprove.trim();
    }
    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParams['startDate'] = startDate.trim();
    }
    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParams['endDate'] = endDate.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.leaveRequest,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return LeaveRequestListResponse.fromJson(rawData, isApprover: approver);
    }

    throw ApiException(
      message: 'Gagal memuat data pengajuan cuti.',
    );
  }

  @override
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id) async {
    final response = await _apiClient.get(
      ApiEndpoints.leaveRequestDetail(id),
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final detailResponse = LeaveRequestDetailResponse.fromJson(rawData);
      return detailResponse.data;
    }

    throw ApiException(
      message: 'Gagal memuat detail pengajuan cuti.',
    );
  }

  @override
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  }) async {
    final payload = <String, dynamic>{
      'isApproved': isApproved,
      'approverNotes': approverNotes ?? '',
    };

    await _apiClient.patch(
      ApiEndpoints.leaveRequestApprove(id),
      data: payload,
    );
  }

  @override
  Future<void> deleteLeaveRequest(String id) async {
    await _apiClient.delete(
      ApiEndpoints.leaveRequestDetail(id),
    );
  }

  @override
  Future<List<LeaveTypeOptionModel>> getLeaveTypes() async {
    final response = await _apiClient.get(
      ApiEndpoints.leaveTypes,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final list = rawData['data'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => LeaveTypeOptionModel.fromJson(e))
            .toList();
      }
      return [];
    }

    throw ApiException(
      message: 'Gagal memuat jenis cuti.',
    );
  }

  @override
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  }) async {
    final map = <String, dynamic>{
      'leaveTypeId': leaveTypeId.trim(),
      'startDate': startDate.trim(),
      'totalDays': totalDays.toString(),
      'notes': notes.trim(),
    };

    if (file != null) {
      final fileName = file.name.isNotEmpty
          ? file.name
          : file.path.split(RegExp(r'[/\\]')).last;
      map['file'] = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(map);

    final response = await _apiClient.post(
      ApiEndpoints.leaveRequest,
      data: formData,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return CreateLeaveResultModel.fromJson(rawData);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal membuat pengajuan cuti.'
          : 'Gagal membuat pengajuan cuti.',
    );
  }
}
