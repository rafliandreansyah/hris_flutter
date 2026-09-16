import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

abstract class AttendanceRequestRemoteDataSource {
  /// Mengambil daftar pengajuan presensi luar kantor dari endpoint `GET /attendances/requests`.
  ///
  /// [approver] `false` = Pengajuan Saya, `true` = Persetujuan Tim (memerlukan hak akses approver).
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

class AttendanceRequestRemoteDataSourceImpl
    implements AttendanceRequestRemoteDataSource {
  final ApiClient _apiClient;

  AttendanceRequestRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
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
    if (status != null && status.trim().isNotEmpty && status != 'all') {
      queryParams['status'] = status.trim();
    } else if (status == 'all') {
      queryParams['status'] = 'all';
    } else {
      queryParams['status'] = 'requested';
    }
    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParams['startDate'] = startDate.trim();
    }
    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParams['endDate'] = endDate.trim();
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.attendanceRequests,
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return AttendanceRequestListResponse.fromJson(
          rawData,
          isApprover: approver,
        );
      }

      throw ApiException(
        message: 'Gagal memuat data pengajuan presensi.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 403) {
        throw ApiException(
          message: 'Tidak memiliki hak akses approver untuk pengajuan presensi tim.',
          statusCode: 403,
        );
      }
      throw ApiException.fromDioException(e);
    }
  }
}
