# Handoff — Yang Belum Selesai

Catatan untuk melanjutkan di perangkat lain. Status per akhir sesi: `flutter analyze` 0 isu,
`flutter test` **1642 lulus**; server `bun test tests/unit tests/integration` **673 lulus**.
**Semua perubahan (Flutter + server) belum di-commit.**

## 0. Wajib dulu di perangkat baru
1. Commit & push **dua repo** agar perubahan ikut terbawa:
   - `D:\Belajar\Flutter\hris_flutter` (branch `dev`)
   - `D:\Belajar\Web\muratech_hris_server` (perubahan refresh token, belum di-commit)
2. Server: `bun install` → `bunx prisma generate` → **`bun run db:push`** (membuat tabel `refresh_tokens`).
3. Flutter: `flutter pub get` (ada dev dependency baru `fake_async`).

## 1. Refresh token

### Sudah dikerjakan
- **Server** (`muratech_hris_server`):
  - Model `RefreshToken` (hash SHA-256, rotasi, `familyId`, deteksi reuse) di `prisma/schema.prisma`.
  - `POST /auth/refresh`; login mengembalikan `refreshToken` + `refreshTokenExpiresAt`;
    logout & konfirmasi reset password mencabut semua refresh token.
  - Config `JWT_REFRESH_EXPIRES_IN` (bawaan `90d`), rate limiter `refreshTokenRateLimiter`,
    util `src/utils/refreshToken.ts`, docs `AUTHORIZATION.md` & `DEPLOYMENT.md`,
    test `tests/integration/auth.refreshToken.test.ts` (13 test).
- **Flutter**:
  - `lib/core/network/token_refresher.dart` (single-flight, hasil `success/rejected/unavailable`).
  - `AuthInterceptor`: 401 → refresh → ulang request sekali (FormData di-clone); logout hanya bila refresh
    ditolak; gangguan jaringan/5xx tidak memaksa logout.
  - Login menyimpan `refreshToken`; `AuthRepository.refreshSession()`; startup memakai refresh bila JWT habis;
    `logout(notifyServer: true)` memanggil `POST /auth/logout` (best-effort) pada logout oleh pengguna.
  - Test: `test/core/network/token_refresh_flow_test.dart` (alur 401 end-to-end dengan Dio + fake adapter).

### Belum
- [ ] **Uji nyata ke server dev** setelah `db:push` + deploy: login → tunggu/ubah `JWT_EXPIRES_IN` pendek (mis. `2m`)
      → pastikan request otomatis lolos tanpa logout; cek refresh token dirotasi (token lama ditolak).
- [ ] Test Flutter yang belum ditulis (mock sudah diperbarui, tetapi belum ada kasus uji):
  - `AuthRepositoryImpl.login` menyimpan `refreshToken` (cek `savedRefreshToken` di `auth_repository_test.dart`).
  - `AuthRepositoryImpl.refreshSession()` (sukses → token baru; gagal → `null`) — perlu `_MockApiClient.refreshAccessToken`.
  - `AuthRepositoryImpl.logout(notifyServer: true)` memanggil remote logout; error remote tidak menghalangi logout lokal.
  - `AuthBloc`: JWT kedaluwarsa + `refreshSession()` berhasil → `AuthSuccess`; gagal → logout + `AuthInitial`.
  - `LoginResponseData.fromJson/toJson` dengan & tanpa `refreshToken` (`login_models_test.dart`).
- [ ] Setelah server terdeploy: pertimbangkan memperpendek `JWT_EXPIRES_IN` (mis. `1h`) di `.env` produksi.
- [ ] Pertimbangkan membersihkan refresh token di job deprovisioning resign
      (`src/cron/jobs/resignationDeprovisioning.job.ts`; saat ini sudah tertolak lewat cek status akun, tetapi baris tidak dicabut).
- [ ] Perilaku baru yang perlu dikonfirmasi: **logout oleh pengguna kini memanggil `/auth/logout`**
      (melepas pendaftaran perangkat di server + mencabut refresh token). Sebelumnya app hanya logout lokal.

## 2. Fitur istirahat (break)
- Sudah: API start/end/today, bottom sheet konfirmasi, timer & sisa jatah, riwayat sesi hari ini, tombol multi-sesi,
  peringatan saat clock-out ketika istirahat berjalan, test unit/bloc/widget.
- [ ] **Belum dicoba di perangkat/emulator** (GPS, izin lokasi, header `x-is-mock` server menolak Fake GPS).
- [ ] **Riwayat istirahat hari lalu**: backend belum menyertakan `breaks`/`totalBreakMinutes`/`overbreakMinutes`
      pada detail/log presensi. Perlu perubahan server lalu tampilkan di `attendance_detail_screen`.
- [ ] Tambah skenario E2E istirahat di `integration_test/attendance_e2e_test.dart` (sengaja belum, karena mengubah data nyata).

## 3. Resign (approval atasan & exit interview)
- Sudah: approve/reject 1-on-1, exit interview (sheet + bloc + data layer + test).
- [ ] Halaman detail berkas/timeline khusus (tombol "Lihat Detail Berkas & Timeline" dihapus karena placeholder;
      timeline sudah tampil di halaman utama).
- [ ] Ambil detail pengajuan bawahan lewat `GET /resignations/subordinates/{id}` bila perlu data lebih lengkap di sheet review.
- [ ] Opsi "lewati" exit interview (`ExitInterviewRequestModel.skipped()` sudah ada, belum ada tombol di UI —
      tergantung kebijakan `isExitInterviewMandatory` dari server).

## 4. Reset password
- Sudah memanggil `POST /auth/reset-password` (`PasswordResetRepository`).
- [ ] Layar masih memakai `setState` untuk status loading (AGENTS.md meminta BLoC) → pindahkan ke Cubit/Bloc.
- [ ] Layar **konfirmasi reset** (token + password baru → `POST /auth/reset-password/confirm`) belum ada.

## 5. E2E (Patrol)
- Sudah ditulis ulang di atas `integration_test/helpers/e2e_helpers.dart`, **belum pernah dijalankan di emulator/perangkat**
  — finder/teks mungkin perlu disesuaikan saat pertama jalan.
- [ ] Jalankan: `patrol test --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...`
- [ ] **Ganti password** akun E2E lama (pernah tertulis di file test & docs; sudah dihapus dari repo, tapi ada di riwayat git).
- [ ] Alur yang belum tercakup: submit form (cuti, lembur, klaim, resign, aktivitas, aset, SP), approve/reject 2 peran,
      clock-in/out (kamera + GPS), logout/sesi habis, search/pagination.

## 6. Kualitas test
- [ ] Beberapa test masih memanggil **jaringan nyata** (`apidev.hroasish.com`): `activity_screen_test` (filter sheet),
      `dashboard_screen_test` (notifikasi, onboarding), `live_attendance_screen_test`, `schedule_attendance_screen_test`.
      Inject repository/Bloc fake agar deterministik (contoh: `test/helpers/fake_lifecycle_repository.dart`).
- [ ] AGENTS.md mewajibkan `bloc_test`, tetapi paket itu belum ada di `pubspec.yaml` (test memakai mock manual) —
      putuskan: tambah `bloc_test` atau ubah aturan.
- [ ] ~80 widget kecil belum punya test langsung (kartu detail attendance/leave/overtime, modal asset, filter sheet per fitur,
      `employee_info_card`, `app_realtime_map_card`).
- [ ] Test data layer yang masih lemah: repository activity/announcement/asset/notification/reimbursement/tracking/warning_letter
      hanya menghitung panggilan (belum menangkap argumen); `disburseCashAdvance` belum diuji.

## 7. Lain-lain
- [ ] `create_asset_screen` masih memakai `SnackBar` mentah untuk validasi (AGENTS.md #10).
- [ ] `AppNameVersionText` memanggil `PackageInfo.fromPlatform()` di `build` (dipanggil ulang tiap rebuild).
- [ ] Dua widget peta (`live_tracking_screen`) memakai flag `isTest` di kode produksi — pertimbangkan menggantinya
      dengan injeksi dependensi peta.
