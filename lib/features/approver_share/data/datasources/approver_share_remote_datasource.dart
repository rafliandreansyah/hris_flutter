import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/approver_share/data/models/approver_model.dart';

abstract class ApproverShareRemoteDataSource {
  /// `GET /approvers?module=<module>&id=<requestId>`
  Future<List<ApproverModel>> getApprovers({
    required String module,
    required String requestId,
  });
}

class ApproverShareRemoteDataSourceImpl implements ApproverShareRemoteDataSource {
  final ApiClient _apiClient;

  ApproverShareRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<List<ApproverModel>> getApprovers({
    required String module,
    required String requestId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.approvers,
      queryParameters: {'module': module, 'id': requestId},
    );

    final data = response.data;
    final list = data is Map<String, dynamic> ? data['data'] : data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(ApproverModel.fromJson)
          .toList();
    }
    return [];
  }
}
