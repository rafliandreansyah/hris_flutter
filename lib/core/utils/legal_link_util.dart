import 'package:flutter/material.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka dokumen legal (Kebijakan Privasi, S&K, Hapus Data, dll.) di browser dalam aplikasi.
class LegalLinkUtil {
  const LegalLinkUtil._();

  static Future<void> open(BuildContext context, String url) async {
    bool opened;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      final l10n = AppLocalizations.of(context);
      AppDialogUtil.showError(
        context,
        message: l10n?.legalLinkOpenFailed ??
            'Halaman tidak dapat dibuka. Periksa koneksi internet Anda lalu coba lagi.',
      );
    }
  }
}
