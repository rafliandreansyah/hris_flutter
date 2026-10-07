import 'package:hris_flutter/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_config_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';
import 'package:hris_flutter/features/tracking/domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource remoteDataSource;

  TrackingRepositoryImpl({TrackingRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? TrackingRemoteDataSourceImpl();

  @override
  Future<TrackingConfigModel> getTrackingConfig() {
    return remoteDataSource.getTrackingConfig();
  }

  @override
  Future<void> uploadBatch(TrackingBatchPayload payload) {
    return remoteDataSource.uploadBatch(payload);
  }

  @override
  Future<List<TrackingLogItem>> getTrackingLogs({
    required String sourceType,
    required String referenceId,
    String? employeeId,
    int? limit,
  }) {
    return remoteDataSource.getTrackingLogs(
      sourceType: sourceType,
      referenceId: referenceId,
      employeeId: employeeId,
      limit: limit,
    );
  }

  @override
  Future<LiveTrackingResponse> getLiveTracking({
    String? companyId,
    String? departmentId,
    String? status,
    bool activeOnly = true,
    String? search,
  }) {
    return remoteDataSource.getLiveTracking(
      companyId: companyId,
      departmentId: departmentId,
      status: status,
      activeOnly: activeOnly,
      search: search,
    );
  }
}
