import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';

/// Exception khusus saat sesi presensi/aktivitas telah ditutup oleh server (HTTP 400 SESSION_CLOSED)
class SessionClosedException implements Exception {
  final String message;
  final String sourceType;
  final String referenceId;

  const SessionClosedException({
    required this.message,
    required this.sourceType,
    required this.referenceId,
  });

  @override
  String toString() => 'SessionClosedException: $message ($sourceType: $referenceId)';
}

abstract class TrackingRemoteDataSource {
  Future<TrackingConfigModel> getTrackingConfig();
  Future<void> uploadBatch(TrackingBatchPayload payload);
  Future<List<TrackingLogItem>> getTrackingLogs({
    required String sourceType,
    required String referenceId,
    String? employeeId,
    int? limit,
  });
  Future<LiveTrackingResponse> getLiveTracking({
    String? companyId,
    String? departmentId,
    String? status,
    bool activeOnly = true,
    String? search,
  });
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final ApiClient apiClient;

  TrackingRemoteDataSourceImpl({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<TrackingConfigModel> getTrackingConfig() async {
    try {
      final response = await apiClient.get(ApiEndpoints.trackingConfig);
      final rawData = response.data;
      if (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>) {
        return TrackingConfigModel.fromJson(rawData['data'] as Map<String, dynamic>);
      }
      throw const ApiException(message: 'Format konfigurasi pelacakan tidak valid.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> uploadBatch(TrackingBatchPayload payload) async {
    try {
      await apiClient.dio.post(
        ApiEndpoints.trackingBatch,
        data: payload.toJson(),
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final errorCode = responseData is Map ? responseData['code'] : null;

      // Handle khusus jika sesi telah ditutup di server (auto-kill session)
      if (e.response?.statusCode == 400 && errorCode == 'SESSION_CLOSED') {
        throw SessionClosedException(
          message: responseData is Map && responseData['message'] != null
              ? responseData['message'].toString()
              : 'Sesi pelacakan telah ditutup di server.',
          sourceType: payload.sourceType,
          referenceId: payload.referenceId,
        );
      }
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<TrackingLogItem>> getTrackingLogs({
    required String sourceType,
    required String referenceId,
    String? employeeId,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'sourceType': sourceType,
        'referenceId': referenceId,
      };
      if (employeeId != null && employeeId.trim().isNotEmpty) {
        queryParams['employeeId'] = employeeId.trim();
      }
      if (limit != null && limit > 0) {
        queryParams['limit'] = limit;
      }

      final response = await apiClient.get(
        ApiEndpoints.trackingLogs,
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic> && rawData['data'] is List) {
        return (rawData['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => TrackingLogItem.fromJson(item))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<LiveTrackingResponse> getLiveTracking({
    String? companyId,
    String? departmentId,
    String? status,
    bool activeOnly = true,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'activeOnly': activeOnly,
      };
      if (companyId != null && companyId.trim().isNotEmpty) {
        queryParams['companyId'] = companyId.trim();
      }
      if (departmentId != null && departmentId.trim().isNotEmpty) {
        queryParams['departmentId'] = departmentId.trim();
      }
      if (status != null && status.trim().isNotEmpty && status != 'all') {
        queryParams['status'] = status.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await apiClient.get(
        ApiEndpoints.trackingLive,
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>) {
        return LiveTrackingResponse.fromJson(
          rawData['data'] as Map<String, dynamic>,
        );
      }
      return LiveTrackingResponse.empty();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
