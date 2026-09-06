import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';

abstract class EmployeeRemoteDataSource {
  /// Mengambil daftar pegawai dari endpoint `/employee`.
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  });

  /// Mengambil detail pegawai dari endpoint `/employee/{id}`.
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId);
}

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final ApiClient _apiClient;

  EmployeeRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
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

    final response = await _apiClient.get(
      ApiEndpoints.employee,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return EmployeeListResponse.fromJson(rawData);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat data pegawai.'
          : 'Gagal memuat data pegawai.',
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.employee}/$employeeId',
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>) {
      return EmployeeDetailData.fromJson(rawData['data'] as Map<String, dynamic>);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat detail pegawai.'
          : 'Gagal memuat detail pegawai.',
    );
  }
}
