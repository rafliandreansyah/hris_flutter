import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Rincian Saldo & Kuota Cuti Karyawan (Enhanced Leave View)
class LeaveBalancesCard extends StatelessWidget {
  const LeaveBalancesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final progressBg = isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SALDO & KUOTA CUTI',
          style: AppTypography.labelSmall.copyWith(
            color: labelCol,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Cuti Tahunan
              _LeaveQuotaItem(
                title: 'Cuti Tahunan',
                remainingDays: 10,
                totalDays: 12,
                usedDays: 2,
                expiryDate: 'Berlaku hingga 31 Desember 2024',
                showDivider: true,
                cardBg: cardBg,
                borderCol: borderCol,
                textCol: textCol,
                labelCol: labelCol,
                progressBg: progressBg,
              ),

              // 2. Cuti Sakit
              _LeaveQuotaItem(
                title: 'Cuti Sakit',
                remainingDays: 14,
                totalDays: 14,
                usedDays: 0,
                expiryDate: 'Berlaku hingga 31 Desember 2024',
                showDivider: true,
                cardBg: cardBg,
                borderCol: borderCol,
                textCol: textCol,
                labelCol: labelCol,
                progressBg: progressBg,
              ),

              // 3. Cuti Khusus (Melahirkan, Menikah, dll)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cuti Khusus',
                          style: AppTypography.titleSmall.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Sesuai Kebijakan',
                            style: AppTypography.labelSmall.copyWith(
                              color: labelCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cuti Melahirkan, Menikah, Berduka, dll.',
                      style: AppTypography.bodySmall.copyWith(
                        color: labelCol,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(title: 'TOTAL HAK', value: '-', textCol: textCol, labelCol: labelCol),
                        _StatColumn(title: 'TERPAKAI', value: '3', textCol: textCol, labelCol: labelCol),
                        _StatColumn(title: 'SISA KUOTA', value: '-', textCol: AppColors.brandTeal, labelCol: labelCol),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaveQuotaItem extends StatelessWidget {
  final String title;
  final int remainingDays;
  final int totalDays;
  final int usedDays;
  final String expiryDate;
  final bool showDivider;
  final Color cardBg;
  final Color borderCol;
  final Color textCol;
  final Color labelCol;
  final Color progressBg;

  const _LeaveQuotaItem({
    required this.title,
    required this.remainingDays,
    required this.totalDays,
    required this.usedDays,
    required this.expiryDate,
    required this.showDivider,
    required this.cardBg,
    required this.borderCol,
    required this.textCol,
    required this.labelCol,
    required this.progressBg,
  });

  @override
  Widget build(BuildContext context) {
    final usedFraction = (usedDays / totalDays).clamp(0.0, 1.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$remainingDays Hari Tersisa',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: progressBg,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: usedFraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(title: 'TOTAL HAK', value: '$totalDays', textCol: textCol, labelCol: labelCol),
                  _StatColumn(title: 'TERPAKAI', value: '$usedDays', textCol: textCol, labelCol: labelCol),
                  _StatColumn(title: 'SISA KUOTA', value: '$remainingDays', textCol: AppColors.brandTeal, labelCol: labelCol),
                ],
              ),
              const SizedBox(height: 10),

              // Expiry Date Footer
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 13, color: labelCol),
                  const SizedBox(width: 4),
                  Text(
                    expiryDate,
                    style: AppTypography.labelSmall.copyWith(
                      color: labelCol,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: borderCol),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color textCol;
  final Color labelCol;

  const _StatColumn({
    required this.title,
    required this.value,
    required this.textCol,
    required this.labelCol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: labelCol,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: textCol,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
