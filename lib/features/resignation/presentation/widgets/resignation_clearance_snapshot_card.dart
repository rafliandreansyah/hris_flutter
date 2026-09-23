import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ResignationClearanceSnapshotCard extends StatelessWidget {
  final ResignationDetailModel resignation;

  const ResignationClearanceSnapshotCard({
    super.key,
    required this.resignation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final clearance = resignation.clearanceSnapshot;
    final itAssets = clearance?.itAssets;
    final finance = clearance?.finance;

    final hasUnreturnedAsset = itAssets != null && !itAssets.isCleared;
    final assetTitle = hasUnreturnedAsset
        ? '${itAssets.count} Perangkat Belum Kembali'
        : 'Semua Aset Dikembalikan';
    final assetSubtitle = hasUnreturnedAsset && itAssets.items.isNotEmpty
        ? '${itAssets.items.first.assetName} (${itAssets.items.first.assetCode})'
        : 'Inventaris & hak akses IT telah beres';
    final assetBadgeText = hasUnreturnedAsset ? 'Perlu Serah Terima' : 'Beres';
    final isAssetOk = !hasUnreturnedAsset;

    final hasOpenFinance = finance != null && !finance.isCleared;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final financeTitle = hasOpenFinance
        ? 'Kasbon Aktif: ${currencyFormatter.format(finance.totalUnsettledCashAdvance)}'
        : 'Keuangan Bersih (Rp 0)';
    final financeSubtitle = hasOpenFinance
        ? '${finance.openCashAdvanceCount} kasbon terbuka, ${finance.pendingReimbursementCount} klaim pending'
        : 'Tidak ada tunggakan kasbon atau klaim gantung';
    final financeBadgeText = hasOpenFinance ? 'Pending' : 'Beres';
    final isFinanceOk = !hasOpenFinance;

    final handoverName = resignation.handoverTo?.fullName;
    final handoverDept = resignation.handoverTo?.departmentName ??
        resignation.handoverTo?.positionName;
    final hasHandover = handoverName != null && handoverName.isNotEmpty;
    const handoverTitle = 'Handover Rekan Kerja';
    final handoverSubtitle = hasHandover
        ? (handoverDept != null ? '$handoverName ($handoverDept)' : handoverName)
        : 'Rekan serah terima belum ditentukan';
    final handoverBadgeText = hasHandover ? 'Disepakati' : 'Menunggu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnosa Clearance',
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Terhubung otomatis ke sistem IT & Finance kantor',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF134E4A)
                      : const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: brandCol,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live Sync',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF5EEAD4)
                            : const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item 1: IT Assets
          _buildDiagnosaItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            borderCol: borderCol,
            icon: LucideIcons.laptop,
            iconBg: isAssetOk
                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
            iconColor: isAssetOk
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
            title: assetTitle,
            subtitle: assetSubtitle,
            badgeText: assetBadgeText,
            isSuccess: isAssetOk,
          ),
          const SizedBox(height: 10),

          // Item 2: Keuangan / Finance
          _buildDiagnosaItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            borderCol: borderCol,
            icon: LucideIcons.walletCards,
            iconBg: isFinanceOk
                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
            iconColor: isFinanceOk
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
            title: financeTitle,
            subtitle: financeSubtitle,
            badgeText: financeBadgeText,
            isSuccess: isFinanceOk,
          ),
          const SizedBox(height: 10),

          // Item 3: Handover Rekan Kerja
          _buildDiagnosaItem(
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
            borderCol: borderCol,
            icon: LucideIcons.arrowLeftRight,
            iconBg: isDark
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFDBEAFE),
            iconColor: isDark
                ? const Color(0xFF93C5FD)
                : const Color(0xFF2563EB),
            title: handoverTitle,
            subtitle: handoverSubtitle,
            badgeText: handoverBadgeText,
            isSuccess: hasHandover,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosaItem({
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required bool isSuccess,
  }) {
    final badgeBg = isSuccess
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7));
    final badgeFg = isSuccess
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textCol,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleCol,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
