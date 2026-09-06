import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card item representasi karyawan di halaman Employee Directory
/// disinkronkan langsung dengan Google Stitch Design System.
class EmployeeCard extends StatelessWidget {
  final EmployeeDirectoryItem employee;
  final VoidCallback onTap;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg =
        isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final cardBorder =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final nameCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final roleCol = isDark ? AppColors.inversePrimary : AppColors.primary;
    final textMuted =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;
    final badgeBg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer;
    final badgeBorder =
        isDark ? AppColors.darkOutline : AppColors.outlineMuted;
    final actionBtnBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.accentTealLight;
    final actionBtnFg =
        isDark ? AppColors.darkOnPrimaryContainer : AppColors.primary;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.brandTeal.withValues(alpha: 0.08),
        highlightColor: AppColors.brandTeal.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Section: Avatar, Meta Info, & Action Buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with Initials Fallback
                  AppAvatar(
                    imageUrl: employee.avatarUrl,
                    name: employee.name,
                    initials: employee.initials,
                    size: 48,
                    showBorder: true,
                    borderColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.primaryFixedDim,
                    backgroundColor: actionBtnBg,
                    textColor: roleCol,
                    fontSize: 16,
                  ),
                  const SizedBox(width: 12),

                  // Name, Role & Department + ID Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: nameCol,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.role,
                          style: AppTypography.labelMedium.copyWith(
                            color: roleCol,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              employee.department,
                              style: AppTypography.labelSmall.copyWith(
                                color: textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: textMuted.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: badgeBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'ID: ${employee.id}',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Buttons: Phone & Mail
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuickActionButton(
                        context: context,
                        icon: LucideIcons.phone,
                        bgCol: actionBtnBg,
                        fgCol: actionBtnFg,
                        tooltip: 'Telepon ${employee.name}',
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menghubungi ${employee.name} (${employee.phone ?? "Nomor belum tersedia"})',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        context: context,
                        icon: LucideIcons.mail,
                        bgCol: actionBtnBg,
                        fgCol: actionBtnFg,
                        tooltip: 'Kirim Email ke ${employee.name}',
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Mengirim email ke ${employee.email}',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: cardBorder,
              ),
              const SizedBox(height: 10),

              // 2. Bottom Section: Email address and "View Profile" link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.atSign,
                          size: 15,
                          color: textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            employee.email,
                            style: AppTypography.labelSmall.copyWith(
                              color: textMuted,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Profile',
                        style: AppTypography.labelMedium.copyWith(
                          color: roleCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: roleCol,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required Color bgCol,
    required Color fgCol,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgCol,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          splashColor: fgCol.withValues(alpha: 0.2),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Icon(
                icon,
                size: 17,
                color: fgCol,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
