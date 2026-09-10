import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';

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
}
