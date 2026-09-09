// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Oasish';

  @override
  String greeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Batal';

  @override
  String get close => 'Tutup';

  @override
  String get back => 'Kembali';

  @override
  String get save => 'Simpan';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get loading => 'Memproses...';

  @override
  String get error => 'Terjadi Kesalahan';

  @override
  String get success => 'Berhasil';

  @override
  String get notice => 'Pemberitahuan';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get currentStatus => 'STATUS SAAT INI';

  @override
  String get flexibleShift => 'Shift Fleksibel';

  @override
  String get noWorkSchedule => 'Tidak Ada Jadwal Kerja';

  @override
  String get quickAccess => 'Akses Cepat';

  @override
  String get updates => 'Pembaruan';

  @override
  String get noAnnouncements => 'Tidak ada pengumuman';

  @override
  String get noAnnouncementsDesc =>
      'Saat ini belum ada pengumuman terbaru dari perusahaan';

  @override
  String get failedToLoadDashboard => 'Gagal memuat Dashboard';

  @override
  String get attendanceTitle => 'Kehadiran & Check-In';

  @override
  String get clockIn => 'Masuk Kerja';

  @override
  String get clockOut => 'Pulang Kerja';

  @override
  String get breakSession => 'Istirahat';

  @override
  String get breakIn => 'Selesai Istirahat';

  @override
  String get breakOut => 'Mulai Istirahat';

  @override
  String get clockInNow => 'Masuk Kerja Sekarang';

  @override
  String get clockOutNow => 'Pulang Kerja Sekarang';

  @override
  String get reportLocationIssue => 'Laporkan Kendala Lokasi';

  @override
  String get scheduleNotice => 'Pemberitahuan Jadwal';

  @override
  String get failedToLoadAttendance => 'Gagal Memuat Absensi';

  @override
  String get insideGeofence => 'Dalam Radius Kantor';

  @override
  String get outsideGeofence => 'Di Luar Radius Kantor';

  @override
  String get anywhereAttendance => 'Absen Dimana Saja';

  @override
  String get gpsDetecting => 'Mendeteksi lokasi...';

  @override
  String get updateGpsLocation => 'Perbarui Lokasi GPS';

  @override
  String get workLocation => 'Lokasi Kerja';

  @override
  String get accountSettings => 'Pengaturan Akun';

  @override
  String get settingsAndPreferences => 'PENGATURAN & PREFERENSI';

  @override
  String get changePassword => 'Ganti Password';

  @override
  String get changePasswordSubtitle => 'Perbarui kata sandi akun keamanan Anda';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get notificationsSubtitle =>
      'Pengingat absen, izin, lembur & broadcast';

  @override
  String get active => 'Aktif';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSubtitle => 'Pilih bahasa tampilan aplikasi';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get indonesian => 'Bahasa Indonesia (ID)';

  @override
  String get english => 'English (EN)';

  @override
  String get logout => 'Keluar dari Akun (Logout)';

  @override
  String get logoutSubtitle => 'Keluar dari sesi login perangkat ini';

  @override
  String get logoutConfirmationTitle => 'Konfirmasi Logout';

  @override
  String get logoutConfirmationDesc =>
      'Apakah Anda yakin ingin keluar dari sesi akun ini?';

  @override
  String get languageUpdatedSuccess => 'Bahasa berhasil diperbarui';

  @override
  String get attendanceDetailTitle => 'Detail Presensi';

  @override
  String get verificationDetails => 'Verifikasi Presensi';

  @override
  String get onTime => 'Tepat Waktu';

  @override
  String lateByMinutes(int minutes) {
    return 'Terlambat $minutes mnt';
  }

  @override
  String get verifiedIdentityNotice =>
      'Identitas terverifikasi dengan biometrik dan geofence GPS';

  @override
  String get attendanceLocation => 'Lokasi Presensi';

  @override
  String get openInMaps => 'Buka di Maps';

  @override
  String get gpsCoordinates => 'Koordinat GPS';

  @override
  String get outsideAttendanceTitle => 'Kehadiran Luar Kantor';

  @override
  String get outsideAttendanceDesc =>
      'Absen dari pengajuan Outside Attendance / Kehadiran luar kantor';

  @override
  String get requestReference => 'Referensi Pengajuan';

  @override
  String get employeeInfo => 'Informasi Karyawan';

  @override
  String get shiftSchedule => 'Jadwal Shift';

  @override
  String get attendanceMethod => 'Metode Presensi';

  @override
  String get proofAttachment => 'Bukti Foto Presensi';

  @override
  String get tapToPreview => 'Ketuk untuk memperbesar foto';

  @override
  String get requestAttendanceCorrection => 'Ajukan Koreksi Absensi';

  @override
  String get attendanceDetailNotFound => 'Data detail presensi tidak ditemukan';

  @override
  String get attendanceDetailNoAccess =>
      'Anda tidak memiliki hak akses untuk melihat data ini';

  @override
  String get noPayrollPeriodTitle => 'Periode Penggajian Belum Ada';

  @override
  String get noPayrollPeriodLastMonthDesc =>
      'Belum ada periode penggajian untuk bulan lalu. Anda dapat melihat riwayat pada periode Bulan Ini.';

  @override
  String get viewCurrentMonth => 'Lihat Bulan Ini';
}
