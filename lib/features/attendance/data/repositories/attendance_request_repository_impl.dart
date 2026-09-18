import 'package:hris_flutter/features/attendance/data/datasources/attendance_request_remote_datasource.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';
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

  @override
  Future<AttendanceRequestDetailData> getAttendanceRequestDetail(String id) {
    return _remoteDataSource.getAttendanceRequestDetail(id);
  }

  @override
  Future<void> approveAttendanceRequest({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) {
    return _remoteDataSource.approveAttendanceRequest(
      id: id,
      isApproved: isApproved,
      approverNotes: approverNotes,
    );
  }

  @override
  Future<void> deleteAttendanceRequest(String id) {
    return _remoteDataSource.deleteAttendanceRequest(id);
  }

  @override
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  ) {
    return _remoteDataSource.submitLiveAttendance(request);
  }

  @override
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  ) {
    return _remoteDataSource.submitScheduleAttendance(request);
  }
}
