# Share Link Pengajuan ke Atasan (Deep Link)

Pengaju menekan **Bagikan** di halaman detail pengajuan → app membuka halaman **Bagikan ke Atasan** yang memuat
atasan yang berhak approve (dari API). Link dikirim lewat WhatsApp / Email memakai kontak dari data pegawai.
**Salin Link** dan **Bagikan Lainnya** selalu tersedia, juga saat daftar atasan kosong atau gagal dimuat.

Link = URL halaman approval di hris-web. Kalau app terpasang, link membuka app (App Links / Universal Links).
Kalau tidak, link membuka web.

| Modul          | Link web                                                                                              | Route mobile                                    |
| -------------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Cuti           | `/approval/leaves/{id}`                                                                               | `LEAVE_DETAIL?id=&isApprover=true`              |
| Lembur         | `/approval/overtimes/{id}`                                                                            | `OVERTIME_DETAIL?id=&isApprover=true`           |
| Presensi       | `/approval/attendances/{id}`                                                                          | `ATTENDANCE_REQUEST_DETAIL?id=&isApprover=true` |
| Reimbursement  | `/approval/reimbursements/{id}`                                                                       | `REIMBURSEMENT_DETAIL?id=`                      |
| Kasbon         | `/approval/cash-advances/{id}` (web: diarahkan ke `/reimbursement?cashAdvanceId=` dan membuka drawer) | `CASH_ADVANCE_DETAIL?id=`                       |
| Resign         | `/approval/resignation/{id}` (web: diarahkan ke `/approval/resignation`)                              | `RESIGNATION` (tab Persetujuan Tim)             |
| Aktivitas      | `/report/activities/{id}`                                                                             | `ACTIVITY_DETAIL?id=`                           |
| Profil Pegawai | `/employee/{id}` (dan `/employees/{id}`)                                                              | `EMPLOYEE_DETAIL?id=`                           |

Kode mobile: `lib/core/utils/share_link_util.dart`, `lib/features/approver_share/`.
Host web: `ApiEndpoints.webBaseUrl` (override `--dart-define=WEB_BASE_URL=...`), harus sama dengan host di manifest Android
(lihat bagian "Host App Links Android"). Host ditetapkan saat build, bukan per tenant: semua link dari satu build memakai host yang sama.

## Host App Links Android (per build type)

Filter `autoVerify` **tidak** ada di `src/main/AndroidManifest.xml`. Filter ada di manifest per build type, digabung otomatis oleh Gradle:

| Build | File | Host |
|---|---|---|
| debug, profile | `android/app/src/{debug,profile}/AndroidManifest.xml` | `dev.hroasish.com` + `${customHost}` (default `dev.hroasish.com`) |
| release | `android/app/src/release/AndroidManifest.xml` | `app.hroasish.com` + `${customHost}` (default `app.hroasish.com`) |

**Kenapa dipisah per build type.** Android ≤ 11 menganggap paket terverifikasi hanya bila **semua** host ber-`autoVerify` lolos
(status per paket, bukan per filter). Satu host tanpa `assetlinks.json` valid membuat semua host `ask`: link menampilkan dialog
"Chrome atau aplikasi" dan memilih Chrome hanya membuka web (login). Android 12+ memverifikasi per domain, jadi tidak terpengaruh.
Karena itu build debug tidak boleh memuat host prod, dan sebaliknya.
Build **release yang diarahkan ke dev** (APK QA) wajib `--android-project-arg=customHost=dev.hroasish.com` (lihat [DEPLOYMENT.md §4.3](DEPLOYMENT.md#43-build-development-mobile-app-flutter-android)).

**Klien dengan domain custom (white-label)** dan build release yang diarahkan ke dev: perintah build ada di
[DEPLOYMENT.md §5.7](DEPLOYMENT.md#57-build-klien-domain-custom--deep-link-app-links) dan §4.3.
Wildcard `*.hroasish.com` sengaja tidak dipakai: host tidak per tenant dan wildcard butuh `assetlinks.json` di root `hroasish.com`.

## API (muratech_hris_server) — sudah dibuat

`src/modules/approver/` → `GET /api/v1/approvers?module=<leave|overtime|attendance|reimbursement|cash_advance|resignation|activity>&id=<uuid>`

- Daftar atasan memakai `getApproverEmployeeIds` (sama dengan penerima notifikasi pengajuan): atasan langsung,
  admin perusahaan, dan pemegang data scope yang mencakup pengaju, disaring dengan permission modul
  (`approval.leave.action`, `approval.overtime.action`, `approval.attendance.action`, `approval.reimbursement.manager`,
  `resignation.approve_manager`, `report.activity.view`). Pengaju dan pemanggil sendiri tidak ikut.
- `phone`, `email`, jabatan, departemen, perusahaan, `photoUrl` diambil dari master pegawai.
- Hanya pemilik pengajuan atau user yang data scope-nya mencakup pemilik yang boleh memanggil (selain itu `403`), pengajuan tidak ada → `404`.
  Pesan error dua bahasa di `src/core/i18n/{id,en}.ts` (`error.approver.*`).
- Tes: `tests/integration/approver.service.test.ts`.

## Web (hris-web) — sudah dibuat

- `public/.well-known/assetlinks.json` (Android App Links).
- `src/routes/[.]well-known/apple-app-site-association.ts` (iOS Universal Links, `Content-Type: application/json`).
- `approval/cash-advances.$cashAdvanceId.tsx` → `/reimbursement?cashAdvanceId=` (tab Kasbon + drawer detail terbuka).
- `approval/resignation_.$resignationId.tsx` → `/approval/resignation`.
- Belum login → `/login?redirect=<link>` → setelah login kembali ke link (`src/middleware/auth.ts`, `_authenticatedLayout.tsx`).

**Sidik jari Android.** `assetlinks.json` berisi SHA256 debug keystore mesin ini, karena build release saat ini
masih ditandatangani dengan debug key (`android/app/build.gradle.kts`). Kalau rilis lewat Play Store (Play App Signing)
atau memakai keystore release sendiri, tambahkan SHA256-nya ke `sha256_cert_fingerprints`
(Play Console → App integrity, atau `keytool -list -v -keystore <release.jks>`).

## iOS — sudah dipasang

`ios/Runner/Runner.entitlements` (`applinks:app.hroasish.com`, `applinks:dev.hroasish.com`) dan
`CODE_SIGN_ENTITLEMENTS` di 3 konfigurasi Runner. Signing otomatis (Team `3LZG597XJ5`): build pertama dari Xcode
(akun Apple login) akan mendaftarkan capability Associated Domains ke App ID. Untuk build CI/manual signing,
aktifkan Associated Domains di App ID `com.hroasish.app` lalu buat ulang provisioning profile.

## Uji Android

```bash
adb shell am start -a android.intent.action.VIEW -d "https://dev.hroasish.com/approval/leaves/<id>"
adb shell pm get-app-links com.hroasish.app            # Android 12+: harus verified
adb shell dumpsys package domain-preferred-apps         # Android ≤ 11: Status harus "always", bukan "ask"
```

Verifikasi berjalan saat **install**: setelah `assetlinks.json` diperbaiki/dideploy, uninstall lalu install ulang aplikasi.
Tes cepat: perintah `am start` di atas harus langsung membuka `MainActivity` tanpa `ResolverActivity` (dialog pilihan).

**Troubleshooting "pilih Chrome → stuck di web".** Dialog pilihan = link belum terverifikasi. Cek: (1) `curl -i https://<host>/.well-known/assetlinks.json`
harus `200 application/json` (bukan HTML SPA); (2) di Android ≤ 11, semua host di merged manifest harus lolos;
(3) SHA-256 keystore penanda APK ada di `sha256_cert_fingerprints`. Memilih Chrome secara sadar memang hanya membuka web.
