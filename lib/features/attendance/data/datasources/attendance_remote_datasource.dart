import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/check_in_request_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> fetchAttendanceInfo();
  Future<Map<String, dynamic>> fetchDashboardAttendance();
  Future<Map<String, dynamic>> checkIn(CheckInRequestModel request);
  Future<Map<String, dynamic>> checkOut(CheckInRequestModel request);
  Future<Map<String, dynamic>> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<Map<String, dynamic>> fetchAttendanceInfo() async {
    try {
      final response = await apiClient.get(ApiEndpoints.employeeAttendanceInfo);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchDashboardAttendance() async {
    try {
      final response = await apiClient.get(ApiEndpoints.employeeDashboard);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> checkIn(CheckInRequestModel request) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.checkIn,
        data: request.toJson(),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> checkOut(CheckInRequestModel request) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.checkOut,
        data: request.toJson(),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.outsideAttendance,
        data: {
          'reason': issueDescription,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
