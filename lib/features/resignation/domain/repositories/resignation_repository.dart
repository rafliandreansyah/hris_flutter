import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
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
}
