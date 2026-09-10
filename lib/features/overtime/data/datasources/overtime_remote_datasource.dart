import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

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
  });
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
    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParams['startDate'] = startDate.trim();
    }
    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParams['endDate'] = endDate.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
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
}
