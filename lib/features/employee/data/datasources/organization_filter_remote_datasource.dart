import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';

abstract class OrganizationFilterRemoteDataSource {
  Future<List<CompanyItem>> getCompanies({String? search});
  Future<List<DepartmentItem>> getDepartments({
    String? companyId,
    String? search,
  });
  Future<List<PositionItem>> getPositions({
    String? companyId,
    String? departmentId,
    String? search,
  });
}

class OrganizationFilterRemoteDataSourceImpl
    implements OrganizationFilterRemoteDataSource {
  final ApiClient _apiClient;

  OrganizationFilterRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<List<CompanyItem>> getCompanies({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.companies,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      final list = rawData['data'] as List;
      return list
          .map((item) => CompanyItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat data perusahaan.'
          : 'Gagal memuat data perusahaan.',
    );
  }

  @override
  Future<List<DepartmentItem>> getDepartments({
    String? companyId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (companyId != null && companyId.trim().isNotEmpty) {
      queryParams['companyId'] = companyId.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.departments,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      final list = rawData['data'] as List;
      return list
          .map((item) => DepartmentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat data departemen.'
          : 'Gagal memuat data departemen.',
    );
  }

  @override
  Future<List<PositionItem>> getPositions({
    String? companyId,
    String? departmentId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (companyId != null && companyId.trim().isNotEmpty) {
      queryParams['companyId'] = companyId.trim();
    }
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      queryParams['departmentId'] = departmentId.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.positions,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      final list = rawData['data'] as List;
      return list
          .map((item) => PositionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat data jabatan.'
          : 'Gagal memuat data jabatan.',
    );
  }
}
