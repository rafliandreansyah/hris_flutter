import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal Bottom Sheet untuk menghubungi Admin Oasish via WhatsApp & Email
class ContactAdminBottomSheet extends StatelessWidget {
  static const String whatsappUrl =
      'https://api.whatsapp.com/send/?phone=6285888164634&text=Halo+Tim+Oasish%2C+saya+tertarik+dengan+software+HRIS+untuk+usaha+saya&type=phone_number&app_absent=0';
  static const String whatsappNumber = '+62 858-8816-4634';
  static const String adminEmail = 'halo@hroasish.com';

  const ContactAdminBottomSheet({super.key});

  /// Helper untuk menampilkan bottom sheet secara modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const ContactAdminBottomSheet(),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final uri = Uri.parse(whatsappUrl);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        AppDialogUtil.showError(
          context,
          message:
              'Tidak dapat membuka aplikasi WhatsApp. Nomor WhatsApp telah disalin ke papan klip: $whatsappNumber',
        );
      }
      await Clipboard.setData(const ClipboardData(text: '6285888164634'));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor WhatsApp telah disalin: +62 858-8816-4634'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
      }
      await Clipboard.setData(const ClipboardData(text: '6285888164634'));
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    try {
      final uri = Uri.parse(
        'mailto:$adminEmail?subject=Tertarik%20dengan%20Software%20HRIS%20Oasish',
      );
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        AppDialogUtil.showError(
          context,
          message:
              'Tidak dapat membuka aplikasi Email. Alamat email telah disalin: $adminEmail',
        );
      }
      await Clipboard.setData(const ClipboardData(text: adminEmail));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alamat email telah disalin: halo@hroasish.com'),
            backgroundColor: AppColors.brandTeal,
          ),
        );
      }
      await Clipboard.setData(const ClipboardData(text: adminEmail));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle Pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subtitleCol.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Header Title with Close Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.headset,
                      color: AppColors.brandTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hubungi Admin Oasish',
                          style: AppTypography.titleMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pilih jalur komunikasi untuk konsultasi atau pendaftaran akun perusahaan.',
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleCol,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: subtitleCol),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Option WhatsApp Card
              _buildContactCard(
                context,
                title: 'WhatsApp Official',
                subtitle: '+62 858-8816-4634',
                tag: 'Respon Cepat',
                tagColor: const Color(0xFF25D366),
                icon: LucideIcons.messageCircle,
                iconColor: const Color(0xFF25D366),
                iconBgColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                borderCol: borderCol,
                surfaceColor: surfaceColor,
                textCol: textCol,
                subtitleCol: subtitleCol,
                onTap: () {
                  Navigator.of(context).pop();
                  _openWhatsApp(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Option Email Card
              _buildContactCard(
                context,
                title: 'Email Support',
                subtitle: adminEmail,
                tag: 'Penawaran & Surat',
                tagColor: AppColors.brandTeal,
                icon: LucideIcons.mail,
                iconColor: AppColors.brandTeal,
                iconBgColor: AppColors.brandTeal.withValues(alpha: 0.12),
                borderCol: borderCol,
                surfaceColor: surfaceColor,
                textCol: textCol,
                subtitleCol: subtitleCol,
                onTap: () {
                  Navigator.of(context).pop();
                  _openEmail(context);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color borderCol,
    required Color surfaceColor,
    required Color textCol,
    required Color subtitleCol,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTypography.titleSmall.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.labelSmall.copyWith(
                              color: tagColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Arrow
              Icon(
                LucideIcons.arrowUpRight,
                color: subtitleCol,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
