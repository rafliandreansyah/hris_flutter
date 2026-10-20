# Share Link Pengajuan ke Atasan (Deep Link)

Pengaju menekan **Bagikan** di halaman detail pengajuan → app membuka halaman **Bagikan ke Atasan** yang memuat
atasan yang berhak approve (dari API). Link dikirim lewat WhatsApp / Email memakai kontak dari data pegawai.
**Salin Link** dan **Bagikan Lainnya** selalu tersedia, juga saat daftar atasan kosong atau gagal dimuat.

Link = URL halaman approval di hris-web. Kalau app terpasang, link membuka app (App Links / Universal Links).
Kalau tidak, link membuka web.

| Modul         | Link web                                                                                              | Route mobile                                    |
| ------------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Cuti          | `/approval/leaves/{id}`                                                                               | `LEAVE_DETAIL?id=&isApprover=true`              |
| Lembur        | `/approval/overtimes/{id}`                                                                            | `OVERTIME_DETAIL?id=&isApprover=true`           |
| Presensi      | `/approval/attendances/{id}`                                                                          | `ATTENDANCE_REQUEST_DETAIL?id=&isApprover=true` |
| Reimbursement | `/approval/reimbursements/{id}`                                                                       | `REIMBURSEMENT_DETAIL?id=`                      |
| Kasbon        | `/approval/cash-advances/{id}` (web: diarahkan ke `/reimbursement?cashAdvanceId=` dan membuka drawer) | `CASH_ADVANCE_DETAIL?id=`                       |
| Resign        | `/approval/resignation/{id}` (web: diarahkan ke `/approval/resignation`)                              | `RESIGNATION` (tab Persetujuan Tim)             |
| Aktivitas     | `/report/activities/{id}`                                                                             | `ACTIVITY_DETAIL?id=`                           |

Kode mobile: `lib/core/utils/share_link_util.dart`, `lib/features/approver_share/`.
Host web: `ApiEndpoints.webBaseUrl` (override `--dart-define=WEB_BASE_URL=...`), harus sama dengan host di `AndroidManifest.xml`.

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
adb shell pm get-app-links com.hroasish.app
```
