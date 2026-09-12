import 'package:hris_flutter/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:image_picker/image_picker.dart';

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
    @Deprecated('Gunakan status') String? statusApprove,
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
      statusApprove: statusApprove,
    );
  }

  @override
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  }) {
    return _remoteDataSource.getOvertimeSchedule(
      dateTimeStart: dateTimeStart,
    );
  }

  @override
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  }) {
    return _remoteDataSource.createOvertimeRequest(
      startOvertime: startOvertime,
      endOvertime: endOvertime,
      notes: notes,
      workScheduleId: workScheduleId,
      file: file,
    );
  }

  @override
  Future<OvertimeDetailData> getOvertimeDetail(String id) {
    return _remoteDataSource.getOvertimeDetail(id);
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) {
    return _remoteDataSource.approveOvertime(
      id: id,
      isApproved: isApproved,
      approverNotes: approverNotes,
    );
  }

  @override
  Future<void> deleteOvertime(String id) {
    return _remoteDataSource.deleteOvertime(id);
  }
}
