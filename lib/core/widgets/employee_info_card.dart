import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';

/// Widget global untuk menampilkan informasi karyawan (avatar, nama, role, ID).
/// Reusable di seluruh aplikasi — dashboard, daftar aktivitas, history, dll.
class EmployeeInfoCard extends StatelessWidget {
  final String employeeName;
  final String employeeRole;
  final String employeeId;
  final String? photoUrl;
  final String? initials;
  final double avatarSize;

  const EmployeeInfoCard({
    super.key,
    required this.employeeName,
    required this.employeeRole,
    required this.employeeId,
    this.photoUrl,
    this.initials,
    this.avatarSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.onBackground;
    final textSecondary = isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;
    final borderColor = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          AppAvatar(
            imageUrl: photoUrl,
            name: employeeName,
            initials: initials,
            size: avatarSize,
            showBorder: true,
          ),
          const SizedBox(width: 14),

          // Name, Role & ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$employeeRole • ID: $employeeId',
                  style: AppTypography.bodyMedium.copyWith(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
