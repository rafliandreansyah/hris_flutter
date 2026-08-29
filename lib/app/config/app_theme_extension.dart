import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ThemeExtension untuk mendistribusikan token warna kustom
/// yang tidak terakomodasi secara default di Material 3 ColorScheme.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.brandTeal,
    required this.outlineMuted,
    required this.backgroundSubtle,
    required this.accentTealLight,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.textMuted,
  });

  final Color brandTeal;
  final Color outlineMuted;
  final Color backgroundSubtle;
  final Color accentTealLight;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color textMuted;

  /// Nilai default untuk Light Theme
  static const AppCustomColors light = AppCustomColors(
    brandTeal: AppColors.brandTeal,
    outlineMuted: AppColors.outlineMuted,
    backgroundSubtle: AppColors.backgroundSubtle,
    accentTealLight: AppColors.accentTealLight,
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    textMuted: AppColors.textMuted,
  );

  /// Nilai default untuk Dark Theme
  static const AppCustomColors dark = AppCustomColors(
    brandTeal: AppColors.brandTealSecondary,
    outlineMuted: AppColors.darkOutlineMuted,
    backgroundSubtle: AppColors.darkBackgroundSubtle,
    accentTealLight: AppColors.darkPrimaryContainer,
    success: AppColors.success,
    successContainer: AppColors.onSuccessContainer,
    onSuccessContainer: AppColors.successContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.onWarningContainer,
    onWarningContainer: AppColors.warningContainer,
    textMuted: AppColors.darkOnSurfaceVariant,
  );

  @override
  AppCustomColors copyWith({
    Color? brandTeal,
    Color? outlineMuted,
    Color? backgroundSubtle,
    Color? accentTealLight,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? textMuted,
  }) {
    return AppCustomColors(
      brandTeal: brandTeal ?? this.brandTeal,
      outlineMuted: outlineMuted ?? this.outlineMuted,
      backgroundSubtle: backgroundSubtle ?? this.backgroundSubtle,
      accentTealLight: accentTealLight ?? this.accentTealLight,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) {
      return this;
    }
    return AppCustomColors(
      brandTeal: Color.lerp(brandTeal, other.brandTeal, t) ?? brandTeal,
      outlineMuted:
          Color.lerp(outlineMuted, other.outlineMuted, t) ?? outlineMuted,
      backgroundSubtle:
          Color.lerp(backgroundSubtle, other.backgroundSubtle, t) ??
          backgroundSubtle,
      accentTealLight:
          Color.lerp(accentTealLight, other.accentTealLight, t) ??
          accentTealLight,
      success: Color.lerp(success, other.success, t) ?? success,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t) ??
          onSuccessContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t) ??
          onWarningContainer,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}

/// Extension helper pada BuildContext untuk memudahkan akses warna kustom
extension AppCustomColorsContextExtension on BuildContext {
  AppCustomColors get customColors =>
      Theme.of(this).extension<AppCustomColors>() ?? AppCustomColors.light;
}
