import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tampilan standar global untuk HTTP 403 Forbidden (tidak memiliki hak akses).
///
/// Kartu di tengah halaman dengan ikon perisai, judul, pesan (sebaiknya dari API),
/// tombol "Coba Lagi" dan tombol aksi opsional (mis. kembali ke tab milik sendiri).
class AppForbiddenState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? actionText;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const AppForbiddenState({
    super.key,
    this.title = 'Tidak Memiliki Hak Akses',
    required this.message,
    this.onRetry,
    this.actionText,
    this.actionIcon = LucideIcons.arrowLeft,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark ? AppColors.darkSurface : Colors.white;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final content = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldAlert,
              color: AppColors.warning,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
              fontSize: 13,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null || onAction != null) ...[
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (onRetry != null)
                  AppButton(
                    text: 'Coba Lagi',
                    leadingIcon: LucideIcons.rotateCcw,
                    variant: AppButtonVariant.outlined,
                    width: 130,
                    height: 42,
                    onPressed: onRetry,
                  ),
                if (onAction != null && actionText != null)
                  AppButton(
                    text: actionText!,
                    leadingIcon: actionIcon,
                    width: 130,
                    height: 42,
                    onPressed: onAction,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    // Tetap bisa pull-to-refresh & selalu presisi di tengah viewport.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
