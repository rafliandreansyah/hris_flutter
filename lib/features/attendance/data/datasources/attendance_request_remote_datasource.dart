import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';

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

  /// Mengambil detail permohonan presensi luar kantor dari endpoint `GET /attendances/requests/{id}`.
  Future<AttendanceRequestDetailData> getAttendanceRequestDetail(String id);

  /// Menyetujui atau menolak permohonan presensi luar kantor ke endpoint `PATCH /attendances/requests/{id}/approve`.
  Future<void> approveAttendanceRequest({
    required String id,
    required bool isApproved,
    String? approverNotes,
  });

  /// Menghapus permohonan presensi luar kantor ke endpoint `DELETE /attendances/requests/{id}`.
  Future<void> deleteAttendanceRequest(String id);

  /// Mengirimkan permintaan live attendance ke endpoint `POST /attendances/requests/live`.
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  );

  /// Mengirimkan permintaan schedule attendance ke endpoint `POST /attendances/requests/schedule`.
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  );
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

      throw const ApiException(
        message: 'Gagal memuat data pengajuan presensi.',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 403) {
        throw const ApiException(
          message: 'Tidak memiliki hak akses approver untuk pengajuan presensi tim.',
          statusCode: 403,
        );
      }
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  ) async {
    try {
      final map = await request.toFormDataMap();
      final formData = FormData.fromMap(map);

      final response = await _apiClient.post(
        ApiEndpoints.attendanceLiveRequest,
        data: formData,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return LiveAttendanceResponse.fromJson(rawData);
      }

      throw const ApiException(
        message: 'Gagal mengirim presensi live.',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  ) async {
    try {
      final formDataMap = await request.toFormDataMap();
      final formData = FormData.fromMap(formDataMap);

      final response = await _apiClient.post(
        ApiEndpoints.attendanceScheduleRequest,
        data: formData,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return ScheduleAttendanceResponse.fromJson(rawData);
      }

      throw const ApiException(
        message: 'Gagal mengajukan presensi terjadwal.',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AttendanceRequestDetailData> getAttendanceRequestDetail(String id) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.attendanceRequestDetail(id),
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final parsed = AttendanceRequestDetailResponse.fromJson(rawData);
        return parsed.data;
      }

      throw const ApiException(
        message: 'Gagal memuat detail pengajuan presensi.',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> approveAttendanceRequest({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'isApproved': isApproved,
      };
      if (approverNotes != null && approverNotes.trim().isNotEmpty) {
        payload['approverNotes'] = approverNotes.trim();
      }

      await _apiClient.patch(
        ApiEndpoints.attendanceRequestApprove(id),
        data: payload,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteAttendanceRequest(String id) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.attendanceRequestDetail(id),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
