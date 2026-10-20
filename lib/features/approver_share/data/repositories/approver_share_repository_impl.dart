import 'package:hris_flutter/features/approver_share/data/datasources/approver_share_remote_datasource.dart';
import 'package:hris_flutter/features/approver_share/data/models/approver_model.dart';
import 'package:hris_flutter/features/approver_share/domain/repositories/approver_share_repository.dart';

class ApproverShareRepositoryImpl implements ApproverShareRepository {
  final ApproverShareRemoteDataSource _remoteDataSource;

  ApproverShareRepositoryImpl({ApproverShareRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? ApproverShareRemoteDataSourceImpl();

  @override
  Future<List<ApproverModel>> getApprovers({
    required String module,
    required String requestId,
  }) {
    return _remoteDataSource.getApprovers(module: module, requestId: requestId);
  }
}
