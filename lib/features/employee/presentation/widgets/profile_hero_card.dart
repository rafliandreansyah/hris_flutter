import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Hero Card Profil Karyawan (Teal Oasis)
class ProfileHeroCard extends StatelessWidget {
  final String name;
  final String role;
  final String level;
  final String department;
  final String company;
  final String employmentStatus;
  final String contractType;
  final String? avatarUrl;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback? onChat;

  /// Aksi lihat jadwal kerja. Null = tombol disembunyikan (tidak berwenang).
  final VoidCallback? onViewSchedule;
  final bool isSelf;

  const ProfileHeroCard({
    super.key,
    this.name = '-',
    this.role = '-',
    this.level = '-',
    this.department = '-',
    this.company = '-',
    this.employmentStatus = '-',
    this.contractType = '-',
    this.avatarUrl,
    this.onCall,
    this.onEmail,
    this.onChat,
    this.onViewSchedule,
    this.isSelf = false,
  });

  static bool _has(String v) => v.trim().isNotEmpty && v.trim() != '-';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final actionBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar Image with Teal Ring
          AppAvatar(
            imageUrl: avatarUrl,
            name: name,
            size: 80,
            showBorder: true,
            borderColor: AppColors.brandTeal,
            borderWidth: 2.5,
            fontSize: 24,
          ),
          const SizedBox(height: AppSpacing.md - 4),

          // Name
          Text(
            name,
            style: AppTypography.headlineLargeMobile.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Jabatan
          if (_has(role))
            Text(
              role,
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              textAlign: TextAlign.center,
            ),
          if (_has(level)) ...[
            const SizedBox(height: 2),
            Text(
              level,
              style: AppTypography.bodySmall.copyWith(
                color: labelCol,
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.md - 4),

          // Badge status kepegawaian & tipe kontrak
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm - 2,
            children: [
              if (_has(employmentStatus))
                _Badge(
                  label: employmentStatus,
                  bg: isDark
                      ? AppColors.success.withValues(alpha: 0.18)
                      : AppColors.successContainer,
                  fg: isDark
                      ? AppColors.success
                      : AppColors.onSuccessContainer,
                ),
              if (_has(contractType))
                _Badge(
                  label: contractType,
                  bg: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.primaryContainer,
                  fg: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                ),
            ],
          ),

          // Departemen & perusahaan — baris terpisah agar teks panjang tidak terpotong
          if (_has(department) || _has(company)) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 2,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: actionBg,
                borderRadius: AppRadius.borderInput,
              ),
              child: Column(
                children: [
                  if (_has(department))
                    _OrgLine(
                      icon: LucideIcons.layers,
                      text: department,
                      color: textCol,
                      iconColor: labelCol,
                    ),
                  if (_has(department) && _has(company))
                    const SizedBox(height: AppSpacing.sm),
                  if (_has(company))
                    _OrgLine(
                      icon: LucideIcons.building2,
                      text: company,
                      color: textCol,
                      iconColor: labelCol,
                    ),
                ],
              ),
            ),
          ],

          // Aksi cepat
          if (!isSelf || onViewSchedule != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (!isSelf) ...[
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.phone,
                      label: 'Hubungi',
                      backgroundColor: actionBg,
                      onTap: onCall ?? () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickActionButton(
                      icon: LucideIcons.mail,
                      label: 'Email',
                      backgroundColor: actionBg,
                      onTap: onEmail ?? () {},
                    ),
                  ),
                ],
                if (onViewSchedule != null) ...[
                  if (!isSelf) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickActionButton(
                      key: const ValueKey('profile_view_schedule_button'),
                      icon: LucideIcons.calendarClock,
                      label: 'Jadwal Kerja',
                      backgroundColor: actionBg,
                      onTap: onViewSchedule!,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.borderFull),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _OrgLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color iconColor;

  const _OrgLine({
    required this.icon,
    required this.text,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkOnSurface
        : AppColors.darkSurfaceContainerHigh;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
