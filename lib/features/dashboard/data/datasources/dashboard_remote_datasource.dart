import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardResponseModel> getEmployeeDashboard();
  Future<MenuResponseModel> getAuthMenus();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<DashboardResponseModel> getEmployeeDashboard() async {
    final response = await _apiClient.get(ApiEndpoints.employeeDashboard);
    return DashboardResponseModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<MenuResponseModel> getAuthMenus() async {
    final response = await _apiClient.get(ApiEndpoints.authMenus);
    return MenuResponseModel.fromJson(response.data as Map<String, dynamic>);
  }
}
