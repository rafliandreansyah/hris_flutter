# Roadmap Pengembangan — OASISH HRIS Mobile App (Flutter)

> **Cakupan**: rencana pengembangan masa depan, inisiatif peningkatan performa, fitur mobile yang direncanakan, serta jadwal rilis untuk aplikasi **OASISH HRIS Mobile (Flutter)**.
> **Terakhir diperbarui**: Oktober 2026.

---

## Daftar Isi

1. [Status Rilis & Milestone Saat Ini](#1-status-rilis--milestone-saat-ini)
2. [Prioritas Jangka Pendek (Q4 2026)](#2-prioritas-jangka-pendek-q4-2026)
3. [Prioritas Jangka Menengah (Q1 – Q2 2027)](#3-prioritas-jangka-menengah-q1--q2-2027)
4. [Inisiatif Jangka Panjang & Eksplorasi (Q3 – Q4 2027)](#4-inisiatif-jangka-panjang--eksplorasi-q3--q4-2027)
5. [Inisiatif Refactoring & Peningkatan Fondasi Teknis](#5-inisiatif-refactoring--peningkatan-fondasi-teknis)

---

## 1. Status Rilis & Milestone Saat Ini

### Milestone Versi 1.0.0 (Selesai — Oktober 2026)
- [x] **17 Modul Bisnis Inti**: Otentikasi, Beranda Bento Grid, Presensi GPS & Wajah (ML Kit), Koreksi Absensi, Aktivitas Lapangan, Pelacakan Latar Belakang (Foreground Service), Cuti, Lembur, Reimbursement & Kasbon, Slip Gaji PDF Viewer, Kalender Shift, Direktori Rekan Kerja, Siklus Hidup Karyawan, Manajemen Aset, Surat Peringatan, Pengunduran Diri (Resign), dan Pusat Notifikasi In-App + FCM.
- [x] **Design System Stitch M3 Teal Oasis**: 100% integrasi token warna, tipografi Plus Jakarta Sans, dan geometri radius.
- [x] **Keamanan Sesi Dua Arah**: Implementasi *Silent Token Refresh* terpadu dengan rotasi token di `TokenRefresher`, enkripsi `FlutterSecureStorage`, dan proteksi anti-tamper.
- [x] **Cakupan Pengujian**: 220+ file unit & widget test di `test/` dan 20 skenario integrasi E2E dengan Patrol di `integration_test/`.

---

## 2. Prioritas Jangka Pendek (Q4 2026)

### 2.1 Mode Offline Penuh (Offline-First SQLite Cache)
- **Konteks**: Karyawan lapangan di area pertambangan, perkebunan, atau basement gedung sering mengalami kehilangan sinyal internet saat hendak melakukan presensi atau pelaporan kegiatan.
- **Rencana**:
  - Mengintegrasikan basis data lokal terenkripsi (`drift` / `sqflite_sqlcipher`) untuk menyimpan master shift, data profil, dan antrian presensi.
  - *Outbox Synchronization Pattern*: Presensi masuk/pulang saat offline disimpan ke SQLite lokal, ditandai status `PENDING_SYNC`, dan otomatis diunggah ke server saat koneksi internet kembali aktif (`connectivity_plus`).

### 2.2 Uji Sesi Nyata & Rotasi Refresh Token
- Uji coba nyata di staging server dengan masa kedaluwarsa JWT pendek (2 menit) untuk memvalidasi rotasi refresh token otomatis tanpa kedipan (*flicker*) atau logout paksa.
- Penambahan skenario pengujian unit tambahan pada `AuthRepositoryImpl` dan `AuthBloc`.

### 2.3 Konfirmasi Reset Password In-App
- Membuat layar formulir konfirmasi token reset sandi (`POST /auth/reset-password/confirm`) langsung di dalam aplikasi tanpa mengharuskan pengguna membuka browser web.

---

## 3. Prioritas Jangka Menengah (Q1 – Q2 2027)

### 3.1 Integrasi Smartwatch (Wear OS & Apple Watch)
- **Komponen**: *Companion App* ringan untuk jam tangan pintar.
- **Fungsionalitas**:
  - *One-Tap Clock In/Out*: Melakukan presensi cepat dengan verifikasi GPS jam tangan saat memasuki area kantor.
  - Komplikasi Tampilan Jam (*Watch Face Complication*): Menampilkan sisa waktu shift kerja dan pengingat waktu pulang.

### 3.2 Widget Beranda HP (Android AppWidget & iOS Live Activities)
- **iOS Live Activities (Dynamic Island)**: Menampilkan status presensi hari ini, durasi jam kerja berjalan, dan notifikasi persetujuan cuti yang mendesak di layar kunci (*Lock Screen*).
- **Android Glance AppWidget**: Widget ukuran 2x2 atau 4x2 di homescreen untuk pintasan presensi sekali sentuh dan ringkasan jadwal shift besok.

### 3.3 Presensi Indoor Berbasis BLE Beacon (Bluetooth Low Energy)
- Untuk gedung bertingkat tinggi atau ruangan di mana sinyal GPS lemah atau melompat (*GPS drift*).
- Mengintegrasikan pemindaian iBeacon / Eddystone yang terpasang di lobi kantor sebagai bukti kehadiran fisik yang sah.

---

## 4. Inisiatif Jangka Panjang & Eksplorasi (Q3 – Q4 2027)

### 4.1 In-App Direct Chat & Koordinasi Lapangan
- Komunikasi pesan instan antar karyawan dan atasan langsung di dalam aplikasi (menggunakan WebSocket atau Firebase Realtime Database) tanpa perlu berpindah ke aplikasi perpesanan pihak ketiga.
- Berbagi koordinat lokasi tugas lapangan secara real-time antar tim patroli/lapangan.

### 4.2 Pelaporan Pajak & SPT Tahunan Terintegrasi
- Ekspor ringkasan bukti potong pajak PPh 21 (Formulir 1721-A1) langsung dari modul Slip Gaji ke format PDF resmi.
- Panduan interaktif pelaporan SPT tahunan untuk karyawan tetap.

---

## 5. Inisiatif Refactoring & Peningkatan Fondasi Teknis

| Inisiatif | Dampak | Target Waktu |
|---|---|---|
| **Audit Pembersihan Hardcoded Colors** | Menghilangkan sisa ~458 instans `Color(0xFF...)` dan memindahkannya ke semantic tokens `AppColors` | Q4 2026 |
| **Dependency Injection via `get_it`** | Menyederhanakan penyediaan repository lintas BLoC tanpa membengkakkan widget tree `MultiRepositoryProvider` | Q1 2027 |
| **Automasi Fastlane Play Store & TestFlight** | Build dan upload otomatis setiap pembuatan Git release tag di CI/CD GitHub Actions | Q4 2026 |
| **Golden UI Tests** | Pengujian regresi visual otomatis untuk mendeteksi pergeseran tata letak pixel pada komponen Stitch M3 | Q2 2027 |

---

> Dokumen terkait:
> - Panduan deploy mobile Android & iOS: [DEPLOYMENT.md](./DEPLOYMENT.md)
> - Arsitektur sistem: [ARCHITECTURE.md](./ARCHITECTURE.md)
> - Checklist verifikasi & perbaikan: [BUG_FIX_CHECKLIST.md](./BUG_FIX_CHECKLIST.md)
