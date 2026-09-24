import 'package:hris_flutter/features/asset/data/datasources/asset_remote_datasource.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AssetRemoteDataSource _remoteDataSource;

  AssetRepositoryImpl({AssetRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AssetRemoteDataSourceImpl();

  @override
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  }) {
    return _remoteDataSource.getAssets(
      page: page,
      size: size,
      search: search,
      categoryId: categoryId,
      status: status,
    );
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) {
    return _remoteDataSource.getAssetCategories(search: search);
  }

  @override
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  }) {
    return _remoteDataSource.approveAssignment(
      assignmentId: assignmentId,
      conditionOnCheckin: conditionOnCheckin,
      recipientNotes: recipientNotes,
      signatureUrl: signatureUrl,
      handoverPhotoUrl: handoverPhotoUrl,
    );
  }

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) {
    return _remoteDataSource.rejectAssignment(
      assignmentId: assignmentId,
      rejectionReason: rejectionReason,
    );
  }
}
