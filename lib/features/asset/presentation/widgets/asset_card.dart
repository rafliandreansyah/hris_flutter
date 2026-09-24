import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Aset / Fasilitas sesuai desain Stitch M3:
/// "Oasish Fasilitas Saya (Unified Asset List)"
/// (ID: fa2fa6bde7d648aabb74209dbd5dde63).
class AssetCard extends StatelessWidget {
  final AssetListItem asset;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const AssetCard({
    super.key,
    required this.asset,
    this.onAccept,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (asset.isPendingAcceptance) {
      return _buildPendingAcceptanceCard(context);
    }
    return _buildStandardCard(context);
  }

  /// Kartu untuk status Menunggu Konfirmasi (PENDING_ACCEPTANCE)
  Widget _buildPendingAcceptanceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final transferred = asset.transferredFrom;

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
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Aset & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Kategori Kuning/Amber
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  asset.categoryIcon,
                  size: 24,
                  color: const Color(0xFFB45309),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackgroundSubtle
                            : AppColors.backgroundSubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderCol),
                      ),
                      child: Text(
                        asset.assetCode,
                        style: AppTypography.labelSmall.copyWith(
                          fontFamily: 'monospace',
                          color: subtitleCol,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (transferred != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 13,
                            color: subtitleCol,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: AppTypography.bodySmall.copyWith(
                                  color: subtitleCol,
                                  fontSize: 12,
                                ),
                                children: [
                                  const TextSpan(text: 'Dari: '),
                                  TextSpan(
                                    text: transferred.employeeName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textCol,
                                    ),
                                  ),
                                  if (transferred.department != null &&
                                      transferred.department!.isNotEmpty)
                                    TextSpan(
                                      text: ' • ${transferred.department}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Badge Menunggu
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: asset.statusBadgeBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: asset.statusBadgeBorderColor),
                ),
                child: Text(
                  asset.statusLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: asset.statusBadgeTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Action Buttons (Tolak & Terima)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Terima'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Kartu untuk status Aktif, Dikembalikan, Tersedia, dsb
  Widget _buildStandardCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Kategori Teal Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandTeal.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                asset.categoryIcon,
                size: 24,
                color: AppColors.brandTeal,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackgroundSubtle
                          : AppColors.backgroundSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderCol),
                    ),
                    child: Text(
                      asset.assetCode,
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: 'monospace',
                        color: subtitleCol,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.subtitleInfo,
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Status Tag & Sedang Dialihkan
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: asset.statusBadgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: asset.statusBadgeBorderColor),
                      ),
                      child: Text(
                        asset.statusLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: asset.statusBadgeTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: subtitleCol.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                if (asset.isPendingTransfer) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.repeat,
                        size: 11,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Sedang dialihkan',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
