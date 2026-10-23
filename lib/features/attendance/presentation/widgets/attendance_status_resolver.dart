import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/status_banner_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu status tunggal di atas halaman presensi: menjawab "bisa absen sekarang?
/// kalau tidak, kenapa dan harus apa?" lengkap dengan checklist langkah.
/// Menentukan status presensi (judul, pesan, aksi, checklist) dari [AttendanceLoaded].
abstract final class AttendanceStatusResolver {
  static String _breakMessage(AttendanceLoaded state) {
    // Jam perangkat, sama dengan kartu riwayat istirahat.
    final left = state.breakStatus?.remainingMinutesAt(DateTime.now());
    const tail = 'Tekan "Selesai Istirahat" saat kembali bekerja.';
    return left == null ? tail : 'Sisa jatah $left menit. $tail';
  }

  static String _distance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.toStringAsFixed(0)} m';

  static StatusBannerSpec resolve(AttendanceLoaded state) {
    final data = state.data;
    final loc = data.selectedWorkLocation;
    final isAnyWhere = loc?.isAnyWhere ?? false;
    final actionName = data.isClockedIn ? 'Absen Pulang' : 'Absen Masuk';
    final method = data.isLivenessMethod
        ? 'wajah (Liveness AI)'
        : data.isBiometricMethod
        ? 'sidik jari / Face ID'
        : 'foto selfie';

    if (!data.hasAttendanceMethod) {
      return const StatusBannerSpec(
        tone: StatusTone.error,
        icon: LucideIcons.shieldAlert,
        title: 'Metode presensi belum diatur',
        message:
            'Hubungi admin atau atasan Anda untuk mengatur metode presensi.',
      );
    }
    if (!data.hasWorkLocation) {
      return const StatusBannerSpec(
        tone: StatusTone.error,
        icon: LucideIcons.mapPinOff,
        title: 'Lokasi kerja belum diatur',
        message:
            'Hubungi admin atau atasan Anda untuk menentukan lokasi kerja.',
      );
    }
    if (data.isClockedIn && data.isClockedOut) {
      return const StatusBannerSpec(
        tone: StatusTone.success,
        icon: LucideIcons.circleCheck,
        title: 'Presensi hari ini selesai',
        message: 'Terima kasih, sampai jumpa besok!',
      );
    }
    if (data.isDayOff) {
      return const StatusBannerSpec(
        tone: StatusTone.warning,
        icon: LucideIcons.calendarOff,
        title: 'Hari ini jadwal libur kerja',
        message: 'Anda tidak memiliki jadwal kerja aktif hari ini.',
      );
    }
    if (!data.hasSchedule) {
      return const StatusBannerSpec(
        tone: StatusTone.warning,
        icon: LucideIcons.calendarX,
        title: 'Tidak ada jadwal kerja',
        message: 'Anda belum memiliki jadwal kerja untuk hari ini.',
      );
    }

    final steps = <StatusStep>[
      StatusStep(
        'Lokasi terdeteksi',
        state.isGpsAcquired
            ? StatusStepState.done
            : state.gpsIssue != null
            ? StatusStepState.failed
            : StatusStepState.pending,
      ),
      StatusStep(
        isAnyWhere
            ? 'Bebas lokasi, tanpa batas radius'
            : 'Berada dalam radius kantor',
        isAnyWhere
            ? StatusStepState.done
            : !state.isGpsAcquired
            ? StatusStepState.pending
            : state.isInsideGeofence
            ? StatusStepState.done
            : StatusStepState.failed,
      ),
      StatusStep(
        'Verifikasi $method saat tombol ditekan',
        StatusStepState.pending,
      ),
    ];

    if (!state.isGpsAcquired) {
      switch (state.gpsIssue) {
        case AttendanceGpsIssue.permissionDenied:
          return StatusBannerSpec(
            tone: StatusTone.error,
            icon: LucideIcons.locateOff,
            title: 'Izin lokasi dibutuhkan',
            message:
                'Aplikasi belum diizinkan mengakses lokasi, sehingga tidak bisa memastikan Anda berada di area kerja.',
            actionText: 'Izinkan Akses Lokasi',
            steps: steps,
          );
        case AttendanceGpsIssue.serviceDisabled:
          return StatusBannerSpec(
            tone: StatusTone.error,
            icon: LucideIcons.locateOff,
            title: 'GPS perangkat mati',
            message: 'Aktifkan GPS/Lokasi di perangkat Anda lalu coba lagi.',
            actionText: 'Aktifkan GPS',
            steps: steps,
          );
        case AttendanceGpsIssue.unavailable:
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
          if (!isAnyWhere) {
            return StatusBannerSpec(
              tone: StatusTone.info,
              icon: LucideIcons.crosshair,
              title: 'Mencari lokasi Anda…',
              message:
                  'Mohon tunggu sebentar, kami sedang memastikan posisi Anda.',
              steps: steps,
            );
          }
      }
    }

    if (!isAnyWhere && !state.isInsideGeofence) {
      final dist = state.distanceToOfficeMeters;
      final radius = data.geofenceRadiusMeters.toStringAsFixed(0);
      return StatusBannerSpec(
        tone: StatusTone.error,
        icon: LucideIcons.mapPinOff,
        title: 'Anda di luar radius kantor',
        message:
            '${dist != null ? 'Posisi Anda ±${_distance(dist)} dari ${data.officeName}. ' : ''}'
            'Batas presensi $radius m. Dekati area kantor atau ganti lokasi kerja di bawah peta.',
        actionText: 'Perbarui Lokasi',
        steps: steps,
      );
    }

    if (data.isOnBreak) {
      return StatusBannerSpec(
        tone: StatusTone.info,
        icon: LucideIcons.coffee,
        title: 'Sedang istirahat',
        message: _breakMessage(state),
        steps: steps,
      );
    }

    final weakGps = state.isGpsAcquired && state.gpsAccuracyMeters > 100;
    return StatusBannerSpec(
      tone: weakGps ? StatusTone.warning : StatusTone.success,
      icon: weakGps ? LucideIcons.satelliteDish : LucideIcons.circleCheck,
      title: 'Siap $actionName',
      message: weakGps
          ? 'Sinyal GPS lemah (±${state.gpsAccuracyMeters.toStringAsFixed(0)} m). Pindah ke area terbuka agar lebih akurat, atau lanjut tekan tombol di bawah.'
          : isAnyWhere
          ? 'Anda bisa absen dari mana saja. Tekan tombol di bawah untuk melanjutkan.'
          : 'Anda berada di area ${data.officeName}. Tekan tombol di bawah untuk melanjutkan.',
      steps: steps,
    );
  }
}
