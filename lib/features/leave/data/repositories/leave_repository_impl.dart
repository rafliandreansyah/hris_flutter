import 'package:hris_flutter/features/leave/data/datasources/leave_remote_datasource.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource _remoteDataSource;

  LeaveRepositoryImpl({LeaveRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? LeaveRemoteDataSourceImpl();

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) {
    return _remoteDataSource.getLeaveRequests(
      page: page,
      size: size,
      companyId: companyId,
      departmentId: departmentId,
      positionId: positionId,
      search: search,
      statusApprove: statusApprove,
      startDate: startDate,
      endDate: endDate,
      approver: approver,
    );
  }
}
