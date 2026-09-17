import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pro_dialog/pro_dialog.dart';

import '../../app/config/app_colors.dart';
import '../../app/config/app_design.dart';
import '../../app/config/app_typography.dart';
import '../widgets/app_button.dart';

/// Model item representasi perizinan untuk [AppDialogUtil.showPermissionDialog].
class AppPermissionItem {
  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  const AppPermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  /// Factory preset untuk izin Kamera
  factory AppPermissionItem.camera({
    String? title,
    String? description,
  }) =>
      AppPermissionItem(
        icon: LucideIcons.camera,
        title: title ?? 'Kamera',
        description: description ??
            'Untuk foto selfie presensi kehadiran dan bukti aktivitas lapangan.',
      );

  /// Factory preset untuk izin Lokasi / GPS
  factory AppPermissionItem.location({
    String? title,
    String? description,
  }) =>
      AppPermissionItem(
        icon: LucideIcons.mapPin,
        title: title ?? 'Lokasi & GPS',
        description: description ??
            'Untuk memvalidasi kehadiran berada di dalam radius kantor (geofencing).',
      );

  /// Factory preset untuk izin Galeri / Foto
  factory AppPermissionItem.gallery({
    String? title,
    String? description,
  }) =>
      AppPermissionItem(
        icon: LucideIcons.image,
        title: title ?? 'Galeri & Foto',
        description: description ??
            'Untuk mengunggah dokumen izin, bukti sakit, atau lampiran lembur.',
      );

  /// Factory preset untuk izin Notifikasi
  factory AppPermissionItem.notification({
    String? title,
    String? description,
  }) =>
      AppPermissionItem(
        icon: LucideIcons.bell,
        title: title ?? 'Notifikasi',
        description: description ??
            'Untuk menerima pengingat jam kerja, status persetujuan, dan pengumuman HR.',
      );

  /// Factory preset untuk izin Penyimpanan Dokumen
  factory AppPermissionItem.storage({
    String? title,
    String? description,
  }) =>
      AppPermissionItem(
        icon: LucideIcons.fileText,
        title: title ?? 'Penyimpanan Dokumen',
        description: description ??
            'Untuk mengunduh dan menyimpan berkas Slip Gaji dan dokumen resmi.',
      );
}

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

  /// Menampilkan dialog permohonan izin (Permission Request Dialog) yang dipercantik menggunakan `pro_dialog`.
  ///
  /// Menampilkan daftar [permissions] secara rapi dan terstruktur.
  /// Secara default, dialog ini dikunci secara persisten ([barrierDismissible: false] dan [PopScope(canPop: false)]),
  /// sehingga tidak dapat ditutup secara tidak sengaja melalui ketukan di luar ataupun gestur back,
  /// dan pengguna harus secara eksplisit menekan tombol "Izinkan" atau "Tolak".
  static Future<bool> showPermissionDialog(
    BuildContext context, {
    String title = 'Izin Akses Aplikasi',
    String description =
        'HRIS Oasish membutuhkan akses izin berikut untuk dapat menjalankan fitur ini dengan optimal:',
    required List<AppPermissionItem> permissions,
    String allowText = 'Izinkan',
    String denyText = 'Tolak',
    IconData icon = Icons.security_rounded,
    Color? iconBackgroundColor,
    Axis? buttonsAxis,
    bool barrierDismissible = false,
    bool canPop = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final cardBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

    final effectiveAxis = buttonsAxis ??
        ((denyText.length + allowText.length > 18)
            ? Axis.vertical
            : Axis.horizontal);

    final result = await showProDialog<bool>(
      context,
      type: DialogType.custom,
      title: title,
      description: description,
      icon: icon,
      iconBackgroundColor: iconBackgroundColor ?? AppColors.brandTeal,
      barrierDismissible: barrierDismissible,
      showCloseButton: false,
      buttonsAxis: effectiveAxis,
      theme: ProDialogTheme(
        backgroundColor: surfaceColor,
        borderRadius: 24.0,
        maxWidth: 400.0,
        iconSize: 32.0,
        iconBackgroundSize: 64.0,
        elevation: 8.0,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        animationStyle: DialogAnimationStyle.bounce,
        iconAnimationStyle: IconAnimationStyle.bounce,
        titleStyle: AppTypography.headlineMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: textCol,
          fontSize: 19,
          letterSpacing: -0.3,
        ),
        descriptionStyle: AppTypography.bodyMedium.copyWith(
          color: subtitleCol,
          fontSize: 13,
          height: 1.35,
        ),
        contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      ),
      customContent: PopScope(
        canPop: canPop,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: borderCol),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < permissions.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.brandTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            permissions[i].icon,
                            size: 19,
                            color: AppColors.brandTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                permissions[i].title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: textCol,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                permissions[i].description,
                                softWrap: true,
                                style: AppTypography.bodySmall.copyWith(
                                  color: subtitleCol,
                                  fontSize: 11.5,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        permissions[i].trailing ??
                            const Icon(
                              LucideIcons.circleCheck,
                              color: AppColors.success,
                              size: 20,
                            ),
                      ],
                    ),
                    if (i < permissions.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: borderCol),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      buttons: [
        DialogButton(
          text: denyText,
          style: DialogButtonStyle.outlined,
          onPressed: () => Navigator.of(context).pop(false),
          customWidget: AppButton(
            key: const ValueKey('permission_dialog_deny_button'),
            text: denyText,
            variant: AppButtonVariant.outlined,
            borderColor: borderCol,
            height: 46,
            borderRadius: 12,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        DialogButton(
          text: allowText,
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(true),
          customWidget: AppButton(
            key: const ValueKey('permission_dialog_allow_button'),
            text: allowText,
            leadingIcon: LucideIcons.check,
            variant: AppButtonVariant.primary,
            height: 46,
            borderRadius: 12,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );

    return result ?? false;
  }
}

