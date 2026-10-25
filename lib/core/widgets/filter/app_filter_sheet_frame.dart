import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kerangka (frame) standar seluruh bottom sheet filter.
///
/// Struktur seragam agar header lega dan konsisten:
/// - Header: judul filter + tombol close (x) sejajar di kanan.
/// - Body: konten form filter yang dapat di-scroll.
/// - Footer: tombol "Reset" (outlined) sejajar dengan "Terapkan Filter".
class AppFilterSheetFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onReset;
  final VoidCallback? onApply;
  final String applyLabel;
  final String resetLabel;
  final bool isApplying;
  final EdgeInsetsGeometry bodyPadding;

  /// Tinggi maksimum sheet relatif terhadap layar.
  final double maxHeightFactor;

  /// Jika true, sheet selalu mengisi [maxHeightFactor] (untuk konten panjang
  /// seperti daftar grid yang memakai Expanded di dalamnya).
  final bool expandBody;

  /// Jika false, [child] tidak dibungkus SingleChildScrollView (konten
  /// mengatur scroll sendiri).
  final bool scrollable;

  const AppFilterSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.onReset,
    this.onApply,
    this.applyLabel = 'Terapkan Filter',
    this.resetLabel = 'Reset',
    this.isApplying = false,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    this.maxHeightFactor = 0.88,
    this.expandBody = false,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final media = MediaQuery.of(context);

    final body = scrollable
        ? SingleChildScrollView(padding: bodyPadding, child: child)
        : Padding(padding: bodyPadding, child: child);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: Judul + Close ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(LucideIcons.x, size: 22, color: subtitleCol),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: borderCol),

            // ── Body ─────────────────────────────────────────────────
            if (expandBody) Expanded(child: body) else Flexible(child: body),

            // ── Footer: Reset + Terapkan ─────────────────────────────
            Divider(height: 1, thickness: 1, color: borderCol),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md - 4,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: resetLabel,
                        leadingIcon: LucideIcons.rotateCcw,
                        variant: AppButtonVariant.outlined,
                        height: 50,
                        onPressed: isApplying ? null : onReset,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md - 4),
                    Expanded(
                      child: AppButton(
                        text: applyLabel,
                        leadingIcon: LucideIcons.filter,
                        variant: AppButtonVariant.primary,
                        height: 50,
                        isLoading: isApplying,
                        onPressed: isApplying ? null : onApply,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
