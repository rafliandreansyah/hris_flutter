import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Informasi Atasan Langsung (Direct Reporting Manager)
class ManagerInfoCard extends StatelessWidget {
  final String? name;
  final String? role;
  final String? department;
  final String? company;
  final String? employeeId;
  final String? initials;
  final String? avatarUrl;

  const ManagerInfoCard({
    super.key,
    this.name,
    this.role,
    this.department,
    this.company,
    this.employeeId,
    this.initials,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final hasManager = name != null && name!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIRECT REPORTING MANAGER',
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
          child: hasManager
              ? Row(
                  children: [
                    AppAvatar(
                      imageUrl: avatarUrl,
                      name: name,
                      initials: initials,
                      size: 44,
                      showBorder: true,
                      borderColor: borderCol,
                      fontSize: 15,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name!,
                            style: AppTypography.titleSmall.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${role ?? "Direct Manager"} • ${department ?? ""}',
                            style: AppTypography.bodySmall.copyWith(
                              color: labelCol,
                              fontSize: 12,
                            ),
                          ),
                          if (company != null || employeeId != null)
                            Text(
                              [company, employeeId]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(' • '),
                              style: AppTypography.labelSmall.copyWith(
                                color: labelCol.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderCol),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.userX,
                        size: 20,
                        color: labelCol,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Belum Ada Atasan Langsung',
                            style: AppTypography.titleSmall.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pegawai ini belum memiliki atasan langsung yang terdaftar.',
                            style: AppTypography.bodySmall.copyWith(
                              color: labelCol,
                              fontSize: 12,
                            ),
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
