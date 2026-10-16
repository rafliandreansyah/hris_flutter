import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';

class MockResignationRepository implements ResignationRepository {
  MyResignationStatusModel? mockMyStatus;
  SubordinateResignationResponseModel? mockSubordinates;
  ResignationInitialFormModel? mockInitialForm;
  ResignationDetailModel? mockDetail;
  bool shouldThrowError = false;
  String errorMessage = 'Internal Server Error';
  bool cancelCalled = false;
  SubmitResignationRequestModel? lastSubmittedRequest;

  @override
  Future<MyResignationStatusModel> getMyResignationStatus() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockMyStatus ??
        const MyResignationStatusModel(
          hasActiveResignation: false,
          daysRemaining: 0,
        );
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
  }) async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockSubordinates ??
        const SubordinateResignationResponseModel(
          success: true,
          message: 'OK',
          data: [],
          meta: ResignationPaginationMeta(
            page: 1,
            size: 10,
            total: 0,
            totalPages: 1,
          ),
        );
  }

  @override
  Future<void> cancelMyResignation() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    cancelCalled = true;
  }


  @override
  Future<ResignationInitialFormModel> getInitialFormData() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockInitialForm ??
        const ResignationInitialFormModel(
          companyPolicy: ResignationCompanyPolicyModel(defaultNoticePeriodDays: 30),
          employee: ResignationFormEmployeeModel(id: 'emp-1', name: 'John Doe'),
          minSuggestedDate: '2026-10-31',
          colleagues: [],
        );
  }

  @override
  Future<void> submitResignation(SubmitResignationRequestModel request) async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    lastSubmittedRequest = request;
  }

  final List<Map<String, Object?>> reviewCalls = [];
  ExitInterviewRequestModel? lastExitInterview;

  @override
  Future<void> approveSubordinateResignation(
    String id, {
    required String managerNotes,
    bool approveEarlyNotice = true,
  }) async {
    reviewCalls.add({
      'action': 'approve',
      'id': id,
      'notes': managerNotes,
      'approveEarlyNotice': approveEarlyNotice,
    });
    if (shouldThrowError) throw ApiException(message: errorMessage);
  }

  @override
  Future<void> rejectSubordinateResignation(
    String id, {
    required String rejectionReason,
  }) async {
    reviewCalls.add({'action': 'reject', 'id': id, 'notes': rejectionReason});
    if (shouldThrowError) throw ApiException(message: errorMessage);
  }

  @override
  Future<void> submitExitInterview(ExitInterviewRequestModel request) async {
    lastExitInterview = request;
    if (shouldThrowError) throw ApiException(message: errorMessage);
  }
}
