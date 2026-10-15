import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu inventaris fasilitas yang tersedia di gudang/pool (`AVAILABLE`)
/// Menampilkan lokasi penyimpanan rak/gudang dan tombol serah terima cepat ke karyawan.
class AssetWarehouseCard extends StatelessWidget {
  final AssetListItem asset;
  final VoidCallback? onTap;
  final VoidCallback? onHandover;
  final bool canHandover;

  const AssetWarehouseCard({
    super.key,
    required this.asset,
    this.onTap,
    this.onHandover,
    this.canHandover = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final locationText = (asset.location != null && asset.location!.trim().isNotEmpty)
        ? asset.location!.trim()
        : 'Gudang Inventaris Utama';

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Icon Kategori, Nama, Kode, & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.brandTeal.withValues(alpha: 0.2)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.brandTeal.withValues(alpha: 0.3)
                              : const Color(0xFFBAE6FD),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.warehouse,
                        size: 22,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBackgroundSubtle
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  asset.assetCode,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (asset.brand != null &&
                                  asset.brand!.trim().isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${asset.brand} ${asset.model ?? ''}'.trim(),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: subtitleCol,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Badge Tersedia di Gudang
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tersedia',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF15803D),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm + 2),

                // 2. Info Lokasi Penyimpanan & Kondisi Fisik
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackgroundSubtle
                        : AppColors.backgroundSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderCol.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: AppColors.brandTeal,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locationText,
                          style: AppTypography.bodySmall.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: asset.conditionBadgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          asset.conditionBadgeLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: asset.conditionBadgeTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Tombol Aksi Cepat: Serah Terima
                if (canHandover && onHandover != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: onHandover,
                      icon: const Icon(LucideIcons.userPlus, size: 16),
                      label: const Text('Serah Terima ke Karyawan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const AppColors.brandTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
