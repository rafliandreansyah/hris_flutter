import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';

abstract class ResignationRepository {
  Future<MyResignationStatusModel> getMyResignationStatus();

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
  });

  Future<void> cancelMyResignation();

  Future<ResignationDetailModel> getResignationDetail(String id);

  Future<ResignationInitialFormModel> getInitialFormData();

  Future<void> submitResignation(SubmitResignationRequestModel request);
}
