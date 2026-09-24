import 'package:hris_flutter/features/resignation/data/datasources/resignation_remote_datasource.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';

class ResignationRepositoryImpl implements ResignationRepository {
  final ResignationRemoteDataSource _remoteDataSource;

  ResignationRepositoryImpl({ResignationRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? ResignationRemoteDataSourceImpl();

  @override
  Future<MyResignationStatusModel> getMyResignationStatus() {
    return _remoteDataSource.getMyResignationStatus();
  }

  @override
  Future<SubordinateResignationResponseModel> getSubordinateResignations({
    String status = 'pending',
    int page = 1,
    int size = 10,
    String? search,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? startDate,
    String? endDate,
  }) {
    return _remoteDataSource.getSubordinateResignations(
      status: status,
      page: page,
      size: size,
      search: search,
      companyId: companyId,
      departmentId: departmentId,
      positionId: positionId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> cancelMyResignation() {
    return _remoteDataSource.cancelMyResignation();
  }

  @override
  Future<ResignationDetailModel> getResignationDetail(String id) {
    return _remoteDataSource.getResignationDetail(id);
  }

  @override
  Future<ResignationInitialFormModel> getInitialFormData() {
    return _remoteDataSource.getInitialFormData();
  }

  @override
  Future<void> submitResignation(SubmitResignationRequestModel request) {
    return _remoteDataSource.submitResignation(request);
  }
}

