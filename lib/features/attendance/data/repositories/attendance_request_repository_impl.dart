import 'package:hris_flutter/features/attendance/data/datasources/attendance_request_remote_datasource.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';

class AttendanceRequestRepositoryImpl implements AttendanceRequestRepository {
  final AttendanceRequestRemoteDataSource _remoteDataSource;

  AttendanceRequestRepositoryImpl({
    AttendanceRequestRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
            remoteDataSource ?? AttendanceRequestRemoteDataSourceImpl();

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
  }) {
    return _remoteDataSource.getAttendanceRequests(
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
}
