import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Alamat Domisili & Kantor Penugasan Karyawan
class WorkLocationCard extends StatelessWidget {
  final String residentialAddress;
  final String officeName;
  final String officeAddress;
  final String radius;
  final bool isDefaultOffice;

  const WorkLocationCard({
    super.key,
    this.residentialAddress =
        'Jl. Dharmahusada Indah Barat No. 88, Kel. Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60285, Indonesia',
    this.officeName = 'HQ Office Sudirman',
    this.officeAddress = 'SCBD Lot 28 Floor 14, Jakarta Selatan',
    this.radius = '50m',
    this.isDefaultOffice = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final iconBoxBg = isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Residential Address
        Text(
          'RESIDENTIAL ADDRESS',
          style: AppTypography.labelSmall.copyWith(
            color: labelCol,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.home,
                size: 18,
                color: labelCol,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  residentialAddress,
                  style: AppTypography.bodySmall.copyWith(
                    color: textCol,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Assigned Work Location
        Text(
          'ASSIGNED WORK LOCATIONS',
          style: AppTypography.labelSmall.copyWith(
            color: labelCol,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.building2,
                  size: 20,
                  color: AppColors.brandTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officeName,
                      style: AppTypography.titleSmall.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      officeAddress,
                      style: AppTypography.bodySmall.copyWith(
                        color: labelCol,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Radius Absensi: $radius',
                      style: AppTypography.labelSmall.copyWith(
                        color: labelCol.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDefaultOffice)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF15803D),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
