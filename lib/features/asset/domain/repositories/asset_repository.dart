import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';

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
