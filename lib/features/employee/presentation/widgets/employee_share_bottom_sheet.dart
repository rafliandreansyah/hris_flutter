import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/share_link_util.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka modal bottom sheet pilihan share profil karyawan
/// (WhatsApp, Email, Salin Link, dan Bagikan Lainnya).
Future<void> showEmployeeShareBottomSheet(
  BuildContext context, {
  required String employeeId,
  required String name,
  String? role,
  String? department,
  String? company,
  String? email,
  String? phone,
}) {
  final url = ShareLinkUtil.webUrl(ShareModule.employee, employeeId);

  final text = StringBuffer()..writeln('Profil Karyawan: $name');
  if (role != null && role.isNotEmpty && role != '-') {
    text.writeln('Posisi: $role');
  }
  if (department != null && department.isNotEmpty && department != '-') {
    text.writeln('Departemen: $department');
  }
  if (company != null && company.isNotEmpty && company != '-') {
    text.writeln('Perusahaan: $company');
  }
  if (email != null && email.isNotEmpty && email != '-') {
    text.writeln('Email: $email');
  }
  if (phone != null && phone.isNotEmpty && phone != '-') {
    text.writeln('No. HP: $phone');
  }
  text
    ..writeln()
    ..writeln('Lihat profil lengkap:')
    ..writeln(url);

  final message = text.toString();
  final subject = 'Profil Karyawan: $name';

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => EmployeeShareBottomSheet(
      parentContext: context,
      name: name,
      url: url,
      message: message,
      subject: subject,
    ),
  );
}

class EmployeeShareBottomSheet extends StatelessWidget {
  final BuildContext? parentContext;
  final String name;
  final String url;
  final String message;
  final String subject;

  const EmployeeShareBottomSheet({
    super.key,
    this.parentContext,
    required this.name,
    required this.url,
    required this.message,
    required this.subject,
  });

  BuildContext _targetContext(BuildContext fallback) {
    if (parentContext != null && parentContext!.mounted) {
      return parentContext!;
    }
    return fallback;
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final target = _targetContext(context);
    Navigator.of(context).pop();
    final uri = ShareLinkUtil.whatsAppShareUri(message);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && target.mounted) {
        await AppDialogUtil.showError(
          target,
          title: 'Gagal Membuka WhatsApp',
          message: 'Tidak dapat membuka aplikasi WhatsApp di perangkat ini.',
        );
      }
    } catch (_) {
      if (target.mounted) {
        await AppDialogUtil.showError(
          target,
          title: 'Gagal Membuka WhatsApp',
          message: 'Tidak dapat membuka aplikasi WhatsApp di perangkat ini.',
        );
      }
    }
  }

  Future<void> _shareEmail(BuildContext context) async {
    final target = _targetContext(context);
    Navigator.of(context).pop();
    final uri = ShareLinkUtil.emailShareUri(subject: subject, body: message);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && target.mounted) {
        await AppDialogUtil.showError(
          target,
          title: 'Gagal Membuka Email',
          message: 'Tidak dapat membuka aplikasi email di perangkat ini.',
        );
      }
    } catch (_) {
      if (target.mounted) {
        await AppDialogUtil.showError(
          target,
          title: 'Gagal Membuka Email',
          message: 'Tidak dapat membuka aplikasi email di perangkat ini.',
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    final target = _targetContext(context);
    Navigator.of(context).pop();
    await ShareLinkUtil.copyLink(
      target,
      url,
      title: 'Link Disalin',
      message: 'Link profil karyawan berhasil disalin ke clipboard.',
    );
  }

  void _shareOthers(BuildContext context) {
    Navigator.of(context).pop();
    SharePlus.instance.share(
      ShareParams(text: message, subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final linkCardBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title & Subtitle + Close
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.inversePrimary : AppColors.brandTeal)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.share2,
                    size: 18,
                    color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bagikan Profil',
                        style: AppTypography.titleMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih metode untuk membagikan tautan profil $name',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 20, color: subtitleCol),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Deep link preview box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: linkCardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.link,
                    size: 15,
                    color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url,
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Options List
            _ShareOptionTile(
              key: const ValueKey('employee_share_whatsapp'),
              icon: LucideIcons.messageCircle,
              iconColor: const Color(0xFF15803D),
              iconBgColor: const Color(0xFFDCFCE7),
              title: 'WhatsApp',
              subtitle: 'Kirim ringkasan & link profil ke WhatsApp',
              onTap: () => _shareWhatsApp(context),
            ),
            const SizedBox(height: 8),
            _ShareOptionTile(
              key: const ValueKey('employee_share_email'),
              icon: LucideIcons.mail,
              iconColor: const Color(0xFF1D4ED8),
              iconBgColor: const Color(0xFFDBEAFE),
              title: 'Email',
              subtitle: 'Kirim detail profil via aplikasi email',
              onTap: () => _shareEmail(context),
            ),
            const SizedBox(height: 8),
            _ShareOptionTile(
              key: const ValueKey('employee_share_copy'),
              icon: LucideIcons.copy,
              iconColor: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
              iconBgColor: (isDark ? AppColors.inversePrimary : AppColors.brandTeal)
                  .withValues(alpha: 0.12),
              title: 'Salin Link',
              subtitle: 'Salin tautan deep link ke clipboard',
              onTap: () => _copyLink(context),
            ),
            const SizedBox(height: 8),
            _ShareOptionTile(
              key: const ValueKey('employee_share_more'),
              icon: LucideIcons.share2,
              iconColor: textCol,
              iconBgColor: isDark
                  ? AppColors.darkSurfaceContainerHigh
                  : AppColors.surfaceContainerHigh,
              title: 'Bagikan Lainnya',
              subtitle: 'Gunakan menu share bawaan perangkat',
              onTap: () => _shareOthers(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: subtitleCol),
            ],
          ),
        ),
      ),
    );
  }
}
