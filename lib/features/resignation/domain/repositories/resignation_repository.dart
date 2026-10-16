import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';
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


  Future<ResignationInitialFormModel> getInitialFormData();

  Future<void> submitResignation(SubmitResignationRequestModel request);

  /// Persetujuan 1-on-1 atasan (`POST /resignations/subordinates/{id}/approve`).
  Future<void> approveSubordinateResignation(
    String id, {
    required String managerNotes,
    bool approveEarlyNotice = true,
  });

  /// Penolakan oleh atasan (`POST /resignations/subordinates/{id}/reject`).
  Future<void> rejectSubordinateResignation(
    String id, {
    required String rejectionReason,
  });

  /// Kuesioner exit interview mandiri (`POST /resignations/my/exit-interview`).
  Future<void> submitExitInterview(ExitInterviewRequestModel request);
}
