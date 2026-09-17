import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

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

  /// Mengambil daftar rekan kerja (coworkers) dari endpoint `/employee/coworkers`.
  Future<List<EmployeeDirectoryItem>> getCoworkers();

  /// Memperbarui password pegawai dari endpoint `/employee/update-password`.
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  });
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

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    final response = await _apiClient.get(
      ApiEndpoints.employeeCoworkers,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      final list = rawData['data'] as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => EmployeeDirectoryItem.fromJson(item))
          .toList();
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat rekan kerja.'
          : 'Gagal memuat rekan kerja.',
    );
  }

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.employeeUpdatePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      if (rawData['success'] == true) {
        return rawData['message']?.toString() ?? 'Password berhasil diperbarui.';
      }
      throw ApiException(
        message: rawData['message']?.toString() ?? 'Gagal memperbarui password.',
      );
    }

    return 'Password berhasil diperbarui.';
  }
}
