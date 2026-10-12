import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/app_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';

/// Handler terpusat untuk memproses dan menavigasikan aksi klik notifikasi
/// (baik dari Push Notification FCM di background/terminated maupun dari Inbox Notifikasi In-App).
class NotificationNavigationHandler {
  static final NotificationNavigationHandler _instance =
      NotificationNavigationHandler._internal();
  static NotificationNavigationHandler get instance => _instance;
  factory NotificationNavigationHandler() => _instance;

  NotificationNavigationHandler._internal();

  /// Menyimpan payload saat aplikasi dibuka dari kondisi Terminated (Cold Start)
  /// agar dieksekusi setelah navigasi Splash & autentikasi Dashboard selesai.
  Map<String, dynamic>? _pendingPayload;

  Map<String, dynamic>? get pendingPayload => _pendingPayload;

  /// Simpan payload cold-start ke antrian pending
  void setPendingPayload(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) return;
    _pendingPayload = Map<String, dynamic>.from(payload);
    debugPrint('📦 [NotificationNavigationHandler] Cold start pending payload saved: $_pendingPayload');
  }

  /// Bersihkan payload pending
  void clearPendingPayload() {
    _pendingPayload = null;
  }

  /// Handler saat Push Notification FCM diklik dari tray OS / notification response
  void handleMessage(RemoteMessage message) {
    debugPrint('🔔 [NotificationNavigationHandler] Handling RemoteMessage: ${message.data}');
    final data = message.data;
    if (data.isEmpty) return;

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null) {
      final handled = handlePayload(context, data);
      if (!handled) {
        setPendingPayload(data);
      }
    } else {
      setPendingPayload(data);
    }
  }

  /// Eksekusi payload pending begitu Dashboard selesai mounting
  bool consumePendingPayload([BuildContext? targetContext]) {
    final payload = _pendingPayload;
    if (payload == null || payload.isEmpty) return false;

    final ctx = targetContext ?? AppRouter.rootNavigatorKey.currentContext;
    if (ctx == null) return false;

    debugPrint('🚀 [NotificationNavigationHandler] Consuming pending payload: $payload');
    final handled = handlePayload(ctx, payload);
    if (handled) {
      clearPendingPayload();
    }
    return handled;
  }

  /// Handler saat item diketuk di layar Pusat Notifikasi (In-App Inbox)
  bool handleNotificationItem(BuildContext context, NotificationItemModel item) {
    final Map<String, dynamic> combinedData = {};

    // 1. Masukkan data JSON bawaan dari backend jika tersedia
    if (item.data != null && item.data!.isNotEmpty) {
      combinedData.addAll(item.data!);
    }

    // 2. Jika tipe belum tercantum di data JSON, gunakan item.type dari DB
    if (!combinedData.containsKey('type') || (combinedData['type'] == null || combinedData['type'].toString().isEmpty)) {
      combinedData['type'] = item.type;
    }

    // 3. Jika belum ada ID di data, gunakan item.id sebagai fallback jika relevan
    if (!combinedData.containsKey('id') && combinedData['type'] != 'general') {
      combinedData['id'] = item.id;
    }

    return handlePayload(context, combinedData);
  }

  /// Router utama yang mem-parsing struktur payload dari `muratech_hris_server` dan `hris-web`
  /// dan mengarahkan ke GoRouter routes yang sesuai.
  bool handlePayload(BuildContext context, Map<String, dynamic> rawData) {
    try {
      final String type = (rawData['type']?.toString() ?? '').toLowerCase().trim();
      final String module = (rawData['module']?.toString() ?? '').toLowerCase().trim();
      final String actionUrl = (rawData['actionUrl']?.toString() ?? '').trim();

      // Ekstraksi ID secara defensif dari berbagai kemungkinan format key backend & web
      final String id = (rawData['id'] ??
              rawData['entityId'] ??
              rawData['leaveRequestId'] ??
              rawData['attendanceRequestId'] ??
              rawData['overtimeId'] ??
              rawData['reimbursementId'] ??
              rawData['resignationId'] ??
              rawData['assetId'] ??
              rawData['assignmentId'] ??
              '')
          .toString()
          .trim();

      // Deteksi apakah notifikasi ini ditujukan untuk Approver (atasan) atau Pemohon (karyawan)
      final bool isApprover = _resolveIsApprover(type, rawData);

      debugPrint('🧭 [NotificationNavigationHandler] Parsing route -> type: "$type", module: "$module", id: "$id", isApprover: $isApprover, actionUrl: "$actionUrl"');

      // 1. Cek Cuti & Izin (Leave)
      if (type.contains('leave') || module == 'leave' || actionUrl.contains('/approval/leaves')) {
        final resolvedId = id.isNotEmpty ? id : _extractIdFromUrl(actionUrl);
        if (resolvedId.isNotEmpty) {
          context.push(
            Routes.LEAVE_DETAIL,
            extra: {'id': resolvedId, 'isApprover': isApprover},
          );
        } else {
          context.push(Routes.LEAVE);
        }
        return true;
      }

      // 2. Cek Lembur (Overtime)
      if (type.contains('overtime') || module == 'overtime' || actionUrl.contains('/approval/overtimes')) {
        final resolvedId = id.isNotEmpty ? id : _extractIdFromUrl(actionUrl);
        if (resolvedId.isNotEmpty) {
          context.push(
            Routes.OVERTIME_DETAIL,
            extra: {'id': resolvedId, 'isApprover': isApprover},
          );
        } else {
          context.push(Routes.OVERTIME);
        }
        return true;
      }

      // 3. Cek Presensi & Absen Luar Kantor (Attendance)
      if (type.contains('attendance') || module == 'attendance' || actionUrl.contains('/approval/attendances')) {
        final resolvedId = id.isNotEmpty ? id : _extractIdFromUrl(actionUrl);
        if (resolvedId.isNotEmpty) {
          context.push(
            Routes.ATTENDANCE_REQUEST_DETAIL,
            extra: {'id': resolvedId, 'isApprover': isApprover},
          );
        } else {
          context.push(Routes.ATTENDANCE_REQUESTS);
        }
        return true;
      }

      // 4. Cek Aktivitas Lapangan (Activity)
      if (type.contains('activity') || module == 'activity' || actionUrl.contains('/report-aktivities')) {
        if (id.isNotEmpty) {
          context.push(Routes.ACTIVITY_DETAIL, extra: id);
        } else {
          context.push(Routes.ACTIVITY);
        }
        return true;
      }

      // 5. Cek Surat Peringatan (Warning Letter)
      if (type.contains('warning_letter') || module == 'warning_letter' || type.contains('warningletter')) {
        if (id.isNotEmpty) {
          context.push(Routes.WARNING_LETTER_DETAIL, extra: id);
        } else {
          context.push(Routes.WARNING_LETTER);
        }
        return true;
      }

      // 6. Cek Reimbursement & Klaim Biaya
      if (type.contains('reimbursement') || module == 'reimbursement' || actionUrl.contains('/approval/reimbursements')) {
        final resolvedId = id.isNotEmpty ? id : _extractIdFromUrl(actionUrl);
        if (resolvedId.isNotEmpty) {
          context.push(Routes.REIMBURSEMENT_DETAIL, extra: resolvedId);
        } else {
          context.push(Routes.EXPENSES);
        }
        return true;
      }

      // 7. Cek Kasbon (Cash Advance)
      if (type.contains('cash_advance') || module == 'cash_advance' || type.contains('cashadvance')) {
        if (id.isNotEmpty) {
          context.push(Routes.CASH_ADVANCE_DETAIL, extra: id);
        } else {
          context.push(Routes.EXPENSES);
        }
        return true;
      }

      // 8. Cek Pengumuman Perusahaan (Announcement)
      if (type.contains('announcement') || module == 'announcement') {
        if (id.isNotEmpty) {
          context.push(Routes.ANNOUNCEMENT_DETAIL, extra: id);
        } else {
          context.push(Routes.ANNOUNCEMENT);
        }
        return true;
      }

      // 9. Cek Fasilitas Kerja & Aset (Asset)
      if (type.contains('asset') || module == 'asset') {
        context.push(Routes.ASSETS);
        return true;
      }

      // 10. Cek Pengunduran Diri (Resignation)
      if (type.contains('resignation') || module == 'resignation' || actionUrl.contains('/approval/resignation')) {
        context.push(Routes.RESIGNATION);
        return true;
      }

      // 11. Cek Penggajian (Payroll)
      if (type.contains('payroll') || module == 'payroll') {
        if (id.isNotEmpty) {
          context.push(Routes.PAYROLL_DETAIL, extra: id);
        } else {
          context.push(Routes.PAYROLL);
        }
        return true;
      }

      // 12. Cek Pemetaan actionUrl Khusus dari Web (Correction / Report URLs)
      if (actionUrl.isNotEmpty) {
        if (actionUrl.contains('/report-kehadiran')) {
          context.push(Routes.ATTENDANCE_LOGS);
          return true;
        }
        if (actionUrl.contains('/report-izin')) {
          context.push(Routes.LEAVE);
          return true;
        }
        if (actionUrl.contains('/report-lembur')) {
          context.push(Routes.OVERTIME);
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ [NotificationNavigationHandler] Gagal menavigasikan payload notifikasi: $e');
      return false;
    }
  }

  /// Ekstraksi peran Approver berdasarkan penamaan event backend / web
  bool _resolveIsApprover(String type, Map<String, dynamic> rawData) {
    if (rawData.containsKey('isApprover')) {
      final val = rawData['isApprover'];
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true';
    }

    // Tipe event dari Web untuk Approver
    if (type.endsWith('_new_submission') || type.contains('new_submission')) {
      return true;
    }

    // Tipe event konfirmasi pengajuan / keputusan untuk Pemohon
    if (type.endsWith('_submission_confirmation') ||
        type.contains('submission_confirmation') ||
        type.endsWith('_approval') ||
        type.contains('_decision')) {
      return false;
    }

    // Default false untuk self
    return false;
  }

  /// Ekstraksi UUID / ID dari URL web (contoh: `/approval/leaves/123e4567-e89b...`)
  String _extractIdFromUrl(String url) {
    if (url.isEmpty) return '';
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length >= 3) {
      return segments.last;
    }
    return '';
  }
}
