# Checklist Kualitas, Audit Edge-Case & Perbaikan Bug — OASISH HRIS Mobile App (Flutter)

> **Cakupan**: checklist komprehensif audit mutu kode, kepatuhan arsitektur BLoC & Clean Architecture, penanganan edge-case perangkat keras mobile (GPS, Fake GPS, Kamera, Biometrik, Baterai, Izin OS), audit token & sesi latar belakang, serta daftar perbaikan terbuka.
> **Terakhir diperbarui**: Oktober 2026.

---

## 1. Audit Kepatuhan Izin Perangkat (Android 14+ & iOS 17+)

- [ ] **Alur Prominent Disclosure**: Pastikan `AppDialogUtil.showPermissionDialog` selalu muncul sebelum dialog perizinan native OS dipanggil untuk izin Lokasi, Kamera, dan Notifikasi.
- [ ] **Penolakan Permanen (*Permanently Denied*)**: Ketika user memilih "Don't ask again", dialog harus memberikan tombol "Buka Pengaturan" (`openAppSettings()`) dan tidak boleh menutup aplikasi secara kasar.
- [ ] **Android 14 Foreground Service (Location)**: Pastikan tipe `foregroundServiceType="location"` dideklarasikan dengan benar di `AndroidManifest.xml` dan service berhenti saat sesi jam kerja / aktivitas selesai.
- [ ] **iOS Background Modes**: Pastikan `location` dan `fetch` diaktifkan di `Info.plist` dan deskripsi `NSLocationAlwaysAndWhenInUseUsageDescription` menjelaskan alasan operasional bisnis secara jelas.

---

## 2. Audit Integritas GPS & Anti-Kecurangan (Anti-Spoofing)

- [ ] **Deteksi Mock Location / Fake GPS**:
  - [x] Verifikasi atribut `position.isMocked` di `lib/features/attendance/data/datasources/` dan `lib/core/services/geolocator_service.dart`.
  - [ ] Pastikan ketika `isMocked == true`, aplikasi memblokir tombol Clock In/Out dan menampilkan dialog kesalahan `AppDialogUtil.showError(context, message: 'Terdeteksi penggunaan Fake GPS / Lokasi Palsu. Harap nonaktifkan mock location pada pengaturan pengembang perangkat Anda.')`.
  - [ ] Pastikan payload `is_mocked: true` dikirimkan ke server untuk pencatatan di audit log keamanan.
- [ ] **Drift & Akurasi GPS**:
  - [ ] Tolak presensi jika nilai akurasi GPS (`accuracy`) lebih besar dari 100 meter (sinyal satelit tidak akurat / berada di dalam gedung tebal). Berikan instruksi kepada pengguna untuk melangkah mendekati jendela atau area terbuka.

---

## 3. Audit Siklus Kamera, Biometrik & Lifecycle

- [ ] **Pembersihan Kontroller Kamera (*Dispose Safety*)**:
  - [ ] Pastikan `CameraController.dispose()` selalu dipanggil di blok `dispose()` halaman presensi untuk mencegah kebocoran memori RAM kamera native (*hardware camera lock*).
- [ ] **Pemberian Waktu Jeda Deteksi Wajah (ML Kit)**:
  - [ ] Pastikan pemrosesan stream gambar `camera.startImageStream()` di-throttle (maksimal 2–3 frame per detik) agar CPU ponsel tidak mengalami panas berlebih (*throttling*) dan menguras daya baterai.
- [ ] **Pergantian Aplikasi (*App Lifecycle State*)**:
  - [ ] Pastikan saat aplikasi beralih ke background (`AppLifecycleState.paused`), stream kamera dihentikan sementara, dan diaktifkan kembali saat `resumed`.

---

## 4. Audit Ketahanan Jaringan & Siklus Sesi (Network & Session Resilience)

- [ ] **Rotasi Refresh Token Nyata**:
  - [ ] Uji skenario access token kedaluwarsa saat aplikasi berada di background selama 1 jam: saat dibuka kembali, pastikan `AuthInterceptor` melakukan silent refresh ke `POST /auth/refresh` secara mulus tanpa mengganggu alur pengguna.
- [ ] **Penanganan Status HTTP 409 Conflict**:
  - [ ] Pada pengajuan yang bentrok (misal: pengajuan cuti di tanggal yang sama dengan jadwal dinas), pastikan pesan error `409` diekstrak dari `ApiException.message` dan ditampilkan rapi di dialog.
- [ ] **Penanganan Timeout & Sambungan Terputus**:
  - [ ] Pastikan ketika koneksi Wi-Fi/Data mati saat mengunggah foto struk klaim atau slip gaji, tombol aksi mengembalikan status `isLoading: false` dan menampilkan pesan kesalahan jaringan yang dapat dicoba kembali (*Retry*).

---

## 5. Audit Keyboard Handling & Layout Overflow

- [ ] **Dilarang Ada *Bottom Overflowed by X Pixels***:
  - [x] Seluruh form input dibungkus `SingleChildScrollView` dengan `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
  - [x] Seluruh field input teks memiliki handler `onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus()`.
  - [x] Tombol aksi utama form ditempatkan di `Scaffold.bottomNavigationBar` dengan `SafeArea(top: false)`, sehingga tetap berada di bagian bawah layar tanpa melompat ke atas keyboard saat pengguna mengetik.

---

## 6. Audit Konsistensi Desain (Stitch M3 "Teal Oasis")

- [ ] **Pembersihan Warna Hardcoded**:
  - [ ] Migrasi sisa instans `Color(0xFF...)` di 86 file ke semantic tokens resmi di `lib/app/config/app_colors.dart`.
- [ ] **Standardisasi Komponen Global**:
  - [x] Seluruh profil pengaju dan pejabat penyetuju di layar detail transaksi wajib menggunakan kartu standar **`EmployeeInfoRow`**.
  - [x] Seluruh filter pengajuan wajib menggunakan **`AppRequestFilterBottomSheet`**.
  - [x] Seluruh input pencarian wajib menggunakan **`AppSearchBar`**.
  - [x] Seluruh indikator wajib asterik merah `*` menggunakan `AppColors.errorRed`.

---

## 7. Status Pengujian & Quality Gate

- [ ] **Analisis Statis**: Jalankan `flutter analyze` dan pastikan 0 error / warning.
- [ ] **Unit & Widget Test**: Jalankan `flutter test` dan pastikan 220+ file tes lulus 100%.
- [ ] **Pengujian E2E di Emulator/Perangkat Nyata**:
  - [ ] Jalankan bundle Patrol: `patrol test -t integration_test/test_bundle.dart`.

---

> Dokumen terkait:
> - Panduan deploy mobile: [DEPLOYMENT.md](./DEPLOYMENT.md)
> - Panduan arsitektur sistem: [ARCHITECTURE.md](./ARCHITECTURE.md)
> - Pengujian sistem & skenario E2E: [TESTING.md](./TESTING.md)
