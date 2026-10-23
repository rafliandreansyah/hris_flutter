import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';

/// Modul pengajuan yang bisa dibagikan ke atasan.
/// [apiKey] dikirim ke `GET /approvers?module=`, [webPath] = path halaman approval di hris-web.
enum ShareModule {
  leave('leave', 'approval/leaves', 'Cuti'),
  overtime('overtime', 'approval/overtimes', 'Lembur'),
  attendance('attendance', 'approval/attendances', 'Presensi'),
  reimbursement('reimbursement', 'approval/reimbursements', 'Reimbursement'),
  // Di web, path ini diarahkan ke drawer detail kasbon di /reimbursement.
  cashAdvance('cash_advance', 'approval/cash-advances', 'Kasbon'),
  resignation('resignation', 'approval/resignation', 'Pengunduran Diri'),
  activity('activity', 'report/activities', 'Aktivitas'),
  employee('employee', 'employee', 'Profil Karyawan');

  final String apiKey;
  final String webPath;
  final String label;

  const ShareModule(this.apiKey, this.webPath, this.label);
}

/// Argumen halaman daftar atasan ([Routes.APPROVER_SHARE]).
class ApproverShareArgs {
  final ShareModule module;
  final String requestId;

  /// Ringkasan pengajuan (teks yang sebelumnya dibagikan lewat SharePlus).
  final String summary;
  final String subject;

  const ApproverShareArgs({
    required this.module,
    required this.requestId,
    required this.summary,
    required this.subject,
  });

  String get url => ShareLinkUtil.webUrl(module, requestId);

  String get message => '$summary\nLihat & proses pengajuan:\n$url';
}

/// Link share pengajuan: URL web (App Links / Universal Links) + pemetaannya ke route aplikasi.
abstract class ShareLinkUtil {
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String webUrl(ShareModule module, String id) =>
      '${ApiEndpoints.webBaseUrl}/${module.webPath}/${Uri.encodeComponent(id)}';

  /// Memetakan URL web pengajuan ke lokasi GoRouter. Null jika bukan link pengajuan.
  static String? toAppLocation(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;

    final base = segments.sublist(0, segments.length - 1).join('/');
    // Halaman admin web lain di bawah /employee/ (mis. /employee/create) bukan profil karyawan.
    if (base == 'employee' || base == 'employees') {
      if (!_uuidPattern.hasMatch(segments.last)) return null;
      return '${Routes.EMPLOYEE_DETAIL}?id=${Uri.encodeQueryComponent(segments.last)}';
    }

    final module =
        ShareModule.values.where((m) => m.webPath == base).firstOrNull;
    if (module == null) return null;

    final query = 'id=${Uri.encodeQueryComponent(segments.last)}';
    switch (module) {
      case ShareModule.leave:
        return '${Routes.LEAVE_DETAIL}?$query&isApprover=true';
      case ShareModule.overtime:
        return '${Routes.OVERTIME_DETAIL}?$query&isApprover=true';
      case ShareModule.attendance:
        return '${Routes.ATTENDANCE_REQUEST_DETAIL}?$query&isApprover=true';
      case ShareModule.reimbursement:
        return '${Routes.REIMBURSEMENT_DETAIL}?$query';
      case ShareModule.cashAdvance:
        return '${Routes.CASH_ADVANCE_DETAIL}?$query';
      case ShareModule.activity:
        return '${Routes.ACTIVITY_DETAIL}?$query';
      case ShareModule.resignation:
        // Approval resign ada di tab "Persetujuan Tim" halaman resign (tidak ada halaman detail).
        return Routes.RESIGNATION;
      case ShareModule.employee:
        return '${Routes.EMPLOYEE_DETAIL}?$query';
    }
  }

  /// Link pengajuan yang tertunda di query `from` (diisi redirect router saat splash / belum login).
  /// Hanya link pengajuan yang dikenali yang dikembalikan, supaya `from` tidak bisa membuka route lain.
  static String? pendingLink(Uri uri) {
    final from = uri.queryParameters['from'];
    if (from == null || toAppLocation(Uri.parse(from)) == null) return null;
    return from;
  }

  /// [pendingLink] dari lokasi router saat ini. Null bila tidak ada GoRouter (mis. widget test).
  static String? pendingLinkOf(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    return router == null ? null : pendingLink(router.state.uri);
  }

  /// Nomor HP pegawai → format internasional wa.me (`0812…` / `+62812…` → `62812…`).
  static String normalizeWhatsAppPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return '62${digits.substring(1)}';
    if (digits.startsWith('8')) return '62$digits';
    return digits;
  }

  static Uri whatsAppUri(String phone, String message) => Uri.https(
        'wa.me',
        '/${normalizeWhatsAppPhone(phone)}',
        {'text': message},
      );

  /// URI universal untuk share ke WhatsApp (membuka WhatsApp dengan pesan terisi, memilih kontak tujuan).
  static Uri whatsAppShareUri(String message) => Uri.https(
        'api.whatsapp.com',
        '/send',
        {'text': message},
      );

  // Query ditulis manual: Uri(queryParameters:) mengubah spasi jadi '+', yang tampil apa adanya di aplikasi email.
  static Uri emailUri(String email, {required String subject, required String body}) =>
      Uri.parse(
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

  /// Email share URI tanpa penerima khusus (pengguna memilih penerima sendiri di aplikasi email).
  static Uri emailShareUri({required String subject, required String body}) =>
      Uri.parse(
        'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

  /// Buka halaman daftar atasan yang bisa approve pengajuan ini.
  static void openApproverShare(BuildContext context, ApproverShareArgs args) {
    context.push(Routes.APPROVER_SHARE, extra: args);
  }

  static Future<void> copyLink(
    BuildContext context,
    String url, {
    String title = 'Link Disalin',
    String message =
        'Link pengajuan sudah disalin. Tempel di aplikasi mana pun untuk membagikannya.',
  }) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    AppDialogUtil.showSuccess(
      context,
      title: title,
      message: message,
    );
  }
}
