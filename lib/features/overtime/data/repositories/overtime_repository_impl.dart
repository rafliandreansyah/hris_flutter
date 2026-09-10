import 'package:hris_flutter/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';

class OvertimeRepositoryImpl implements OvertimeRepository {
  final OvertimeRemoteDataSource _remoteDataSource;

  OvertimeRepositoryImpl({OvertimeRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? OvertimeRemoteDataSourceImpl();

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
  }) {
    return _remoteDataSource.getOvertimeRequests(
      page: page,
      size: size,
      companyId: companyId,
      departmentId: departmentId,
      positionId: positionId,
      search: search,
      startDate: startDate,
      endDate: endDate,
      approver: approver,
      status: status,
    );
  }
}
