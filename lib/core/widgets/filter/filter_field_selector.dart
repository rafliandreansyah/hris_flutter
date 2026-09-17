import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Reusable form selector card component for filter bottom sheets.
/// Conforms to Stitch M3 "Teal Oasis" design tokens.
class FilterFieldSelector extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isEnabled;
  final String? helperText;
  final VoidCallback? onClear;

  const FilterFieldSelector({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
    this.helperText,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final effectiveFieldBg =
        isEnabled ? fieldBg : fieldBg.withValues(alpha: 0.4);
    final effectiveBorderCol =
        isEnabled ? borderCol : borderCol.withValues(alpha: 0.4);
    final effectiveTextCol =
        isEnabled ? textCol : labelCol.withValues(alpha: 0.5);
    final effectiveIconCol =
        isEnabled ? brandColor : labelCol.withValues(alpha: 0.4);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: effectiveTextCol,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: isEnabled && !isLoading ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: effectiveFieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: effectiveBorderCol, width: 1),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: effectiveIconCol),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.bodyMedium.copyWith(
                        color: effectiveTextCol,
                        fontWeight:
                            isEnabled ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: brandColor,
                      ),
                    ),
                  ] else if (!isEnabled) ...[
                    Icon(
                      LucideIcons.lock,
                      size: 16,
                      color: labelCol.withValues(alpha: 0.45),
                    ),
                  ] else if (onClear != null) ...[
                    GestureDetector(
                      onTap: onClear,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(LucideIcons.x, size: 16, color: labelCol),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronDown, size: 16, color: labelCol),
                  ],
                ],
              ),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (!isEnabled) ...[
                  Icon(
                    LucideIcons.info,
                    size: 12,
                    color: labelCol.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    helperText!,
                    style: AppTypography.labelSmall.copyWith(
                      color: labelCol.withValues(alpha: isEnabled ? 1.0 : 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
