import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget global baris info pegawai — avatar, nama, role, departemen, badge ID,
/// dan badge perusahaan. Reusable di seluruh aplikasi.
///
/// Menerima [EmployeeDirectoryItem] secara langsung ATAU parameter individual
/// ([name], [role], [department], [avatarUrl], [initials]) untuk kasus di mana
/// data bukan berasal dari model tersebut (misalnya [ActivityItem]).
///
/// Jika [company] null/kosong, badge perusahaan tidak ditampilkan.
/// Jika [employeeId] null/kosong, badge ID tidak ditampilkan.
class EmployeeInfoRow extends StatelessWidget {
  final EmployeeDirectoryItem? employee;

  /// Field individual (fallback jika [employee] null).
  final String? name;
  final String? role;
  final String? department;
  final String? company;
  final String? employeeId;
  final String? avatarUrl;
  final String? initials;

  final double avatarSize;

  const EmployeeInfoRow({
    super.key,
    this.employee,
    this.name,
    this.role,
    this.department,
    this.company,
    this.employeeId,
    this.avatarUrl,
    this.initials,
    this.avatarSize = 52,
  });

  // Helpers untuk resolved values dari model atau params individual
  String _resolvedName() => employee?.name ?? name ?? '';
  String _resolvedRole() => employee?.role ?? role ?? '';
  String _resolvedDepartment() => employee?.department ?? department ?? '';
  String? _resolvedCompany() => employee?.company ?? company;
  String _resolvedEmployeeId() {
    if (employee != null) {
      final num = employee!.employeeNumber;
      return (num != null && num.isNotEmpty) ? num : employee!.id;
    }
    return employeeId ?? '';
  }

  String? _resolvedAvatarUrl() => employee?.avatarUrl ?? avatarUrl;
  String? _resolvedInitials() => employee?.initials ?? initials;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final badgeBg = isDark
        ? AppColors.darkSurfaceContainerHigh
        : const Color(0xFFF1F5F9);

    final resolvedName = _resolvedName();
    final resolvedRole = _resolvedRole();
    final resolvedDept = _resolvedDepartment();
    final resolvedCompany = _resolvedCompany();
    final resolvedEmployeeId = _resolvedEmployeeId();
    final resolvedAvatarUrl = _resolvedAvatarUrl();
    final resolvedInitials = _resolvedInitials();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          imageUrl: resolvedAvatarUrl,
          name: resolvedName,
          initials: resolvedInitials,
          size: avatarSize,
          backgroundColor: isDark
              ? AppColors.darkPrimaryContainer
              : AppColors.accentTealLight,
          textColor: isDark
              ? AppColors.darkOnPrimaryContainer
              : AppColors.primary,
          fontSize: 18,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedName,
                style: AppTypography.titleMedium.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.5,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                resolvedDept.isNotEmpty
                    ? '$resolvedRole • $resolvedDept'
                    : resolvedRole,
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (resolvedEmployeeId.isNotEmpty)
                Wrap(
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.idCard,
                            size: 12,
                            color: subtitleCol,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            resolvedEmployeeId,
                            style: AppTypography.labelSmall.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((resolvedCompany?.isNotEmpty ?? false)) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            resolvedCompany!,
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
