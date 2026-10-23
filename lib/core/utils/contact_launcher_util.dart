import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_icon_badge.dart';
import 'package:hris_flutter/core/widgets/whatsapp_icon.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka kontak pegawai: pilihan WhatsApp / telepon langsung, dan aplikasi email.
class ContactLauncherUtil {
  const ContactLauncherUtil._();

  /// Nomor ke format internasional tanpa tanda (08xx -> 628xx, +62 -> 62).
  static String? normalizePhone(String? raw) {
    var digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
    return digits;
  }

  static Uri whatsappUri(String normalizedPhone) =>
      Uri.parse('https://wa.me/$normalizedPhone');

  static Uri telUri(String normalizedPhone) => Uri.parse('tel:+$normalizedPhone');

  static Uri mailUri(String email) =>
      Uri(scheme: 'mailto', path: email.trim());

  /// Tombol telepon: tampilkan pilihan WhatsApp atau Telepon.
  static Future<void> showPhoneOptions(
    BuildContext context, {
    required String name,
    required String? phone,
  }) async {
    final number = normalizePhone(phone);
    if (number == null) {
      await AppDialogUtil.showError(
        context,
        title: 'Nomor Belum Tersedia',
        message: '$name belum memiliki nomor telepon.',
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hubungi $name',
                style: AppTypography.titleMedium.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+$number',
                style: AppTypography.bodySmall.copyWith(color: subCol),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const ValueKey('contact_whatsapp_option'),
                contentPadding: EdgeInsets.zero,
                leading: const AppIconBadge(
                  color: AppColors.whatsappGreen,
                  child: WhatsAppIcon(size: 20),
                ),
                title: Text('WhatsApp',
                    style: AppTypography.bodyMedium.copyWith(color: textCol)),
                onTap: () => Navigator.of(sheetContext).pop('whatsapp'),
              ),
              ListTile(
                key: const ValueKey('contact_call_option'),
                contentPadding: EdgeInsets.zero,
                leading: AppIconBadge(
                  icon: LucideIcons.phone,
                  color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                ),
                title: Text('Telepon',
                    style: AppTypography.bodyMedium.copyWith(color: textCol)),
                onTap: () => Navigator.of(sheetContext).pop('call'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return;
    final ok = await _launch(
      choice == 'whatsapp' ? whatsappUri(number) : telUri(number),
    );
    if (!ok && context.mounted) {
      await AppDialogUtil.showError(
        context,
        message: choice == 'whatsapp'
            ? 'Tidak dapat membuka WhatsApp.'
            : 'Tidak dapat membuka aplikasi telepon.',
      );
    }
  }

  /// Tombol email: buka aplikasi email dengan alamat pegawai sebagai penerima.
  static Future<void> composeEmail(
    BuildContext context, {
    required String name,
    required String? email,
  }) async {
    if (email == null || email.trim().isEmpty) {
      await AppDialogUtil.showError(
        context,
        title: 'Email Belum Tersedia',
        message: '$name belum memiliki alamat email.',
      );
      return;
    }
    final ok = await _launch(mailUri(email));
    if (!ok && context.mounted) {
      await AppDialogUtil.showError(
        context,
        message: 'Tidak dapat membuka aplikasi email.',
      );
    }
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
