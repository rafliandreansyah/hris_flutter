import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

/// Enum tipe perizinan yang sering digunakan di modul-modul HRIS Oasish
enum HrisPermissionType {
  camera,
  gallery,
  documentStorage,
  location,
  backgroundLocation,
  notification,
  exactAlarm,
  microphone,
}

/// Hasil evaluasi perizinan yang mudah digunakan oleh UI / ViewModel
class HrisPermissionResult {
  final bool isGranted;
  final bool isPermanentlyDenied;
  final bool isDenied;
  final bool isRestricted;
  final String message;

  const HrisPermissionResult({
    required this.isGranted,
    this.isPermanentlyDenied = false,
    this.isDenied = false,
    this.isRestricted = false,
    this.message = '',
  });

  factory HrisPermissionResult.fromStatus(PermissionStatus status, {String message = ''}) {
    return HrisPermissionResult(
      isGranted: status.isGranted || status.isLimited,
      isPermanentlyDenied: status.isPermanentlyDenied,
      isDenied: status.isDenied,
      isRestricted: status.isRestricted,
      message: message,
    );
  }

  factory HrisPermissionResult.granted([String message = 'Izin diberikan.']) {
    return HrisPermissionResult(
      isGranted: true,
      message: message,
    );
  }

  factory HrisPermissionResult.denied([String message = 'Izin ditolak.']) {
    return HrisPermissionResult(
      isGranted: false,
      isDenied: true,
      message: message,
    );
  }
}

/// Utility terpusat untuk mengelola seluruh izin (Permissions) aplikasi HRIS Oasish.
///
/// Mendukung izin:
/// - [Camera]: Untuk selfie clock-in, foto profil, dan bukti aktivitas lapangan.
/// - [Gallery/Photos]: Untuk upload bukti nota reimburse, dokumen izin sakit, & foto kegiatan.
/// - [Document/Storage]: Untuk mengunduh & membuka Slip Gaji (PDF), form SPT pajak, & surat tugas.
/// - [Location/Maps]: Untuk validasi radius geofencing presensi dan pelacakan aktivitas lapangan.
/// - [Notification]: Untuk pengingat shift kerja, notifikasi approval atasan, & pengumuman HR.
/// - [ExactAlarm]: Untuk pengingat tepat waktu jam masuk/pulang kerja (Shift Alarm).
/// - [Microphone]: Untuk rekam catatan suara pada investigasi/inspeksi lapangan.
class PermissionUtil {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Menandakan apakah berjalan dalam lingkungan unit test / flutter_test
  static bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // 1. KAMERA (Camera)
  // ===========================================================================

  /// Periksa status izin kamera
  static Future<bool> hasCameraPermission() async {
    if (_isTestEnvironment) return true;
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.hasCameraPermission] $e');
      return false;
    }
  }

  /// Meminta izin kamera
  static Future<HrisPermissionResult> requestCameraPermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final status = await Permission.camera.request();
      final result = HrisPermissionResult.fromStatus(
        status,
        message: status.isGranted
            ? 'Akses kamera diberikan.'
            : 'Akses kamera dibutuhkan untuk verifikasi kehadiran dan bukti aktivitas.',
      );

      if (result.isPermanentlyDenied && context != null && context.mounted) {
        showPermissionDeniedDialog(
          context: context,
          type: HrisPermissionType.camera,
          title: 'Izin Kamera Diperlukan',
          description:
              'Aplikasi membutuhkan izin kamera untuk mengambil foto bukti aktivitas lapangan atau selfie kehadiran. Silakan aktifkan melalui Pengaturan aplikasi.',
        );
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestCameraPermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  // ===========================================================================
  // 2. GALERI & FOTO (Gallery / Photos)
  // ===========================================================================

  /// Periksa status izin akses galeri foto
  static Future<bool> hasGalleryPermission() async {
    if (_isTestEnvironment) return true;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.photos.status;
          return status.isGranted || status.isLimited;
        } else {
          final status = await Permission.storage.status;
          return status.isGranted;
        }
      } else {
        final status = await Permission.photos.status;
        return status.isGranted || status.isLimited;
      }
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.hasGalleryPermission] $e');
      return false;
    }
  }

  /// Meminta izin galeri foto (menyesuaikan Android 13+ vs Android lama vs iOS)
  static Future<HrisPermissionResult> requestGalleryPermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.photos.request();
      }

      final result = HrisPermissionResult.fromStatus(
        status,
        message: status.isGranted || status.isLimited
            ? 'Akses galeri foto diberikan.'
            : 'Akses galeri dibutuhkan untuk memilih foto bukti atau dokumen klaim.',
      );

      if (result.isPermanentlyDenied && context != null && context.mounted) {
        showPermissionDeniedDialog(
          context: context,
          type: HrisPermissionType.gallery,
          title: 'Izin Galeri Foto Diperlukan',
          description:
              'Aplikasi membutuhkan izin akses foto untuk melampirkan bukti pengeluaran reimburse atau dokumen pendukung. Silakan aktifkan di Pengaturan.',
        );
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestGalleryPermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  // ===========================================================================
  // 3. PENYIMPANAN & DOKUMEN (Document / File Storage)
  // ===========================================================================

  /// Periksa izin penyimpanan dokumen (Slip Gaji, Bukti Potong Pajak, SOP)
  static Future<bool> hasDocumentStoragePermission() async {
    if (_isTestEnvironment) return true;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Android 13+ menggunakan Scoped Storage untuk file umum
        if (androidInfo.version.sdkInt >= 33) {
          return true;
        }
        final status = await Permission.storage.status;
        return status.isGranted;
      }
      return true; // iOS tidak memerlukan izin storage global
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.hasDocumentStoragePermission] $e');
      return false;
    }
  }

  /// Meminta izin penyimpanan dokumen
  static Future<HrisPermissionResult> requestDocumentStoragePermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          return HrisPermissionResult.granted('Menggunakan Scoped Storage.');
        }
        final status = await Permission.storage.request();
        final result = HrisPermissionResult.fromStatus(status);

        if (result.isPermanentlyDenied && context != null && context.mounted) {
          showPermissionDeniedDialog(
            context: context,
            type: HrisPermissionType.documentStorage,
            title: 'Izin Penyimpanan Diperlukan',
            description:
                'Izin penyimpanan diperlukan untuk mengunduh slip gaji dan dokumen ke memori perangkat.',
          );
        }
        return result;
      }
      return HrisPermissionResult.granted();
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestDocumentStoragePermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  // ===========================================================================
  // 4. LOKASI & PETA (Location / Maps)
  // ===========================================================================

  /// Periksa apakah izin lokasi sudah diberikan
  static Future<bool> hasLocationPermission() async {
    if (_isTestEnvironment) return true;
    try {
      final status = await Permission.locationWhenInUse.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.hasLocationPermission] $e');
      return false;
    }
  }

  /// Meminta izin lokasi saat aplikasi digunakan (WhenInUse)
  static Future<HrisPermissionResult> requestLocationPermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      var status = await Permission.locationWhenInUse.request();
      final result = HrisPermissionResult.fromStatus(
        status,
        message: status.isGranted
            ? 'Izin lokasi diberikan.'
            : 'Izin lokasi dibutuhkan untuk verifikasi radius kantor & peta aktivitas.',
      );

      if (result.isPermanentlyDenied && context != null && context.mounted) {
        showPermissionDeniedDialog(
          context: context,
          type: HrisPermissionType.location,
          title: 'Izin Lokasi GPS Diperlukan',
          description:
              'Aplikasi HRIS Oasish membutuhkan akses lokasi GPS untuk memvalidasi posisi presensi dan rute aktivitas lapangan Anda. Aktifkan lokasi di Pengaturan.',
        );
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestLocationPermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  /// Meminta izin lokasi latar belakang (Background Location) - khusus field sales / duty tracking
  static Future<HrisPermissionResult> requestBackgroundLocationPermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      // Wajib request WhenInUse terlebih dahulu sebelum Always
      final inUseStatus = await Permission.locationWhenInUse.status;
      if (!inUseStatus.isGranted) {
        final initial = await Permission.locationWhenInUse.request();
        if (!initial.isGranted) {
          return HrisPermissionResult.fromStatus(initial);
        }
      }

      final alwaysStatus = await Permission.locationAlways.request();
      final result = HrisPermissionResult.fromStatus(alwaysStatus);

      if (result.isPermanentlyDenied && context != null && context.mounted) {
        showPermissionDeniedDialog(
          context: context,
          type: HrisPermissionType.backgroundLocation,
          title: 'Izin Lokasi Latar Belakang Diperlukan',
          description:
              'Untuk pelacakan rute dinas luar kota / sales tracking otomatis, pilih "Izinkan Sepanjang Waktu" pada Pengaturan Lokasi.',
        );
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestBackgroundLocationPermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  // ===========================================================================
  // 5. NOTIFIKASI PUSH & SISTEM (Notification)
  // ===========================================================================

  /// Periksa status izin notifikasi
  static Future<bool> hasNotificationPermission() async {
    if (_isTestEnvironment) return true;
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.hasNotificationPermission] $e');
      return false;
    }
  }

  /// Meminta izin notifikasi (Android 13+ & iOS)
  static Future<HrisPermissionResult> requestNotificationPermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final status = await Permission.notification.request();
      final result = HrisPermissionResult.fromStatus(
        status,
        message: status.isGranted
            ? 'Izin notifikasi aktif.'
            : 'Aktifkan notifikasi agar tidak ketinggalan pengingat absen & persetujuan cuti.',
      );

      if (result.isPermanentlyDenied && context != null && context.mounted) {
        showPermissionDeniedDialog(
          context: context,
          type: HrisPermissionType.notification,
          title: 'Izin Notifikasi Dimatikan',
          description:
              'Notifikasi penting seperti pengingat jam masuk, pengumuman perusahaan, dan status approval cuti tidak dapat diterima. Silakan izinkan di Pengaturan.',
        );
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestNotificationPermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  // ===========================================================================
  // 6. TAMBAHAN HRIS: PENGINGAT TEPAT WAKTU (Schedule Exact Alarm)
  // ===========================================================================

  /// Izin Alarm Tepat Waktu untuk pengingat shift kerja dan jadwal check-in
  static Future<HrisPermissionResult> requestExactAlarmPermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Hanya relevan untuk Android 12+ (API 31+)
        if (androidInfo.version.sdkInt >= 31) {
          final status = await Permission.scheduleExactAlarm.request();
          return HrisPermissionResult.fromStatus(status);
        }
      }
      return HrisPermissionResult.granted();
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestExactAlarmPermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  // ===========================================================================
  // 7. TAMBAHAN HRIS: MIKROFON (Microphone)
  // ===========================================================================

  /// Meminta izin mikrofon untuk catatan suara inspeksi atau meeting minutes
  static Future<HrisPermissionResult> requestMicrophonePermission({
    BuildContext? context,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final status = await Permission.microphone.request();
      final result = HrisPermissionResult.fromStatus(status);

      if (result.isPermanentlyDenied && context != null && context.mounted) {
        showPermissionDeniedDialog(
          context: context,
          type: HrisPermissionType.microphone,
          title: 'Izin Mikrofon Diperlukan',
          description:
              'Aplikasi membutuhkan mikrofon untuk merekam voice memo pada laporan aktivitas lapangan Anda.',
        );
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.requestMicrophonePermission] $e');
      return HrisPermissionResult.denied(e.toString());
    }
  }

  // ===========================================================================
  // 8. KOMBINASI KHUSUS HRIS (Workflow-based Compound Permissions)
  // ===========================================================================

  /// Meminta izin lengkap untuk alur Presensi Kehadiran (Lokasi + Kamera)
  static Future<bool> requestAttendancePermissions({
    required BuildContext context,
  }) async {
    final locationResult = await requestLocationPermission(context: context);
    if (!locationResult.isGranted) return false;

    if (!context.mounted) return false;
    final cameraResult = await requestCameraPermission(context: context);
    return cameraResult.isGranted;
  }

  /// Meminta izin lengkap untuk alur Catat Aktivitas Lapangan (Lokasi + Kamera + Galeri)
  static Future<bool> requestActivityProofPermissions({
    required BuildContext context,
  }) async {
    final loc = await requestLocationPermission(context: context);
    if (!loc.isGranted) return false;

    if (!context.mounted) return false;
    final cam = await requestCameraPermission(context: context);
    if (!cam.isGranted) return false;

    if (!context.mounted) return false;
    final gal = await requestGalleryPermission(context: context);
    return gal.isGranted;
  }

  // ===========================================================================
  // 9. PENGATURAN & DIALOG PENDUKUNG (Settings & Dialogs)
  // ===========================================================================

  /// Membuka halaman Pengaturan Aplikasi pada sistem OS (Settings)
  static Future<bool> openSettings() async {
    if (_isTestEnvironment) return true;
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('⚠️ [PermissionUtil.openSettings] $e');
      return false;
    }
  }

  /// Dialog elegan bertema Oasish HRIS saat izin ditolak permanen
  static void showPermissionDeniedDialog({
    required BuildContext context,
    required HrisPermissionType type,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    IconData getIcon() {
      switch (type) {
        case HrisPermissionType.camera:
          return LucideIcons.camera;
        case HrisPermissionType.gallery:
          return LucideIcons.image;
        case HrisPermissionType.documentStorage:
          return LucideIcons.fileText;
        case HrisPermissionType.location:
        case HrisPermissionType.backgroundLocation:
          return LucideIcons.mapPin;
        case HrisPermissionType.notification:
          return LucideIcons.bell;
        case HrisPermissionType.exactAlarm:
          return LucideIcons.alarmClock;
        case HrisPermissionType.microphone:
          return LucideIcons.mic;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(),
                color: const Color(0xFF0D9488),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textCol,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: AppTypography.bodySmall.copyWith(
            color: subtitleCol,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Nanti Saja',
              style: TextStyle(
                color: subtitleCol,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Buka Pengaturan',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
