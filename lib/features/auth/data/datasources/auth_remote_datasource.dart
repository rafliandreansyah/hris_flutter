import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_response.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<ApiResponse<LoginResponseData>> login(LoginRequestModel request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<ApiResponse<LoginResponseData>> login(LoginRequestModel request) async {
    final response = await _apiClient.post(
      ApiEndpoints.auth,
      data: request.toJson(),
    );

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LoginResponseData.fromJson(json as Map<String, dynamic>),
    );
  }
}
