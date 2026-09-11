import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/leave/data/datasources/leave_remote_datasource.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
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

  @override
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id) {
    return _remoteDataSource.getLeaveRequestDetail(id);
  }

  @override
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  }) {
    return _remoteDataSource.approveLeaveRequest(
      id,
      isApproved: isApproved,
      approverNotes: approverNotes,
    );
  }

  @override
  Future<void> deleteLeaveRequest(String id) {
    return _remoteDataSource.deleteLeaveRequest(id);
  }

  @override
  Future<List<LeaveTypeOptionModel>> getLeaveTypes() {
    return _remoteDataSource.getLeaveTypes();
  }

  @override
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  }) {
    return _remoteDataSource.createLeaveRequest(
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      totalDays: totalDays,
      notes: notes,
      file: file,
    );
  }
}
