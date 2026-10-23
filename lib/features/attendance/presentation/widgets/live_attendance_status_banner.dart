import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_realtime_map_card.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/status_banner_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Banner status halaman Presensi Live: memandu user langkah demi langkah
/// (GPS terkunci → alasan diisi → verifikasi) dan menjelaskan kendala GPS.
class LiveAttendanceStatusBanner extends StatelessWidget {
  final LiveAttendanceState state;

  /// Dipanggil tombol aksi banner (izinkan akses / aktifkan GPS / coba lagi).
  final VoidCallback? onRefreshLocation;

  const LiveAttendanceStatusBanner({
    super.key,
    required this.state,
    this.onRefreshLocation,
  });

  StatusBannerSpec _resolve() {
    final typeName = state.attendanceType == 'in' ? 'Masuk' : 'Pulang';
    final hasGps = state.hasValidCoordinates;
    final accuracy = state.accuracyMeters;
    final weakGps = hasGps && accuracy != null && accuracy > 100;
    final hasReason = state.reason.trim().isNotEmpty;
    final needsPhoto = state.isPhotoMethod;

    final verifyStep = needsPhoto
        ? StatusStep(
            'Foto selfie diambil',
            state.photo != null
                ? StatusStepState.done
                : StatusStepState.pending,
          )
        : StatusStep(
            state.isLivenessMethod
                ? 'Verifikasi wajah (Liveness AI) saat kirim'
                : 'Verifikasi sidik jari / Face ID saat kirim',
            StatusStepState.pending,
          );
    final steps = <StatusStep>[
      StatusStep(
        'Lokasi GPS terkunci',
        hasGps
            ? StatusStepState.done
            : state.gpsIssue != null
            ? StatusStepState.failed
            : StatusStepState.pending,
      ),
      StatusStep(
        'Alasan presensi diisi',
        hasReason ? StatusStepState.done : StatusStepState.pending,
      ),
      verifyStep,
    ];

    if (!hasGps) {
      switch (state.gpsIssue) {
        case MapGpsIssue.permissionDenied:
          return StatusBannerSpec(
            tone: StatusTone.error,
            icon: LucideIcons.locateOff,
            title: 'Izin lokasi dibutuhkan',
            message:
                'Presensi luar kantor mencatat titik lokasi Anda. Izinkan akses lokasi agar presensi bisa dikirim.',
            actionText: 'Izinkan Akses Lokasi',
            steps: steps,
          );
        case MapGpsIssue.serviceDisabled:
          return StatusBannerSpec(
            tone: StatusTone.error,
            icon: LucideIcons.locateOff,
            title: 'GPS perangkat mati',
            message: 'Aktifkan GPS/Lokasi di perangkat Anda lalu coba lagi.',
            actionText: 'Aktifkan GPS',
            steps: steps,
          );
        case MapGpsIssue.unavailable:
          return StatusBannerSpec(
            tone: StatusTone.warning,
            icon: LucideIcons.satelliteDish,
            title: 'Lokasi belum ditemukan',
            message:
                'Sinyal GPS lemah. Pindah ke area terbuka atau dekat jendela, lalu coba lagi.',
            actionText: 'Coba Lagi',
            steps: steps,
          );
        case null:
          return StatusBannerSpec(
            tone: StatusTone.info,
            icon: LucideIcons.crosshair,
            title: 'Mencari lokasi Anda…',
            message:
                'Mohon tunggu sebentar sampai titik lokasi Anda terkunci di peta.',
            steps: steps,
          );
      }
    }

    if (weakGps) {
      return StatusBannerSpec(
        tone: StatusTone.warning,
        icon: LucideIcons.satelliteDish,
        title: 'Sinyal GPS lemah',
        message:
            'Akurasi ±${accuracy.toStringAsFixed(0)} m. Pindah ke area terbuka agar lokasi presensi lebih akurat.',
        actionText: 'Perbarui Lokasi',
        steps: steps,
      );
    }

    if (!hasReason) {
      return StatusBannerSpec(
        tone: StatusTone.info,
        icon: LucideIcons.fileText,
        title: 'Isi alasan presensi',
        message:
            'Tuliskan alasan atau keterangan pekerjaan di lokasi ini pada form di bawah.',
        steps: steps,
      );
    }

    if (needsPhoto && state.photo == null) {
      return StatusBannerSpec(
        tone: StatusTone.info,
        icon: LucideIcons.camera,
        title: 'Ambil foto selfie',
        message:
            'Ketuk kotak foto di bawah untuk mengambil selfie bukti kehadiran.',
        steps: steps,
      );
    }

    return StatusBannerSpec(
      tone: StatusTone.success,
      icon: LucideIcons.circleCheck,
      title: 'Siap kirim presensi $typeName',
      message: needsPhoto
          ? 'Semua data lengkap. Tekan tombol kirim di bawah.'
          : state.isLivenessMethod
          ? 'Kamera Liveness AI akan terbuka saat Anda menekan tombol kirim.'
          : 'Anda akan diminta sidik jari / Face ID saat menekan tombol kirim.',
      steps: steps,
    );
  }

  @override
  Widget build(BuildContext context) =>
      StatusBannerCard(spec: _resolve(), onAction: onRefreshLocation);
}
