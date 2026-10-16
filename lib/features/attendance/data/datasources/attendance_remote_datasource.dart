import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/create_attendance_response.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/core/network/multipart_file_helper.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> fetchAttendanceInfo();
  Future<Map<String, dynamic>> fetchDashboardAttendance();

  /// `GET /attendances/break/today` — status & daftar istirahat hari ini.
  Future<Map<String, dynamic>> fetchBreakToday();

  /// `POST /attendances/break/start` / `POST /attendances/break/end`.
  Future<Map<String, dynamic>> submitBreak({
    required bool isStart,
    required Map<String, dynamic> payload,
  });
  Future<CreateAttendanceResponse> recordAttendance(CreateAttendanceRequest request);

  Future<AttendanceLogListResponse> getAttendanceLogs({
    String? employeeId,
    bool lastMonth = false,
    int page = 1,
    int size = 20,
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  });
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees();
  Future<AttendanceDetailModel> getAttendanceDetail(String id);
  Future<Map<String, dynamic>> setDefaultWorkLocation({
    String? workLocationId,
    String? employeeWorkLocationId,
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
  Future<Map<String, dynamic>> fetchBreakToday() async {
    final response = await apiClient.get(ApiEndpoints.attendanceBreakToday);
    final raw = response.data;
    return raw is Map<String, dynamic> ? raw : {};
  }

  @override
  Future<Map<String, dynamic>> submitBreak({
    required bool isStart,
    required Map<String, dynamic> payload,
  }) async {
    final response = await apiClient.post(
      isStart
          ? ApiEndpoints.attendanceBreakStart
          : ApiEndpoints.attendanceBreakEnd,
      data: payload,
    );
    final raw = response.data;
    return raw is Map<String, dynamic> ? raw : {};
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
  Future<CreateAttendanceResponse> recordAttendance(
    CreateAttendanceRequest request,
  ) async {
    try {
      final map = request.toFormDataMap();
      if (request.file != null) {
        final fileName = request.file!.name.isNotEmpty
            ? request.file!.name
            : request.file!.path.split(RegExp(r'[/\\]')).last;
        map['file'] = await multipartFromPath(
          request.file!.path,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(map);
      final response = await apiClient.post(
        ApiEndpoints.attendances,
        data: formData,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return CreateAttendanceResponse.fromJson(rawData);
      }

      throw const ApiException(message: 'Format data respons tidak valid');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }



  @override
  Future<AttendanceLogListResponse> getAttendanceLogs({
    String? employeeId,
    bool lastMonth = false,
    int page = 1,
    int size = 20,
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'lastMonth': lastMonth,
      };
      if (employeeId != null && employeeId.trim().isNotEmpty) {
        queryParams['employeeId'] = employeeId.trim();
      }
      if (startDate != null && startDate.trim().isNotEmpty) {
        queryParams['startDate'] = startDate.trim();
      }
      if (endDate != null && endDate.trim().isNotEmpty) {
        queryParams['endDate'] = endDate.trim();
      }
      if (type != null && type.trim().isNotEmpty) {
        queryParams['type'] = type.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }
      if (page > 1) {
        queryParams['page'] = page;
      }
      if (size != 20) {
        queryParams['size'] = size;
      }

      final response = await apiClient.get(
        ApiEndpoints.attendances,
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return AttendanceLogListResponse.fromJson(rawData);
      }

      throw const ApiException(
        message: 'Gagal memuat riwayat absensi.',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async {
    try {
      final response = await apiClient.get(ApiEndpoints.attendancesEmployees);
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final data = rawData['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((e) => EmployeeDirectoryItem.fromJson(e))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const ApiException(
          message: 'Tidak ada hak akses',
          statusCode: 403,
        );
      }
      throw ApiException.fromDioException(e);
    }
  }


  @override
  Future<AttendanceDetailModel> getAttendanceDetail(String id) async {
    try {
      final response = await apiClient.get(ApiEndpoints.attendanceDetail(id));
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final data = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : rawData;
        return AttendanceDetailModel.fromJson(data);
      }
      throw const ApiException(message: 'Format data tidak valid');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const ApiException(
          message: 'Tidak ada hak akses',
          statusCode: 403,
        );
      }
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> setDefaultWorkLocation({
    String? workLocationId,
    String? employeeWorkLocationId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (workLocationId != null && workLocationId.trim().isNotEmpty) {
        body['workLocationId'] = workLocationId.trim();
      }
      if (employeeWorkLocationId != null &&
          employeeWorkLocationId.trim().isNotEmpty) {
        body['employeeWorkLocationId'] = employeeWorkLocationId.trim();
      }

      final response = await apiClient.put(
        ApiEndpoints.employeeDefaultWorkLocation,
        data: body,
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
