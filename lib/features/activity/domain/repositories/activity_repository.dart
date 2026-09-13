import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:image_picker/image_picker.dart';

abstract class ActivityRepository {
  /// Mengambil daftar aktivitas dari backend HRIS.
  Future<ActivityListResponse> getActivities({
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

  /// Mengambil data detail aktivitas dari backend HRIS.
  Future<ActivityDetailResponse> getActivityDetail(String id);

  /// Menyelesaikan aktivitas kerja (`PATCH /activity/{id}/finish`).
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  });

  /// Membatalkan aktivitas kerja (`PATCH /activity/{id}/cancel`).
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  });

  /// Mengambil daftar jenis aktivitas (`GET /activity/types`).
  Future<ActivityTypesResponse> getActivityTypes();

  /// Membuat aktivitas baru (`POST /activity`).
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

  /// Membuat rencana aktivitas untuk bawahan (`POST /activity/plan`).
  Future<CreateActivityResponse> createPlanActivity({
    required String employeeId,
    required String activityTypeId,
    required String startTime,
    required String locationName,
    required String locationAddress,
    required String description,
    double latitude = 0,
    double longitude = 0,
    XFile? file,
  });

  /// Memulai aktivitas kerja yang berstatus plan (`PATCH /activity/{id}/start`).
  Future<ActivityActionResponse> startActivity({
    required String id,
    required double latitude,
    required double longitude,
    required String locationAddress,
    XFile? file,
  });
}
