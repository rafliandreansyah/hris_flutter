import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';

abstract class AssetRepository {
  /// Mengambil daftar aset dengan parameter paginasi, pencarian, dan filter.
  Future<AssetListResponse> getAssets({
    required int page,
    required int size,
    String? search,
    String? categoryId,
    String? status,
  });

  /// Mengambil daftar kategori aset.
  Future<List<AssetCategoryModel>> getAssetCategories({String? search});

  /// Mengambil detail aset lengkap beserta riwayat penugasan (GET /api/v1/assets/:id).
  Future<AssetDetailData> getAssetDetail(String assetId);

  /// Mendaftarkan master unit aset baru (POST /api/v1/assets).
  Future<void> createAsset(CreateAssetPayload payload);

  /// Serah terima unit dari gudang/pool ke karyawan (POST /api/v1/assets/:id/handover).
  Future<void> handoverAsset(String assetId, HandoverAssetPayload payload);

  /// Inisiasi alih tangan / oper fasilitas ke rekan kerja (POST /api/v1/assets/:id/transfer).
  Future<void> directTransferAsset(
    String assetId,
    DirectTransferAssetPayload payload,
  );

  /// Konfirmasi penerimaan fasilitas aset (Approve).
  Future<void> approveAssignment({
    required String assignmentId,
    String? conditionOnCheckin,
    String? recipientNotes,
    String? signatureUrl,
    String? handoverPhotoUrl,
  });

  /// Menolak penyerahan fasilitas aset (Reject).
  Future<void> rejectAssignment({
    required String assignmentId,
    required String rejectionReason,
  });
}
