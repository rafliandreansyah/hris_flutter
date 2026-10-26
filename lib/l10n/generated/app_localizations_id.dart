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
  String get dayOffSchedule => 'Libur Kerja';

  @override
  String get dayOffNotice => 'Jadwal Libur Kerja';

  @override
  String get dayOffDescription =>
      'Hari ini Anda tidak memiliki jadwal kerja aktif (Hari Libur).';

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
  String get theme => 'Tema';

  @override
  String get themeSubtitle => 'Pilih tema tampilan aplikasi';

  @override
  String get selectTheme => 'Pilih Tema';

  @override
  String get themeSystem => 'Mengikuti Sistem';

  @override
  String get themeLight => 'Mode Terang';

  @override
  String get themeDark => 'Mode Gelap';

  @override
  String get themeUpdatedSuccess => 'Tema berhasil diperbarui';

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
  String earlyByMinutes(int minutes) {
    return 'Pulang Lebih Awal $minutes mnt';
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
      'Absen dari pengajuan presensi luar kantor';

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

  @override
  String get tabMyRequests => 'Pengajuan Saya';

  @override
  String get tabTeamApprovals => 'Persetujuan Tim';

  @override
  String get tabSelf => 'Saya';

  @override
  String get tabMyTeam => 'Tim Saya';

  @override
  String get tabWarningReceived => 'Surat Diterima';

  @override
  String get tabWarningIssued => 'Diterbitkan';

  @override
  String get menuAttendance => 'Riwayat Absen';

  @override
  String get menuOutsideAttendance => 'Absen Luar';

  @override
  String get menuSchedule => 'Jadwal Kerja';

  @override
  String get menuLiveTracking => 'Live Tracking';

  @override
  String get menuLeave => 'Izin & Cuti';

  @override
  String get menuOvertime => 'Lembur';

  @override
  String get menuActivity => 'Aktivitas';

  @override
  String get menuPayroll => 'Slip Gaji';

  @override
  String get menuClaims => 'Klaim & Kasbon';

  @override
  String get menuEmployee => 'Pegawai';

  @override
  String get menuWarningLetter => 'Surat Peringatan';

  @override
  String get menuAsset => 'Aset';

  @override
  String get menuResignation => 'Pengunduran Diri';

  @override
  String get menuMore => 'Lainnya';

  @override
  String get menuGroupAttendance => 'Kehadiran';

  @override
  String get menuGroupRequests => 'Pengajuan';

  @override
  String get menuGroupFinance => 'Keuangan';

  @override
  String get menuGroupEmployee => 'Karyawan';

  @override
  String get seeAll => 'Lihat Semua';

  @override
  String get clockInAction => 'Absen Masuk';

  @override
  String get clockOutAction => 'Absen Pulang';

  @override
  String get clockInShort => 'Masuk';

  @override
  String get clockOutShort => 'Pulang';

  @override
  String get latestCompanyAnnouncement => 'Terbaru · Pengumuman Perusahaan';

  @override
  String get titleLeave => 'Cuti & Izin';

  @override
  String get titleLeaveDetail => 'Detail Cuti / Izin';

  @override
  String get titleOvertime => 'Pengajuan Lembur';

  @override
  String get titleOvertimeDetail => 'Detail Lembur';

  @override
  String get titleAttendanceLogs => 'Riwayat Presensi';

  @override
  String get titleActivityReports => 'Laporan Aktivitas';

  @override
  String get titleActivityDetail => 'Detail Aktivitas';

  @override
  String get titleCreateActivity => 'Buat Aktivitas';

  @override
  String get statusWaitingApproval => 'Menunggu Persetujuan';

  @override
  String get statusApproved => 'Disetujui';

  @override
  String get statusRejected => 'Ditolak';

  @override
  String get clockInLabel => 'Absen Masuk';

  @override
  String get clockOutLabel => 'Absen Pulang';

  @override
  String get titleEmployeeDirectory => 'Direktori Pegawai';

  @override
  String get consentTitle => 'Kebijakan Privasi & Syarat Ketentuan';

  @override
  String get consentIntro =>
      'Sebelum menggunakan Oasish, mohon baca dan setujui cara kami mengumpulkan dan memproses data Anda.';

  @override
  String get consentDataHeader => 'DATA YANG KAMI PROSES';

  @override
  String get consentDataLocation =>
      'Lokasi presisi untuk presensi. Selama Anda clock-in hingga clock-out dan saat tugas lapangan, rute kerja direkam termasuk saat aplikasi ditutup atau di latar belakang.';

  @override
  String get consentDataCamera =>
      'Kamera dan foto untuk swafoto presensi, bukti aktivitas, dan dokumen klaim.';

  @override
  String get consentDataBiometric =>
      'Biometrik (sidik jari / Face ID) diproses di perangkat dan tidak dikirim ke server.';

  @override
  String get consentDataDevice =>
      'Data kepegawaian, ID perangkat, level baterai, dan token notifikasi untuk menjalankan layanan.';

  @override
  String get consentDocumentsHeader => 'DOKUMEN LEGAL';

  @override
  String get consentAgreement =>
      'Saya telah membaca dan menyetujui Kebijakan Privasi dan Syarat & Ketentuan Oasish.';

  @override
  String get consentAccept => 'Setuju & Lanjutkan';

  @override
  String get legalPrivacyPolicy => 'Kebijakan Privasi';

  @override
  String get legalTerms => 'Syarat & Ketentuan';

  @override
  String get legalRefundPolicy => 'Kebijakan Pengembalian Dana';

  @override
  String get legalFaq => 'FAQ';

  @override
  String get legalDeleteData => 'Hapus Akun & Data';

  @override
  String get legalDeleteDataSubtitle =>
      'Ajukan penghapusan akun dan data pribadi Anda';

  @override
  String get legalContact => 'Kontak';

  @override
  String get legalAndHelp => 'LEGAL & BANTUAN';

  @override
  String get legalLinkOpenFailed =>
      'Halaman tidak dapat dibuka. Periksa koneksi internet Anda lalu coba lagi.';

  @override
  String get trackingResumeTitle => 'Pelacakan lokasi kerja dijeda';

  @override
  String get trackingResumeBody =>
      'Ketuk untuk melanjutkan pelacakan selama jam kerja Anda.';

  @override
  String get menuLifecycle => 'Evaluasi & Kontrak';

  @override
  String get teamContractsTitle => 'Kontrak Berakhir Tim';

  @override
  String get teamContractsEmptyTitle =>
      'Tidak Ada Kontrak yang Segera Berakhir';

  @override
  String get teamContractsEmptyMessage =>
      'Belum ada kontrak bawahan yang berakhir dalam 30 hari ke depan.';

  @override
  String teamContractsDaysLeft(int days) {
    return 'Sisa $days hari';
  }

  @override
  String teamContractsEndsOn(String date) {
    return 'Berakhir $date';
  }

  @override
  String get teamContractsOpenEvaluation => 'Lihat Evaluasi';

  @override
  String get teamContractsNoEvaluation => 'Evaluasi belum dibuat';
}
