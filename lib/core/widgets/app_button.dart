import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

/// Varian gaya tombol global Oasish
enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  danger,
}

/// Widget tombol standar global Oasish HRIS yang konsisten di seluruh aplikasi.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.width = double.infinity,
    this.height = 52.0,
    this.borderRadius = 100.0, // Stadium pill-shaped by default
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color defaultBg;
    Color defaultFg;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        defaultBg = backgroundColor ?? AppColors.brandTeal;
        defaultFg = foregroundColor ?? AppColors.onPrimary;
        break;
      case AppButtonVariant.secondary:
        defaultBg = backgroundColor ?? (isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer);
        defaultFg = foregroundColor ?? (isDark ? AppColors.inversePrimary : AppColors.onPrimaryContainer);
        break;
      case AppButtonVariant.outlined:
        defaultBg = backgroundColor ?? Colors.transparent;
        defaultFg = foregroundColor ?? (isDark ? AppColors.inversePrimary : AppColors.brandTeal);
        borderSide = BorderSide(
          color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
          width: 1.5,
        );
        break;
      case AppButtonVariant.ghost:
        defaultBg = backgroundColor ?? Colors.transparent;
        defaultFg = foregroundColor ?? (isDark ? AppColors.darkOnSurface : AppColors.onSurface);
        break;
      case AppButtonVariant.danger:
        defaultBg = backgroundColor ?? AppColors.errorRed;
        defaultFg = foregroundColor ?? AppColors.onError;
        break;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: borderSide ?? BorderSide.none,
    );

    final resolvedTextStyle = textStyle ??
        AppTypography.labelMedium.copyWith(
          color: defaultFg,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        );

    final buttonChild = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(defaultFg),
            ),
          )
        : Row(
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: defaultFg),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: resolvedTextStyle,
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 18, color: defaultFg),
              ],
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultBg,
          foregroundColor: defaultFg,
          disabledBackgroundColor: defaultBg.withValues(alpha: 0.6),
          disabledForegroundColor: defaultFg.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
    );
  }
}
