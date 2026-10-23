import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Hero Header Ringkasan Aset pada Layar Detail
class AssetDetailHeroCard extends StatelessWidget {
  final AssetDetailData asset;

  const AssetDetailHeroCard({super.key, required this.asset});

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon Container Besar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandTeal, AppColors.brandTealSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandTeal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.laptop,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 2. Judul & Kode Aset
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
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
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (asset.category != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              asset.category!.name,
                              style: AppTypography.labelSmall.copyWith(
                                color: subtitleCol,
                                fontSize: 12,
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
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // 3. Status & Kondisi Badges
          Row(
            children: [
              _buildStatusChip(asset.status),
              const SizedBox(width: 8),
              _buildConditionChip(asset.condition),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    switch (status) {
      case 'AVAILABLE':
        return const AppStatusChip(
          label: 'Tersedia di Gudang',
          tone: AppStatusTone.success,
        );
      case 'ASSIGNED':
        return const AppStatusChip(
          label: 'Sedang Digunakan',
          tone: AppStatusTone.info,
        );
      case 'MAINTENANCE':
        return const AppStatusChip(
          label: 'Dalam Perbaikan',
          tone: AppStatusTone.warning,
        );
      case 'DISPOSED':
        return const AppStatusChip(
          label: 'Dihapuskan',
          tone: AppStatusTone.error,
        );
      default:
        return AppStatusChip(label: status);
    }
  }

  Widget _buildConditionChip(String condition) {
    Color bg;
    Color text;
    String label;

    switch (condition) {
      case 'NEW':
        bg = const Color(0xFFE0E7FF);
        text = const Color(0xFF3730A3);
        label = 'Kondisi: Baru';
        break;
      case 'GOOD':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        label = 'Kondisi: Baik';
        break;
      case 'FAIR':
        bg = AppColors.warningContainer;
        text = AppColors.onWarningContainer;
        label = 'Kondisi: Cukup';
        break;
      case 'DAMAGED':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFF991B1B);
        label = 'Kondisi: Rusak';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = AppColors.darkSurfaceContainerHighest;
        label = 'Kondisi: $condition';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
