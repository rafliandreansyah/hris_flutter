import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';

abstract class AssetRemoteDataSource {
  /// Mengambil daftar aset/fasilitas dari endpoint GET /api/v1/assets.
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  });

  /// Mengambil daftar kategori aset aktif dari GET /api/v1/assets/categories.
  Future<List<AssetCategoryModel>> getAssetCategories({String? search});

  /// Mengambil detail aset lengkap beserta riwayat penugasan dari GET /api/v1/assets/:id.
  Future<AssetDetailData> getAssetDetail(String assetId);

  /// Mendaftarkan master unit aset baru ke POST /api/v1/assets.
  Future<void> createAsset(CreateAssetPayload payload);

  /// Serah terima unit dari gudang/pool ke karyawan via POST /api/v1/assets/:id/handover.
  Future<void> handoverAsset(String assetId, HandoverAssetPayload payload);

  /// Inisiasi alih tangan ke rekan kerja via POST /api/v1/assets/:id/transfer.
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  );

  /// Menyetujui penerimaan alih tangan fasilitas dari POST /api/v1/assets/assignments/:id/approve.
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  });

  /// Menolak serah terima fasilitas dari POST /api/v1/assets/assignments/:id/reject.
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  });
}

class AssetRemoteDataSourceImpl implements AssetRemoteDataSource {
  final ApiClient _apiClient;

  AssetRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      queryParams['categoryId'] = categoryId.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.assets,
      queryParameters: queryParams,
    );

    return AssetListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories({String? search}) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.assetCategories,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AssetCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AssetDetailData> getAssetDetail(String assetId) async {
    final response = await _apiClient.get(ApiEndpoints.assetDetail(assetId));
    final map = response.data as Map<String, dynamic>;
    final data = (map['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return AssetDetailData.fromJson(data);
  }

  @override
  Future<void> createAsset(CreateAssetPayload payload) async {
    await _apiClient.post(
      ApiEndpoints.assets,
      data: payload.toJson(),
    );
  }

  @override
  Future<void> handoverAsset(String assetId, HandoverAssetPayload payload) async {
    await _apiClient.post(
      ApiEndpoints.assetHandover(assetId),
      data: payload.toJson(),
    );
  }

  @override
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  ) async {
    await _apiClient.post(
      ApiEndpoints.assetTransfer(assetId),
      data: payload.toJson(),
    );
  }

  @override
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (conditionOnCheckin != null) {
      body['conditionOnCheckin'] = conditionOnCheckin;
    }
    if (recipientNotes != null && recipientNotes.trim().isNotEmpty) {
      body['recipientNotes'] = recipientNotes.trim();
    }
    if (signatureUrl != null && signatureUrl.trim().isNotEmpty) {
      body['signatureUrl'] = signatureUrl.trim();
    }
    if (handoverPhotoUrl != null && handoverPhotoUrl.trim().isNotEmpty) {
      body['handoverPhotoUrl'] = handoverPhotoUrl.trim();
    }

    await _apiClient.post(
      ApiEndpoints.assetApprove(assignmentId),
      data: body.isNotEmpty ? body : null,
    );
  }

  @override
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  }) async {
    await _apiClient.post(
      ApiEndpoints.assetReject(assignmentId),
      data: {
        'rejectionReason': rejectionReason.trim(),
      },
    );
  }
}
