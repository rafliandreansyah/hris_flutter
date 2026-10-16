import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';

import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';

abstract class ResignationRemoteDataSource {
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

  Future<void> approveSubordinateResignation(
    String id, {
    required String managerNotes,
    bool approveEarlyNotice = true,
  });

  Future<void> rejectSubordinateResignation(
    String id, {
    required String rejectionReason,
  });

  Future<void> submitExitInterview(ExitInterviewRequestModel request);
}

class ResignationRemoteDataSourceImpl implements ResignationRemoteDataSource {
  final ApiClient _apiClient;

  ResignationRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<MyResignationStatusModel> getMyResignationStatus() async {
    final response = await _apiClient.get(ApiEndpoints.myResignationStatus);
    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'];
      if (data is Map<String, dynamic>) {
        return MyResignationStatusModel.fromJson(data);
      }
    }
    throw const ApiException(
      message: 'Gagal memuat status pengunduran diri.',
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
    final queryParams = <String, dynamic>{
      'status': status,
      'page': page,
      'size': size,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (companyId != null && companyId.trim().isNotEmpty) {
      queryParams['companyId'] = companyId.trim();
    }
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      queryParams['departmentId'] = departmentId.trim();
    }
    if (positionId != null && positionId.trim().isNotEmpty) {
      queryParams['positionId'] = positionId.trim();
    }
    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParams['startDate'] = startDate.trim();
    }
    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParams['endDate'] = endDate.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.subordinateResignations,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return SubordinateResignationResponseModel.fromJson(rawData);
    }

    throw const ApiException(
      message: 'Gagal memuat daftar pengajuan pengunduran diri tim.',
    );
  }

  @override
  Future<void> cancelMyResignation() async {
    final response = await _apiClient.delete('/resignations/my');
    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData['success'] == false) {
      throw ApiException(
        message: rawData['message']?.toString() ??
            'Gagal membatalkan pengajuan resign.',
      );
    }
  }


  @override
  Future<ResignationInitialFormModel> getInitialFormData() async {
    final response = await _apiClient.get(ApiEndpoints.resignationInitialForm);
    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      final data = rawData['data'];
      if (data is Map<String, dynamic>) {
        return ResignationInitialFormModel.fromJson(data);
      }
    }
    throw const ApiException(
      message: 'Gagal memuat data formulir pengunduran diri.',
    );
  }

  @override
  Future<void> submitResignation(SubmitResignationRequestModel request) async {
    final formData = await request.toFormData();
    final response = await _apiClient.post(
      ApiEndpoints.resignations,
      data: formData,
    );
    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData['success'] == false) {
      throw ApiException(
        message: rawData['message']?.toString() ??
            'Gagal mengirimkan pengajuan pengunduran diri.',
      );
    }
  }

  @override
  Future<void> approveSubordinateResignation(
    String id, {
    required String managerNotes,
    bool approveEarlyNotice = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.subordinateResignationApprove(id),
      data: {
        'managerNotes': managerNotes.trim(),
        'approveEarlyNotice': approveEarlyNotice,
      },
    );
    _ensureSuccess(response.data, 'Gagal menyetujui pengajuan resign.');
  }

  @override
  Future<void> rejectSubordinateResignation(
    String id, {
    required String rejectionReason,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.subordinateResignationReject(id),
      data: {'rejectionReason': rejectionReason.trim()},
    );
    _ensureSuccess(response.data, 'Gagal menolak pengajuan resign.');
  }

  @override
  Future<void> submitExitInterview(ExitInterviewRequestModel request) async {
    final response = await _apiClient.post(
      ApiEndpoints.resignationExitInterview,
      data: request.toJson(),
    );
    _ensureSuccess(response.data, 'Gagal mengirim kuesioner exit interview.');
  }

  void _ensureSuccess(dynamic raw, String fallbackMessage) {
    if (raw is Map<String, dynamic> && raw['success'] == false) {
      throw ApiException(message: raw['message']?.toString() ?? fallbackMessage);
    }
  }
}
