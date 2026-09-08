import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/localization/bloc/locale_bloc.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Menampilkan Bottom Sheet dialog "Account Settings" sesuai spesifikasi Google Stitch
/// (Project: Oasish Flutter M3 HRIS - ID: 17152850901645837896, Screen ID: 155d605db9dc42838aa0f1a1ab950b2c).
Future<void> showAccountSettingsBottomSheet(
  BuildContext context, {
  String? name,
  String? role,
  String? employeeId,
  String? status,
  String? avatarUrl,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => AccountSettingsBottomSheet(
      name: name ?? 'Sarah Jenkins',
      role: role ?? 'Senior Frontend Engineer',
      employeeId: employeeId ?? 'EMP-2024-019',
      status: status ?? 'Active',
      avatarUrl: avatarUrl,
    ),
  );
}

class AccountSettingsBottomSheet extends StatelessWidget {
  final String name;
  final String role;
  final String employeeId;
  final String status;
  final String? avatarUrl;

  const AccountSettingsBottomSheet({
    super.key,
    this.name = 'Sarah Jenkins',
    this.role = 'Senior Frontend Engineer',
    this.employeeId = 'EMP-2024-019',
    this.status = 'Active',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale =
        context.watch<LocaleBloc?>()?.state.locale ?? const Locale('id');
    final isEn = currentLocale.languageCode == 'en';
    final languageBadge = isEn ? 'EN (English)' : 'ID (Bahasa)';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final cardBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;
    final iconCircleBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainer;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkOutlineMuted
                          : AppColors.outlineMuted,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Title
                Text(
                  l10n?.accountSettings ?? 'Account Settings',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 3. Profile Overview Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      AppAvatar(
                        imageUrl: avatarUrl,
                        name: name,
                        size: 56,
                        showBorder: true,
                        borderColor: borderCol,
                        borderWidth: 1.5,
                        fontSize: 18,
                      ),
                      const SizedBox(width: 14),

                      // User Info & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.titleMedium.copyWith(
                                color: textCol,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role,
                              style: AppTypography.bodyMedium.copyWith(
                                color: labelCol,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // EMP ID Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceContainerHighest
                                        : const Color(0xFFDAE2FD),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    employeeId,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Active Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        status,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: const Color(0xFF15803D),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Section Label: PENGATURAN & PREFERENSI
                Text(
                  l10n?.settingsAndPreferences ?? 'PENGATURAN & PREFERENSI',
                  style: AppTypography.labelMedium.copyWith(
                    color: labelCol,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // 5. Settings Card Group
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Item 1: Ganti Password
                      _SettingsListTile(
                        icon: LucideIcons.keyRound,
                        iconBg: iconCircleBg,
                        iconColor: textCol,
                        title: l10n?.changePassword ?? 'Ganti Password',
                        subtitle: l10n?.changePasswordSubtitle ??
                            'Perbarui kata sandi akun keamanan Anda',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(Routes.RESET);
                        },
                      ),
                      Divider(height: 1, thickness: 1, color: borderCol),

                      // Item 2: Notifikasi
                      _SettingsListTile(
                        icon: LucideIcons.bellRing,
                        iconBg: iconCircleBg,
                        iconColor: textCol,
                        title: l10n?.notifications ?? 'Notifikasi',
                        subtitle: l10n?.notificationsSubtitle ??
                            'Pengingat absen, izin, lembur & broadcast',
                        badgeText: l10n?.active ?? 'Aktif',
                        badgeBg: const Color(0xFFDCFCE7),
                        badgeFg: const Color(0xFF15803D),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pengaturan notifikasi sedang aktif',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, thickness: 1, color: borderCol),

                      // Item 3: Bahasa
                      _SettingsListTile(
                        icon: LucideIcons.languages,
                        iconBg: iconCircleBg,
                        iconColor: textCol,
                        title: l10n?.language ?? 'Bahasa (Language)',
                        subtitle: l10n?.languageSubtitle ??
                            'Pilih bahasa tampilan aplikasi',
                        badgeText: languageBadge,
                        badgeBg: AppColors.brandTeal,
                        badgeFg: Colors.white,
                        onTap: () {
                          _showLanguageDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Section 2: Logout Action Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A1215)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF5C1D24)
                          : const Color(0xFFFECACA),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showLogoutConfirmationDialog(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF451218)
                                    : const Color(0xFFFEE2E2),
                              ),
                              child: const Icon(
                                LucideIcons.logOut,
                                size: 20,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.logout ?? 'Keluar dari Akun (Logout)',
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: const Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n?.logoutSubtitle ??
                                        'Keluar dari sesi login perangkat ini',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? const Color(0xFFF87171)
                                          : const Color(0xFF991B1B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 7. Footer: Component Versi Standar Proyek (AppNameVersionText)
                const Center(child: AppNameVersionText()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale =
        context.read<LocaleBloc?>()?.state.locale ?? const Locale('id');
    final currentCode = currentLocale.languageCode;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n?.selectLanguage ?? 'Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: currentCode == 'id'
                  ? const Icon(
                      LucideIcons.check,
                      color: AppColors.brandTeal,
                    )
                  : const SizedBox(width: 24),
              title: Text(l10n?.indonesian ?? 'Bahasa Indonesia (ID)'),
              onTap: () {
                Navigator.of(dialogCtx).pop();
                if (currentCode != 'id') {
                  context.read<LocaleBloc?>()?.add(const LocaleChanged('id'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.languageUpdatedSuccess ??
                            'Bahasa berhasil diperbarui',
                      ),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: currentCode == 'en'
                  ? const Icon(
                      LucideIcons.check,
                      color: AppColors.brandTeal,
                    )
                  : const SizedBox(width: 24),
              title: Text(l10n?.english ?? 'English (EN)'),
              onTap: () {
                Navigator.of(dialogCtx).pop();
                if (currentCode != 'en') {
                  context.read<LocaleBloc?>()?.add(const LocaleChanged('en'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.languageUpdatedSuccess ??
                            'Language updated successfully',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n?.logoutConfirmationTitle ?? 'Konfirmasi Logout'),
        content: Text(
          l10n?.logoutConfirmationDesc ??
              'Apakah Anda yakin ingin keluar dari sesi akun ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n?.cancel ?? 'Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop(); // Tutup dialog
              Navigator.of(context).pop(); // Tutup bottom sheet
              await AuthRepositoryImpl().logout();
              if (context.mounted) {
                context.go(Routes.LOGIN);
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeFg;
  final VoidCallback onTap;

  const _SettingsListTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeBg,
    this.badgeFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTypography.bodyLarge.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              badgeText!,
                              style: AppTypography.labelSmall.copyWith(
                                color: badgeFg,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: labelCol,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Chevron Right
              Icon(LucideIcons.chevronRight, size: 18, color: labelCol),
            ],
          ),
        ),
      ),
    );
  }
}
