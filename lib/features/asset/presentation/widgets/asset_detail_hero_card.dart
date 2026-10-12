import 'package:flutter/material.dart';
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
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.25),
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
    Color bg;
    Color border;
    Color text;
    String label;

    switch (status) {
      case 'AVAILABLE':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF15803D);
        label = 'Tersedia di Gudang';
        break;
      case 'ASSIGNED':
        bg = const Color(0xFFF0FDFA);
        border = const Color(0xFF99F6E4);
        text = const Color(0xFF0F766E);
        label = 'Sedang Digunakan';
        break;
      case 'MAINTENANCE':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFB45309);
        label = 'Dalam Perbaikan';
        break;
      case 'DISPOSED':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFB91C1C);
        label = 'Dihapuskan';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF475569);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
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
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF92400E);
        label = 'Kondisi: Cukup';
        break;
      case 'DAMAGED':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFF991B1B);
        label = 'Kondisi: Rusak';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
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
