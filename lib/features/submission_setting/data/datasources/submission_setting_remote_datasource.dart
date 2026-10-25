import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/submission_setting/data/models/submission_setting_model.dart';

abstract class SubmissionSettingRemoteDataSource {
  Future<SubmissionSettingModel> getSubmissionSetting();
}

class SubmissionSettingRemoteDataSourceImpl implements SubmissionSettingRemoteDataSource {
  final ApiClient apiClient;

  SubmissionSettingRemoteDataSourceImpl({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<SubmissionSettingModel> getSubmissionSetting() async {
    try {
      final response = await apiClient.get(ApiEndpoints.submissionSettings);
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
        return SubmissionSettingModel.fromJson(raw['data'] as Map<String, dynamic>);
      }
      throw const ApiException(message: 'Format setelan pengajuan tidak valid.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
