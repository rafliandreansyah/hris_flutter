# Indeks Dokumentasi — OASISH HRIS Mobile App (Flutter)

> **Cakupan**: peta seluruh dokumen di folder `docs/`. Satu topik hanya dijelaskan secara mendalam di satu tempat; dokumen lain menautkannya.
> **Terakhir diperbarui**: Oktober 2026. Dicocokkan langsung dengan kode sumber `hris_flutter` (Flutter 3.x, Dart 3.x, flutter_bloc, Clean Architecture, Google Stitch M3 Teal Oasis).

---

## Mulai dari mana

| Kebutuhan | Dokumen |
|---|---|
| Menyiapkan lingkungan lokal (Flutter, Dart, JDK 17, CocoaPods, Android Studio, Xcode), koneksi backend lokal, dan alur pembuatan fitur baru | [ONBOARDING.md](./ONBOARDING.md) |
| Memahami arsitektur sistem: Feature-First Clean Architecture, BLoC pattern, Dio network client, silent token refresh, storage terenkripsi, theme tokens, dan background service | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| Aturan wewenang siapa boleh apa: Arsitektur otorisasi 3-lapisan, visibilitas menu Bento Grid, izin aksi fungsional di memori, penanganan 401 & 403, dan katalog permission API vs Mobile | [AUTHORIZATION.md](./AUTHORIZATION.md) |
| Penjelasan dan perilaku **seluruh 17 domain fitur aplikasi mobile secara lengkap**: antarmuka UI, alur bisnis, integrasi kamera & GPS geofencing, validasi, dan endpoint REST API | [FEATURES.md](./FEATURES.md) |
| Panduan **deployment komprehensif (Development & Production)**: build Docker API dev (`muratech/oasish-api:dev`), rilis APK/IPA Development targeting staging/dev, rilis Android Keystore & AAB Google Play Console, iOS TestFlight & App Store, sertifikat Apple, Fastlane, dan kebijakan privasi toko aplikasi | [DEPLOYMENT.md](./DEPLOYMENT.md) |
| Menjalankan dan menulis pengujian berjenjang: Unit Testing, BLoC Testing, Widget Testing, End-to-End (E2E) testing dengan Patrol & AndroidX Test Orchestrator, mocking, dan quality gate | [TESTING.md](./TESTING.md) |
| Rencana pengembangan masa depan, inisiatif jangka pendek (offline-first SQLite), jangka menengah (smartwatch & widgets), dan refactoring fondasi | [ROADMAP.md](./ROADMAP.md) |
| Checklist verifikasi perbaikan bug, audit edge-case hardware (GPS, Fake GPS, Kamera, Biometrik, Baterai, Izin OS), audit token, dan konsistensi UI | [BUG_FIX_CHECKLIST.md](./BUG_FIX_CHECKLIST.md) |

---

## Ringkasan 17 Domain di `FEATURES.md`

Dokumen [FEATURES.md](./FEATURES.md) merangkum secara mendalam dan menyeluruh 17 domain operasional aplikasi mobile:

1. **Splash & Otentikasi (`auth`, `splash`)**: Autentikasi NIK/Email + Kata Sandi, biometrik lokal (*LocalAuth Face ID / Fingerprint*), telemetri perangkat, silent refresh, dan logout aman.
2. **Beranda & Dashboard Bento Grid (`dashboard`)**: Header profil karyawan, live clock detik berjalan, banner status shift hari ini, aksi cepat presensi (*Quick Clock-In/Out*), dan Bento Grid modular responsif (12 menu dengan filter visibilitas dinamis).
3. **Presensi Harian & Verifikasi Wajah (`attendance`)**: Clock In & Clock Out interaktif, validasi GPS Geofencing radius kantor, pencegahan Fake GPS / Mock Location, deteksi wajah liveness di perangkat dengan Google ML Kit, dan riwayat kehadiran bulanan.
4. **Pengajuan Koreksi Presensi & Kehadiran Khusus (`attendance_request`)**: Pengajuan koreksi jam absensi (lupa absen, tugas luar), pill-style 2-tab screen (*Pengajuan Saya* & *Persetujuan Tim*), unggah surat tugas, dan alur approval atasan.
5. **Pelaporan Aktivitas Lapangan & Geotagging (`activity`)**: Linimasa feed aktivitas bergaya task stream, foto kamera langsung, auto geotagging GPS, kategori kegiatan, dan catatan progres pekerjaan.
6. **Pelacakan Lokasi Latar Belakang (`tracking`)**: Foreground Service Android & CoreLocation iOS, resolusi prioritas ganda (Aktivitas Lapangan vs Presensi Biasa), efisiensi baterai, offline buffering, dan pengiriman batch koordinat (`POST /tracking/batch`).
7. **Cuti & Izin Kerja (`leave`)**: Ringkasan saldo sisa cuti tahunan, form cuti dengan custom date range picker (mengabaikan hari libur), unggah surat dokter, dan approval atasan.
8. **Pengajuan Lembur / Overtime (`overtime`)**: Form pengajuan lembur, kalkulasi otomatis durasi jam, nomor Surat Perintah Kerja (SPK), estimasi upah lembur Depnaker, dan approval atasan.
9. **Klaim Biaya & Kasbon Dinas (`reimbursement`)**: Klaim pengeluaran murni (*Out-of-Pocket*), pengajuan kasbon dinas (*Cash Advance*), pelaporan nota struk fisik (*Settlement*), rekonsiliasi selisih uang, dan status pencairan (*Disbursement*) oleh Finance.
10. **Slip Gaji Digital (`payroll`)**: Riwayat penerbitan slip gaji bulanan, pratinjau PDF interaktif (`syncfusion_flutter_pdfviewer`), rincian komponen gaji kotor/bersih/potongan/BPJS, serta tombol unduh dan bagikan slip aman.
11. **Jadwal Kerja & Shift (`schedule`)**: Kalender shift bulanan karyawan, penanda warna status hadir/libur, kalender hari libur nasional, dan informasi rekan satu shift.
12. **Direktori Rekan & Profil Karyawan (`employee`)**: Pencarian seluruh rekan kerja via `AppSearchBar`, filter perusahaan/departemen, pintasan telepon/WhatsApp/email, serta detail profil pribadi, karir, bank, dan BPJS.
13. **Siklus Hidup & Riwayat Karir (`lifecycle`)**: Riwayat perjalanan karir karyawan (New Hire, Promosi, Demosi, Rotasi Cabang, Perpanjangan PKWT, Pengangkatan Tetap PKWTT).
14. **Manajemen Aset & Inventaris (`asset`)**: Daftar inventaris kantor yang dipinjamkan, konfirmasi tanda tangan serah terima (*Handover*), pelaporan kerusakan fisik, dan pengajuan pengembalian aset.
15. **Surat Peringatan & Disiplin (`warning_letter`)**: Riwayat sanksi disiplin SP1, SP2, SP3, surat teguran, detail pasal pelanggaran, masa berlaku sanksi, dan tombol konfirmasi tanda terima (*Read Acknowledgment*).
16. **Pengunduran Diri / Offboarding (`resignation`)**: Pengajuan resign mandiri, validasi notice period (minimal 30 hari), alasan pengunduran diri, dan pelacakan status checklist exit clearance (aset, kasbon, paklaring).
17. **Pengumuman & Pusat Notifikasi (`announcement`, `notification`)**: Banner pengumuman penting (*pinned*), penampil teks kaya HTML dan PDF surat edaran, kotak masuk notifikasi in-app, integrasi Firebase Cloud Messaging (FCM), serta routing deep link otomatis saat notifikasi diketuk.

---

## Dokumen Teknis Tambahan

Di luar dokumen utama di atas, tersedia dokumen referensi teknis spesifik:
- **[DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md)**: Sinkronisasi token desain Stitch M3 *Teal Oasis* (Colors, Typography, Spacing, Radius, Component Styling).
- **[LOCATION_TRACKING.md](./LOCATION_TRACKING.md)**: Spesifikasi arsitektur mendalam pelacakan lokasi latar belakang, foreground service, dan resolusi prioritas ganda.
- **[NOTIFICATION_CLICK_ACTION_SPEC.md](./NOTIFICATION_CLICK_ACTION_SPEC.md)**: Spesifikasi kontrak payload push notification FCM dan pemetaan deep-link route dispatcher.
- **[TESTING_FLOW_AND_CHECKLIST.md](./TESTING_FLOW_AND_CHECKLIST.md)**: Skenario operasional E2E terperinci untuk seluruh 18 modul dan checklist kasus uji Patrol.

---

## Aturan Menjaga Dokumen

- **Satu Sumber Kebenaran**: Fakta teknis (konstanta permission, endpoint API, struktur rute, skema DTO) harus selalu dicocokkan dengan kode sumber aktual: endpoint di `lib/core/constants/api_endpoints.dart`, rute di `lib/app/routes/`, token di `lib/app/config/`, dan permission di `lib/core/constants/app_permissions.dart`.
- **Hindari Duplikasi**: Jangan membuat tabel fakta yang sama di dua dokumen berbeda. Jelaskan secara mendalam di dokumen asalnya, lalu tautkan dari dokumen lain.
- **Konsistensi Lintas Repositori**: Setiap pembaruan kontrak endpoint atau kode permission harus selalu selaras dengan dokumentasi di `../muratech_hris_server/docs/` dan `../hris-web/docs/`.
