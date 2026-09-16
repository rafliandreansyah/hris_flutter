import 'package:flutter/material.dart';
import 'package:pro_dialog/pro_dialog.dart';

import '../../app/config/app_colors.dart';
import '../../app/config/app_design.dart';
import '../../app/config/app_typography.dart';

/// Utilitas penampil dialog aplikasi menggunakan package `pro_dialog`.
class AppDialogUtil {
  const AppDialogUtil._();

  /// Helper untuk membuat [DialogButton] dengan [customWidget] yang tahan overflow.
  ///
  /// Menggunakan `Flexible` + `FittedBox(fit: BoxFit.scaleDown)` dan padding yang rapat
  /// agar tombol tidak pernah memicu `RenderFlex overflowed by X pixels` pada layar kecil
  /// ataupun label teks yang panjang.
  static DialogButton _createSafeDialogButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = false,
    DialogButtonStyle style = DialogButtonStyle.filled,
    Color? color,
    IconData? icon,
    bool isLoading = false,
    String? semanticLabel,
  }) {
    final effectiveColor =
        color ?? (isPrimary ? AppColors.errorRed : AppColors.brandTeal);
    final isOutlined = style == DialogButtonStyle.outlined;
    final isTextOnly = style == DialogButtonStyle.text;

    final Color bgColor;
    final Color fgColor;
    final Border? border;

    if (isTextOnly) {
      bgColor = Colors.transparent;
      fgColor = effectiveColor;
      border = null;
    } else if (isOutlined) {
      bgColor = Colors.transparent;
      fgColor = effectiveColor;
      border = Border.all(
        color: effectiveColor.withValues(alpha: 0.55),
        width: 1.5,
      );
    } else if (isPrimary) {
      bgColor = effectiveColor;
      fgColor = AppColors.onPrimary;
      border = null;
    } else {
      bgColor = const Color(0xFFF1F5F9);
      fgColor = const Color(0xFF64748B);
      border = null;
    }

    final customWidget = Material(
      color: bgColor,
      borderRadius: AppRadius.borderInput,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppRadius.borderInput,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderInput,
            border: border,
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fgColor),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            color: fgColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return DialogButton(
      text: text,
      onPressed: onPressed,
      isPrimary: isPrimary,
      style: style,
      color: effectiveColor,
      icon: icon,
      isLoading: isLoading,
      semanticLabel: semanticLabel,
      customWidget: customWidget,
    );
  }

  /// Menampilkan dialog error terstandarisasi dengan animasi dan opsi Retry/Tutup.
  static Future<T?> showError<T>(
    BuildContext context, {
    String title = 'Terjadi Kesalahan',
    required String message,
    String retryText = 'Coba Lagi',
    VoidCallback? onRetry,
    String closeText = 'Tutup',
    VoidCallback? onClose,
    Axis? buttonsAxis,
    ProDialogTheme? theme,
  }) {
    final effectiveButtonsAxis = buttonsAxis ??
        (onRetry != null &&
                (retryText.length > 12 ||
                    closeText.length > 12 ||
                    (retryText.length + closeText.length) > 18)
            ? Axis.vertical
            : Axis.horizontal);

    return showProDialog<T>(
      context,
      type: DialogType.error,
      title: title,
      description: message,
      buttonsAxis: effectiveButtonsAxis,
      theme: theme,
      buttons: [
        if (onRetry != null)
          _createSafeDialogButton(
            text: retryText,
            isPrimary: true,
            color: AppColors.errorRed,
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
          ),
        _createSafeDialogButton(
          text: closeText,
          isPrimary: onRetry == null,
          color: AppColors.errorRed,
          style: onRetry != null
              ? DialogButtonStyle.outlined
              : DialogButtonStyle.filled,
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
        ),
      ],
    );
  }

  /// Menampilkan dialog sukses terstandarisasi menggunakan pro_dialog.
  static Future<T?> showSuccess<T>(
    BuildContext context, {
    String title = 'Berhasil',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onOk,
    ProDialogTheme? theme,
  }) {
    return showProDialog<T>(
      context,
      type: DialogType.success,
      title: title,
      description: message,
      theme: theme,
      buttons: [
        _createSafeDialogButton(
          text: buttonText,
          isPrimary: true,
          color: AppColors.brandTeal,
          onPressed: () {
            Navigator.of(context).pop();
            onOk?.call();
          },
        ),
      ],
    );
  }

  /// Menampilkan dialog konfirmasi atau peringatan.
  static Future<T?> showWarning<T>(
    BuildContext context, {
    String title = 'Peringatan',
    required String message,
    String confirmText = 'Lanjutkan',
    VoidCallback? onConfirm,
    String cancelText = 'Batal',
    VoidCallback? onCancel,
    Axis? buttonsAxis,
    ProDialogTheme? theme,
  }) {
    final effectiveAxis = buttonsAxis ??
        ((confirmText.length > 12 ||
                cancelText.length > 12 ||
                (confirmText.length + cancelText.length) > 18)
            ? Axis.vertical
            : Axis.horizontal);

    return showProDialog<T>(
      context,
      type: DialogType.warning,
      title: title,
      description: message,
      buttonsAxis: effectiveAxis,
      theme: theme,
      buttons: [
        if (onConfirm != null || T == bool)
          _createSafeDialogButton(
            text: confirmText,
            isPrimary: true,
            color: AppColors.warning,
            onPressed: () {
              if (T == bool) {
                Navigator.of(context).pop(true as T);
              } else {
                Navigator.of(context).pop();
              }
              onConfirm?.call();
            },
          ),
        _createSafeDialogButton(
          text: cancelText,
          style: DialogButtonStyle.outlined,
          color: AppColors.warning,
          onPressed: () {
            if (T == bool) {
              Navigator.of(context).pop(false as T);
            } else {
                Navigator.of(context).pop();
            }
            onCancel?.call();
          },
        ),
      ],
    );
  }

  /// Menampilkan dialog loading dengan pro_dialog.
  static Future<T?> showLoading<T>(
    BuildContext context, {
    String title = 'Memproses...',
    String? message,
    ProDialogTheme? theme,
  }) {
    return showLoadingDialog<T>(
      context,
      title: title,
      description: message,
      theme: theme,
    );
  }
}

