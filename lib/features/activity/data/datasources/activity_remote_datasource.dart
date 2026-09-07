import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:image_picker/image_picker.dart';

abstract class ActivityRemoteDataSource {
  /// Mengambil daftar aktivitas kerja dari endpoint `/activity`.
  Future<ActivityListResponse> getActivities({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    bool approver = false,
  });

  /// Mengambil data detail aktivitas kerja dari endpoint `GET /activity/{id}`.
  Future<ActivityDetailResponse> getActivityDetail(String id);

  /// Menyelesaikan aktivitas kerja melalui `PATCH /activity/{id}/finish` (multipart/form-data).
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  });

  /// Membatalkan aktivitas kerja melalui `PATCH /activity/{id}/cancel` (multipart/form-data).
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  });

  /// Mengambil daftar jenis aktivitas dari endpoint `GET /activity/types`.
  Future<ActivityTypesResponse> getActivityTypes();

  /// Membuat aktivitas baru melalui `POST /activity` (multipart/form-data).
  Future<CreateActivityResponse> createActivity({
    required String activityTypeId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String locationAddress,
    required String description,
    String status = 'ongoing',
    XFile? file,
  });
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final ApiClient _apiClient;

  ActivityRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<ActivityListResponse> getActivities({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
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
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.activity,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return ActivityListResponse.fromJson(rawData, isMyActivity: !approver);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat data aktivitas.'
          : 'Gagal memuat data aktivitas.',
    );
  }

  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) async {
    final response = await _apiClient.get(
      ApiEndpoints.activityDetail(id),
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return ActivityDetailResponse.fromJson(rawData);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal memuat detail aktivitas.'
          : 'Gagal memuat detail aktivitas.',
    );
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    final map = <String, dynamic>{
      'notes': notes.trim(),
    };

    if (file != null) {
      final fileName = file.name.isNotEmpty
          ? file.name
          : file.path.split(RegExp(r'[/\\]')).last;
      map['file'] = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(map);

    final response = await _apiClient.patch(
      ApiEndpoints.activityFinish(id),
      data: formData,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return ActivityActionResponse.fromJson(rawData);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal menyelesaikan aktivitas.'
          : 'Gagal menyelesaikan aktivitas.',
    );
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    final map = <String, dynamic>{
      'notes': notes.trim(),
    };

    if (file != null) {
      final fileName = file.name.isNotEmpty
          ? file.name
          : file.path.split(RegExp(r'[/\\]')).last;
      map['file'] = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(map);

    final response = await _apiClient.patch(
      ApiEndpoints.activityCancel(id),
      data: formData,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return ActivityActionResponse.fromJson(rawData);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal membatalkan aktivitas.'
          : 'Gagal membatalkan aktivitas.',
    );
  }

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    final response = await _apiClient.get(
      ApiEndpoints.activityTypes,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return ActivityTypesResponse.fromJson(rawData);
    }

    throw ApiException(
      message: 'Gagal memuat jenis aktivitas.',
    );
  }

  @override
  Future<CreateActivityResponse> createActivity({
    required String activityTypeId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String locationAddress,
    required String description,
    String status = 'ongoing',
    XFile? file,
  }) async {
    final map = <String, dynamic>{
      'activityTypeId': activityTypeId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'locationName': locationName.trim(),
      'locationAddress': locationAddress.trim(),
      'description': description.trim(),
      'status': status,
    };

    if (file != null) {
      final fileName = file.name.isNotEmpty
          ? file.name
          : file.path.split(RegExp(r'[/\\]')).last;
      map['file'] = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(map);

    final response = await _apiClient.post(
      ApiEndpoints.activity,
      data: formData,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return CreateActivityResponse.fromJson(rawData);
    }

    throw ApiException(
      message: rawData is Map<String, dynamic>
          ? rawData['message']?.toString() ?? 'Gagal membuat aktivitas.'
          : 'Gagal membuat aktivitas.',
    );
  }
}
