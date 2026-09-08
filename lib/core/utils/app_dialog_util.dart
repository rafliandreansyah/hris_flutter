import 'package:flutter/material.dart';
import 'package:pro_dialog/pro_dialog.dart';

/// Utilitas penampil dialog aplikasi menggunakan package `pro_dialog`.
class AppDialogUtil {
  const AppDialogUtil._();

  /// Menampilkan dialog error terstandarisasi dengan animasi dan opsi Retry/Tutup.
  static Future<T?> showError<T>(
    BuildContext context, {
    String title = 'Terjadi Kesalahan',
    required String message,
    String retryText = 'Coba Lagi',
    VoidCallback? onRetry,
    String closeText = 'Tutup',
    VoidCallback? onClose,
  }) {
    return showErrorDialog<T>(
      context,
      title: title,
      description: message,
      buttons: [
        if (onRetry != null)
          DialogButton(
            text: retryText,
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
          ),
        DialogButton(
          text: closeText,
          isPrimary: onRetry == null,
          style: onRetry != null
              ? DialogButtonStyle.outlined
              : DialogButtonStyle.filled,
          onPressed: () {
            Navigator.pop(context);
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
  }) {
    return showSuccessDialog<T>(
      context,
      title: title,
      description: message,
      buttons: [
        DialogButton(
          text: buttonText,
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
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
  }) {
    return showWarningDialog<T>(
      context,
      title: title,
      description: message,
      buttons: [
        if (onConfirm != null)
          DialogButton(
            text: confirmText,
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        DialogButton(
          text: cancelText,
          style: DialogButtonStyle.outlined,
          onPressed: () {
            Navigator.pop(context);
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
  }) {
    return showLoadingDialog<T>(
      context,
      title: title,
      description: message,
    );
  }
}
