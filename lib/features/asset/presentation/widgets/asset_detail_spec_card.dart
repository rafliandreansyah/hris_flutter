import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Spesifikasi Teknis & Rincian Pembelian Aset
class AssetDetailSpecCard extends StatelessWidget {
  final AssetDetailData asset;

  const AssetDetailSpecCard({super.key, required this.asset});

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

    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
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
          Row(
            children: [
              const Icon(
                LucideIcons.cpu,
                size: 16,
                color: AppColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Text(
                'SPESIFIKASI & RINCIAN UNIT',
                style: AppTypography.labelSmall.copyWith(
                  color: subtitleCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Specs list
          _buildSpecRow('Merk / Brand', asset.brand ?? '-', textCol, subtitleCol),
          _buildSpecRow('Model / Seri', asset.model ?? '-', textCol, subtitleCol),
          _buildSpecRow(
            'Nomor Seri / S/N',
            asset.serialNumber ?? '-',
            textCol,
            subtitleCol,
          ),
          _buildSpecRow(
            'Lokasi Penyimpanan',
            asset.location ?? 'Gudang Utama',
            textCol,
            subtitleCol,
          ),
          if (asset.purchaseDate != null)
            _buildSpecRow(
              'Tanggal Pembelian',
              dateFormat.format(asset.purchaseDate!),
              textCol,
              subtitleCol,
            ),
          if (asset.purchaseCost != null)
            _buildSpecRow(
              'Harga Pembelian',
              currencyFormat.format(asset.purchaseCost!),
              textCol,
              subtitleCol,
            ),
          if (asset.warrantyExpiry != null)
            _buildSpecRow(
              'Masa Garansi',
              dateFormat.format(asset.warrantyExpiry!),
              textCol,
              subtitleCol,
            ),
          if (asset.vendor != null && asset.vendor!.trim().isNotEmpty)
            _buildSpecRow('Vendor / Distributor', asset.vendor!, textCol, subtitleCol),
          if (asset.notes != null && asset.notes!.trim().isNotEmpty) ...[
            const Divider(height: 16),
            Text(
              'Catatan Tambahan',
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              asset.notes!,
              style: AppTypography.bodySmall.copyWith(
                color: textCol,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(
    String label,
    String value,
    Color textCol,
    Color subtitleCol,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall.copyWith(
                color: textCol,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
