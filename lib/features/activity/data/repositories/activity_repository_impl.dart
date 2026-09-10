import 'package:hris_flutter/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:image_picker/image_picker.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource _remoteDataSource;

  ActivityRepositoryImpl({ActivityRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ActivityRemoteDataSourceImpl();

  @override
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
  }) {
    return _remoteDataSource.getActivities(
      page: page,
      size: size,
      companyId: companyId,
      departmentId: departmentId,
      positionId: positionId,
      search: search,
      status: status,
      startDate: startDate,
      endDate: endDate,
      approver: approver,
    );
  }

  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) {
    return _remoteDataSource.getActivityDetail(id);
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) {
    return _remoteDataSource.finishActivity(
      id: id,
      notes: notes,
      file: file,
    );
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) {
    return _remoteDataSource.cancelActivity(
      id: id,
      notes: notes,
      file: file,
    );
  }

  List<ActivityTypeModel>? _cachedActivityTypes;

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    if (_cachedActivityTypes != null && _cachedActivityTypes!.isNotEmpty) {
      return ActivityTypesResponse(
        success: true,
        message: 'OK',
        data: _cachedActivityTypes!,
      );
    }
    final res = await _remoteDataSource.getActivityTypes();
    if (res.success && res.data.isNotEmpty) {
      _cachedActivityTypes = res.data;
    }
    return res;
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
  }) {
    return _remoteDataSource.createActivity(
      activityTypeId: activityTypeId,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      locationAddress: locationAddress,
      description: description,
      status: status,
      file: file,
    );
  }
}
