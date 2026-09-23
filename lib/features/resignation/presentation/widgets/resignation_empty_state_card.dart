import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ResignationEmptyStateCard extends StatelessWidget {
  final VoidCallback? onCreatePressed;

  const ResignationEmptyStateCard({
    super.key,
    this.onCreatePressed,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: surfaceCol,
          borderRadius: BorderRadius.circular(20),
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
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF134E4A)
                    : const Color(0xFFCCFBF1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.fileCheck2,
                size: 34,
                color: brandCol,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tidak Ada Pengajuan Aktif',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Anda saat ini tidak memiliki permohonan pengunduran diri yang sedang aktif atau diproses.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 18,
                    color: brandCol,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ketentuan Notice Period (30 Hari)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Permohonan pengunduran diri wajib diajukan minimal 30 hari kerja sebelum tanggal efektif terakhir bekerja sesuai PKB perusahaan.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: subtitleCol,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: '+ Ajukan Pengunduran Diri',
              leadingIcon: LucideIcons.plus,
              variant: AppButtonVariant.primary,
              height: 48,
              onPressed: onCreatePressed,
            ),
          ],
        ),
      ),
    );
  }
}
