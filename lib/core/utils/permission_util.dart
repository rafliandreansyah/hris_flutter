import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pro_dialog/pro_dialog.dart';

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

  /// Flag untuk mengontrol apakah bypass otomatis dijalankan saat unit test.
  /// Bermanfaat saat pengujian widget yang sengaja ingin memverifikasi tampilan dialog rationale.
  @visibleForTesting
  static bool bypassInTest = true;

  /// Handler mock opsional untuk status perizinan saat testing
  @visibleForTesting
  static Future<bool> Function(Permission permission)? testPermissionStatusHandler;

  /// Handler mock opsional untuk request perizinan saat testing
  @visibleForTesting
  static Future<PermissionStatus> Function(Permission permission)? testPermissionRequestHandler;

  /// Menandakan apakah berjalan dalam lingkungan unit test / flutter_test
  static bool get _isTestEnvironment {
    if (!bypassInTest) return false;
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
    if (testPermissionStatusHandler != null) {
      return await testPermissionStatusHandler!(Permission.camera);
    }
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
    bool showRationale = true,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final isGrantedAlready = await hasCameraPermission();
      if (isGrantedAlready) {
        return HrisPermissionResult.granted('Akses kamera telah diberikan.');
      }

      // Tampilkan rationale dialog jika belum ada izin dan showRationale aktif
      if (showRationale && context != null && context.mounted) {
        final allowed = await AppDialogUtil.showPermissionDialog(
          context,
          title: 'Izin Kamera Diperlukan',
          description:
              'Aplikasi HRIS Oasish membutuhkan akses kamera untuk mengambil foto selfie kehadiran dan verifikasi aktivitas kerja.',
          permissions: [
            AppPermissionItem.camera(
              description:
                  'Untuk verifikasi selfie presensi kehadiran dan bukti aktivitas.',
            ),
          ],
          barrierDismissible: false,
          canPop: false,
        );

        if (!allowed) {
          return HrisPermissionResult.denied('Izin kamera ditolak oleh pengguna.');
        }
      }

      PermissionStatus status;
      if (testPermissionRequestHandler != null) {
        status = await testPermissionRequestHandler!(Permission.camera);
      } else {
        status = await Permission.camera.request();
      }

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
    if (testPermissionStatusHandler != null) {
      return await testPermissionStatusHandler!(Permission.photos);
    }
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
    bool showRationale = true,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final isGrantedAlready = await hasGalleryPermission();
      if (isGrantedAlready) {
        return HrisPermissionResult.granted('Akses galeri telah diberikan.');
      }

      if (showRationale && context != null && context.mounted) {
        final allowed = await AppDialogUtil.showPermissionDialog(
          context,
          title: 'Izin Galeri Foto Diperlukan',
          description:
              'Aplikasi HRIS Oasish membutuhkan akses galeri foto untuk memilih foto bukti reimburse atau lampiran dokumen.',
          permissions: [
            AppPermissionItem.gallery(
              description:
                  'Untuk memilih foto nota reimburse dan dokumen klaim.',
            ),
          ],
          barrierDismissible: false,
          canPop: false,
        );

        if (!allowed) {
          return HrisPermissionResult.denied('Izin galeri ditolak oleh pengguna.');
        }
      }

      PermissionStatus status;
      if (testPermissionRequestHandler != null) {
        status = await testPermissionRequestHandler!(Permission.photos);
      } else if (Platform.isAndroid) {
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
    if (testPermissionStatusHandler != null) {
      return await testPermissionStatusHandler!(Permission.storage);
    }
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
    bool showRationale = true,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final isGrantedAlready = await hasDocumentStoragePermission();
      if (isGrantedAlready) {
        return HrisPermissionResult.granted(
            'Izin penyimpanan dokumen telah diberikan.');
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          return HrisPermissionResult.granted('Menggunakan Scoped Storage.');
        }

        if (showRationale && context != null && context.mounted) {
          final allowed = await AppDialogUtil.showPermissionDialog(
            context,
            title: 'Izin Penyimpanan Dokumen Diperlukan',
            description:
                'Izin penyimpanan diperlukan untuk mengunduh slip gaji dan dokumen ke memori perangkat.',
            permissions: [
              AppPermissionItem.storage(
                description:
                    'Untuk menyimpan slip gaji (PDF) dan berkas ke memori perangkat.',
              ),
            ],
            barrierDismissible: false,
            canPop: false,
          );

          if (!allowed) {
            return HrisPermissionResult.denied(
                'Izin penyimpanan ditolak oleh pengguna.');
          }
        }

        PermissionStatus status;
        if (testPermissionRequestHandler != null) {
          status = await testPermissionRequestHandler!(Permission.storage);
        } else {
          status = await Permission.storage.request();
        }
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
    if (testPermissionStatusHandler != null) {
      return await testPermissionStatusHandler!(Permission.locationWhenInUse);
    }
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
    bool showRationale = true,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final isGrantedAlready = await hasLocationPermission();
      if (isGrantedAlready) {
        return HrisPermissionResult.granted('Izin lokasi telah diberikan.');
      }

      if (showRationale && context != null && context.mounted) {
        final allowed = await AppDialogUtil.showPermissionDialog(
          context,
          title: 'Izin Lokasi GPS Diperlukan',
          description:
              'Aplikasi HRIS Oasish membutuhkan akses lokasi GPS untuk memvalidasi posisi presensi dan rute aktivitas Anda.',
          permissions: [
            AppPermissionItem.location(
              description:
                  'Untuk validasi radius kantor dan peta aktivitas lapangan.',
            ),
          ],
          barrierDismissible: false,
          canPop: false,
        );

        if (!allowed) {
          return HrisPermissionResult.denied('Izin lokasi ditolak oleh pengguna.');
        }
      }

      PermissionStatus status;
      if (testPermissionRequestHandler != null) {
        status = await testPermissionRequestHandler!(Permission.locationWhenInUse);
      } else {
        status = await Permission.locationWhenInUse.request();
      }

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
    if (testPermissionStatusHandler != null) {
      return await testPermissionStatusHandler!(Permission.notification);
    }
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
    bool showRationale = true,
  }) async {
    if (_isTestEnvironment) return HrisPermissionResult.granted();
    try {
      final isGrantedAlready = await hasNotificationPermission();
      if (isGrantedAlready) {
        return HrisPermissionResult.granted('Izin notifikasi telah aktif.');
      }

      if (showRationale && context != null && context.mounted) {
        final allowed = await AppDialogUtil.showPermissionDialog(
          context,
          title: 'Izin Notifikasi Diperlukan',
          description:
              'Aktifkan notifikasi HRIS Oasish agar Anda tidak melewatkan pengingat jam kerja, status persetujuan cuti, dan pengumuman perusahaan.',
          permissions: [
            AppPermissionItem.notification(
              description:
                  'Pengingat jam kerja, approval cuti/lembur, dan pengumuman kantor.',
            ),
          ],
          barrierDismissible: false,
          canPop: false,
        );

        if (!allowed) {
          return HrisPermissionResult.denied(
              'Izin notifikasi ditolak oleh pengguna.');
        }
      }

      PermissionStatus status;
      if (testPermissionRequestHandler != null) {
        status = await testPermissionRequestHandler!(Permission.notification);
      } else {
        status = await Permission.notification.request();
      }

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
    bool showRationale = true,
  }) async {
    if (_isTestEnvironment) return true;

    final hasLoc = await hasLocationPermission();
    final hasCam = await hasCameraPermission();

    // Jika keduanya sudah diberikan, langsung berhasil tanpa dialog
    if (hasLoc && hasCam) return true;

    // Jika belum diberikan dan rationale aktif, tampilkan 1 dialog komposit yang elegan
    if (showRationale && context.mounted) {
      final items = <AppPermissionItem>[];
      if (!hasLoc) {
        items.add(AppPermissionItem.location(
          description: 'Untuk verifikasi radius lokasi presensi kantor Anda.',
        ));
      }
      if (!hasCam) {
        items.add(AppPermissionItem.camera(
          description: 'Untuk verifikasi foto selfie saat melakukan presensi.',
        ));
      }

      final allowed = await AppDialogUtil.showPermissionDialog(
        context,
        title: 'Izin Presensi Kehadiran',
        description:
            'Aplikasi HRIS Oasish membutuhkan akses berikut untuk memvalidasi kehadiran Anda secara akurat:',
        permissions: items,
        allowText: items.length > 1 ? 'Izinkan Semua' : 'Izinkan',
        barrierDismissible: false,
        canPop: false,
      );

      if (!allowed) return false;
    }

    // Eksekusi request OS untuk izin yang belum ada (tanpa dialog rationale berulang)
    if (!hasLoc) {
      if (!context.mounted) return false;
      final locResult = await requestLocationPermission(
        context: context,
        showRationale: false,
      );
      if (!locResult.isGranted) return false;
    }

    if (!hasCam) {
      if (!context.mounted) return false;
      final camResult = await requestCameraPermission(
        context: context,
        showRationale: false,
      );
      if (!camResult.isGranted) return false;
    }

    return true;
  }

  /// Meminta izin lengkap untuk alur Catat Aktivitas Lapangan (Lokasi + Kamera + Galeri)
  static Future<bool> requestActivityProofPermissions({
    required BuildContext context,
    bool showRationale = true,
  }) async {
    if (_isTestEnvironment) return true;

    final hasLoc = await hasLocationPermission();
    final hasCam = await hasCameraPermission();
    final hasGal = await hasGalleryPermission();

    if (hasLoc && hasCam && hasGal) return true;

    if (showRationale && context.mounted) {
      final items = <AppPermissionItem>[];
      if (!hasLoc) {
        items.add(AppPermissionItem.location(
          description: 'Untuk mencatat koordinat lokasi kegiatan lapangan.',
        ));
      }
      if (!hasCam) {
        items.add(AppPermissionItem.camera(
          description: 'Untuk mengambil foto bukti kegiatan langsung di lapangan.',
        ));
      }
      if (!hasGal) {
        items.add(AppPermissionItem.gallery(
          description: 'Untuk memilih foto dokumentasi kegiatan dari galeri.',
        ));
      }

      final allowed = await AppDialogUtil.showPermissionDialog(
        context,
        title: 'Izin Aktivitas Lapangan',
        description:
            'Aplikasi HRIS Oasish membutuhkan akses berikut untuk mendokumentasikan kegiatan lapangan:',
        permissions: items,
        allowText: items.length > 1 ? 'Izinkan Semua' : 'Izinkan',
        barrierDismissible: false,
        canPop: false,
      );

      if (!allowed) return false;
    }

    if (!hasLoc) {
      if (!context.mounted) return false;
      final loc = await requestLocationPermission(
        context: context,
        showRationale: false,
      );
      if (!loc.isGranted) return false;
    }

    if (!hasCam) {
      if (!context.mounted) return false;
      final cam = await requestCameraPermission(
        context: context,
        showRationale: false,
      );
      if (!cam.isGranted) return false;
    }

    if (!hasGal) {
      if (!context.mounted) return false;
      final gal = await requestGalleryPermission(
        context: context,
        showRationale: false,
      );
      if (!gal.isGranted) return false;
    }

    return true;
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

  /// Dialog elegan bertema Oasish HRIS saat izin ditolak permanen berbasis `pro_dialog`.
  ///
  /// Menggunakan [barrierDismissible: false] dan [PopScope(canPop: false)] sehingga pengguna
  /// harus secara eksplisit memilih tombol "Buka Pengaturan" atau "Nanti Saja".
  static Future<bool> showPermissionDeniedDialog({
    required BuildContext context,
    required HrisPermissionType type,
    required String title,
    required String description,
    String settingsText = 'Buka Pengaturan',
    String cancelText = 'Nanti Saja',
    bool barrierDismissible = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

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

    final result = await showProDialog<bool>(
      context,
      type: DialogType.warning,
      title: title,
      description: description,
      icon: getIcon(),
      iconBackgroundColor: AppColors.warning,
      barrierDismissible: barrierDismissible,
      showCloseButton: false,
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
      customContent: const PopScope(
        canPop: false,
        child: SizedBox.shrink(),
      ),
      buttons: [
        DialogButton(
          text: cancelText,
          style: DialogButtonStyle.outlined,
          onPressed: () => Navigator.of(context).pop(false),
          customWidget: AppButton(
            key: const ValueKey('permission_denied_cancel_button'),
            text: cancelText,
            variant: AppButtonVariant.outlined,
            borderColor: borderCol,
            height: 46,
            borderRadius: 12,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        DialogButton(
          text: settingsText,
          isPrimary: true,
          color: AppColors.brandTeal,
          onPressed: () {
            Navigator.of(context).pop(true);
            openSettings();
          },
          customWidget: AppButton(
            key: const ValueKey('permission_denied_settings_button'),
            text: settingsText,
            variant: AppButtonVariant.primary,
            height: 46,
            borderRadius: 12,
            onPressed: () {
              Navigator.of(context).pop(true);
              openSettings();
            },
          ),
        ),
      ],
    );

    return result ?? false;
  }

  /// Meminta izin dengan dialog penjelasan awal (Permission Request Dialog via `pro_dialog`).
  ///
  /// Menampilkan dialog yang dikunci ([barrierDismissible: false] dan [PopScope(canPop: false)])
  /// sebelum meminta izin OS. Jika pengguna menekan "Izinkan", barulah callback [onPermissionGranted] dipanggil.
  static Future<bool> requestWithRationale({
    required BuildContext context,
    required List<AppPermissionItem> permissions,
    required Future<bool> Function() onPermissionGranted,
    String? title,
    String? description,
    String allowText = 'Izinkan',
    String denyText = 'Tolak',
  }) async {
    if (_isTestEnvironment) return await onPermissionGranted();

    final allowed = await AppDialogUtil.showPermissionDialog(
      context,
      title: title ?? 'Izin Akses Aplikasi',
      description: description ??
          'HRIS Oasish membutuhkan akses izin berikut untuk dapat menjalankan fitur ini dengan optimal:',
      permissions: permissions,
      allowText: allowText,
      denyText: denyText,
      barrierDismissible: false,
      canPop: false,
    );

    if (!allowed) return false;
    return await onPermissionGranted();
  }
}
