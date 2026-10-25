import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Header ringkas untuk kartu di halaman daftar pengajuan.
///
/// Hanya menampilkan informasi paling penting agar tidak terpotong:
/// avatar, nama, dan jabatan (atau departemen sebagai fallback), plus
/// [trailing] (biasanya chip status) di kanan. Detail lengkap pegawai
/// (NIP, perusahaan, departemen, kontak) tersedia di halaman detail.
class RequestCardHeader extends StatelessWidget {
  final String name;
  final String? role;
  final String? department;
  final String? avatarUrl;
  final String? initials;
  final Widget? trailing;

  /// Menandai pengajuan milik pengguna sendiri.
  final bool isSelf;
  final double avatarSize;

  const RequestCardHeader({
    super.key,
    required this.name,
    this.role,
    this.department,
    this.avatarUrl,
    this.initials,
    this.trailing,
    this.isSelf = false,
    this.avatarSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final subtitle = (role?.trim().isNotEmpty ?? false)
        ? role!.trim()
        : (department?.trim() ?? '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          imageUrl: avatarUrl,
          name: name,
          initials: initials,
          size: avatarSize,
          backgroundColor: isDark
              ? AppColors.darkPrimaryContainer
              : AppColors.accentTealLight,
          textColor: isDark
              ? AppColors.darkOnPrimaryContainer
              : AppColors.primary,
          fontSize: 15,
        ),
        const SizedBox(width: AppSpacing.md - 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelf) ...[
                Row(
                  children: [
                    Icon(LucideIcons.user, size: 12, color: brandColor),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Pengajuan Anda',
                      style: AppTypography.labelSmall.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
              // Nama & jabatan boleh turun ke baris berikutnya — tidak dipotong.
              Text(
                name,
                style: AppTypography.titleSmall.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                softWrap: true,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm + 2),
          trailing!,
        ],
      ],
    );
  }
}

/// Baris info ringkas (ikon + teks) untuk isi kartu daftar pengajuan.
class RequestCardInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? trailingText;
  final bool emphasize;

  const RequestCardInfoLine({
    super.key,
    required this.icon,
    required this.text,
    this.trailingText,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Row(
      children: [
        Icon(icon, size: 15, color: subtitleCol),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: textCol,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingText != null && trailingText!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailingText!,
            style: AppTypography.labelMedium.copyWith(
              color: subtitleCol,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Kerangka kartu daftar pengajuan: header pegawai, divider, lalu isi ringkas.
class RequestListCardFrame extends StatelessWidget {
  final Widget header;
  final List<Widget> children;
  final VoidCallback? onTap;
  final bool dimmed;

  const RequestListCardFrame({
    super.key,
    required this.header,
    required this.children,
    this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Opacity(
      opacity: dimmed ? 0.9 : 1,
      child: Material(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(AppRadius.lg + 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg + 2),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg + 2),
              border: Border.all(color: borderCol),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  if (children.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md - 4,
                      ),
                      child: Divider(height: 1, thickness: 1, color: borderCol),
                    ),
                    ...children,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kutipan catatan singkat (maks 1 baris) untuk kartu daftar pengajuan.
class RequestCardNote extends StatelessWidget {
  final String text;

  const RequestCardNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    return Text(
      '“${text.trim()}”',
      style: AppTypography.bodySmall.copyWith(
        color: subtitleCol,
        fontStyle: FontStyle.italic,
        fontSize: 12.5,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
