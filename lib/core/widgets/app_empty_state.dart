import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget Empty State standar global HRIS berstandar Stitch M3 "Teal Oasis".
///
/// Menyediakan tampilan status kosong yang konsisten, presisi di tengah viewport
/// (true vertical center), ramah pengguna, dan responsif terhadap pull-to-refresh.
class AppEmptyState extends StatelessWidget {
  /// Ikon representasi fitur (misal: alarmClockOff, mapPinOff, receipt, dll)
  final IconData icon;

  /// Judul utama empty state
  final String title;

  /// Penjelasan atau panduan kontekstual
  final String? subtitle;

  /// Alias alternatif untuk subtitle
  final String? message;

  /// Menandakan apakah kondisi kosong dipicu oleh filter / query pencarian yang aktif
  final bool hasActiveFilter;

  /// Callback saat tombol "Reset Filter" ditekan
  final VoidCallback? onResetFilter;

  /// Label kustom untuk tombol reset filter (default: 'Reset Filter')
  final String? resetFilterText;

  /// Label untuk tombol aksi utama tambahan (opsional)
  final String? actionText;

  /// Alias alternatif untuk actionText
  final String? actionLabel;

  /// Ikon untuk tombol aksi utama tambahan (opsional)
  final IconData? actionIcon;

  /// Callback untuk tombol aksi utama tambahan (opsional)
  final VoidCallback? onAction;

  /// Varian tombol aksi utama (default: primary)
  final AppButtonVariant actionVariant;

  /// Teks banner info / panduan tambahan (opsional)
  final String? helperText;

  /// Apakah otomatis membungkus widget dalam LayoutBuilder + SingleChildScrollView
  /// agar presisi berada di tengah halaman dan mendukung RefreshIndicator.
  /// Set ke false jika sudah berada dalam container scroll kustom.
  final bool wrapInScrollView;

  /// Padding khusus (opsional)
  final EdgeInsetsGeometry? padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.message,
    this.hasActiveFilter = false,
    this.onResetFilter,
    this.resetFilterText,
    this.actionText,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionVariant = AppButtonVariant.primary,
    this.helperText,
    this.wrapInScrollView = true,
    this.padding,
  }) : assert(
          subtitle != null || message != null,
          'Either subtitle or message must be provided',
        );

  String get effectiveSubtitle => subtitle ?? message ?? '';
  String? get effectiveActionText => actionText ?? actionLabel;
  bool get _canShowReset =>
      (hasActiveFilter || onResetFilter != null) && onResetFilter != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final accentTeal =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final infoBg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLow;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final Widget content = Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icon Badge Lingkaran Ganda dengan Soft Teal Glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accentTeal.withValues(alpha: isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentTeal.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentTeal.withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 28,
                    color: accentTeal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Judul
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 16.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // 3. Deskripsi
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              effectiveSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),

          // 4. Helper Info Banner (opsional)
          if (helperText != null && helperText!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: infoBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: borderCol, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.info,
                        size: 15,
                        color: accentTeal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        helperText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 5. Tombol Aksi
          if (_canShowReset) ...[
            const SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: AppButton(
                text: resetFilterText ?? 'Reset Filter',
                leadingIcon: LucideIcons.rotateCcw,
                variant: AppButtonVariant.outlined,
                height: 44,
                onPressed: onResetFilter,
              ),
            ),
          ] else if (effectiveActionText != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: AppButton(
                text: effectiveActionText!,
                leadingIcon: actionIcon,
                variant: actionVariant,
                height: 44,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );

    if (!wrapInScrollView) {
      return Center(child: content);
    }

    // Viewport Centering: LayoutBuilder + ConstrainedBox(minHeight: maxHeight)
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
