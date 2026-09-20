import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';

abstract class WorkScheduleRemoteDataSource {
  Future<WorkScheduleResponse> getWorkSchedule({String? employeeId});
}

class WorkScheduleRemoteDataSourceImpl implements WorkScheduleRemoteDataSource {
  final ApiClient _apiClient;

  WorkScheduleRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<WorkScheduleResponse> getWorkSchedule({String? employeeId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (employeeId != null && employeeId.trim().isNotEmpty) {
        queryParams['employeeId'] = employeeId.trim();
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.employeeWorkSchedule,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return WorkScheduleResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
