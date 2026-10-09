import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';

abstract class PayrollRemoteDataSource {
  Future<PayrollListResponseModel> getMyPayslips({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
  });

  Future<PayrollListResponseModel> getPayrolls({
    int page = 1,
    int size = 10,
    String? employeeId,
    String? companyId,
    String? departmentId,
    String? payrollPeriodId,
    int? year,
    int? month,
    String? status,
    String? search,
  });

  Future<PayrollEmployeeListResponseModel> getPayrollEmployees({
    int page = 1,
    int size = 20,
    String? search,
    String? companyId,
    String? departmentId,
    String? status,
  });

  Future<List<PayrollPeriodModel>> getPayrollPeriods({
    String? companyId,
    String? status,
    int? year,
  });

  Future<PayrollDetailModel> getPayrollDetail(String id);

  Future<PayrollDownloadResponseModel> downloadPayslip(
    String id, {
    bool force = false,
  });
}

class PayrollRemoteDataSourceImpl implements PayrollRemoteDataSource {
  final ApiClient _apiClient;

  PayrollRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<PayrollListResponseModel> getMyPayslips({
    int page = 1,
    int size = 10,
    int? year,
    int? month,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'year': ?year,
        'month': ?month,
      };

      final response = await _apiClient.get(
        ApiEndpoints.myPayslips,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      return PayrollListResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<PayrollListResponseModel> getPayrolls({
    int page = 1,
    int size = 10,
    String? employeeId,
    String? companyId,
    String? departmentId,
    String? payrollPeriodId,
    int? year,
    int? month,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        if (employeeId != null && employeeId.isNotEmpty)
          'employeeId': employeeId,
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
        if (departmentId != null && departmentId.isNotEmpty)
          'departmentId': departmentId,
        if (payrollPeriodId != null && payrollPeriodId.isNotEmpty)
          'payrollPeriodId': payrollPeriodId,
        'year': ?year,
        'month': ?month,
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      };

      final response = await _apiClient.get(
        ApiEndpoints.payrolls,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      return PayrollListResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }


  @override
  Future<PayrollEmployeeListResponseModel> getPayrollEmployees({
    int page = 1,
    int size = 20,
    String? search,
    String? companyId,
    String? departmentId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
        if (departmentId != null && departmentId.isNotEmpty)
          'departmentId': departmentId,
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
      };

      final response = await _apiClient.get(
        ApiEndpoints.payrollEmployees,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      return PayrollEmployeeListResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
  @override
  Future<List<PayrollPeriodModel>> getPayrollPeriods({
    String? companyId,
    String? status,
    int? year,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
        'year': ?year,
      };

      final response = await _apiClient.get(
        ApiEndpoints.payrollPeriods,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List<dynamic>? ?? [];
      return rawList
          .map((item) =>
              PayrollPeriodModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<PayrollDetailModel> getPayrollDetail(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.payrollDetail(id));
      final data = response.data as Map<String, dynamic>;
      final detailMap = data['data'] as Map<String, dynamic>? ?? {};
      return PayrollDetailModel.fromJson(detailMap);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<PayrollDownloadResponseModel> downloadPayslip(
    String id, {
    bool force = false,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.payrollDownload(id),
        queryParameters: {
          if (force) 'force': true,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final resultData = data['data'] as Map<String, dynamic>? ?? {};
      return PayrollDownloadResponseModel.fromJson(resultData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}
