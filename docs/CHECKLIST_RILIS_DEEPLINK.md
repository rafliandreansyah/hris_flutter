# Checklist Rilis Deep Link (Share Pengajuan)

Dokumen ini dipakai setiap kali menyiapkan rilis ke Play Store atau mengubah domain/kunci.
Detail teknis ada di [SHARE_DEEPLINK.md](SHARE_DEEPLINK.md).

> **Jangan tulis password keystore di dokumen ini.** Simpan di password manager tim.

---

## A. Persiapan keystore (sekali saja)

- [ ] Buat upload key release dengan `keytool -genkeypair ...` (perintah ada di chat/SHARE_DEEPLINK.md).
- [ ] Simpan `oasish-release.jks`, alias, dan password di password manager tim.
- [ ] Pastikan `.jks` dan `key.properties` ada di `.gitignore`.
- [ ] Catat SHA-256 upload key: `keytool -list -v -keystore oasish-release.jks -alias oasish`
- [ ] **Belum dikerjakan:** `signingConfigs.release` di `android/app/build.gradle.kts` (sekarang masih pakai debug key).

## B. Sebelum build release

- [ ] `ApiEndpoints.webBaseUrl` untuk release = `https://app.hroasish.com` (sudah benar di kode).
- [ ] `src/release/AndroidManifest.xml`: host `app.hroasish.com` (+ `${customHost}` bila build klien custom: `-PcustomHost=...` dan `WEB_BASE_URL` sama). Lihat SHARE_DEEPLINK.md.
- [ ] `Runner.entitlements`: `applinks:app.hroasish.com` sudah ada (dev juga bila dipakai).
- [ ] Naikkan `version` di `pubspec.yaml`.
- [ ] Build AAB: `flutter build appbundle --release`.

## C. Upload ke Play Console

- [ ] Upload AAB pertama. Pilih **Play App Signing** (default).
- [ ] Buka **Test and release → App integrity → App signing**.
- [ ] Salin **SHA-256 certificate fingerprint** dari **App signing key** (untuk pengguna Play Store).
- [ ] Catat juga SHA-256 **upload key** (untuk APK yang dibagikan langsung, misal ke klien on-premise).
- [ ] Simpan kedua SHA di catatan ini (bukan di chat).

| Kunci | SHA-256 | Sumber |
|---|---|---|
| App signing key (Play) | `<isi nanti>` | Play Console → App integrity |
| Upload key (release) | `<isi nanti>` | `keytool -list -v ...` |

## D. Website hris-web (wajib sebelum tes rilis)

File: `public/.well-known/assetlinks.json`

- [ ] Ganti/isi `sha256_cert_fingerprints` dengan:
  - [ ] SHA app signing key (Play)
  - [ ] SHA upload key (release, opsional jika ada APK langsung)
  - [ ] SHA debug laptop (opsional, hanya untuk testing; boleh dihapus untuk produksi)
- [ ] Pastikan JSON valid (tanpa koma berlebih).
- [ ] Commit dan deploy hris-web ke **app.hroasish.com**.
- [ ] Cek: `curl -i https://app.hroasish.com/.well-known/assetlinks.json` → `200` dan `application/json`.

File: `src/routes/[.]well-known/apple-app-site-association.ts`

- [ ] `appIDs` berisi `3LZG597XJ5.com.hroasish.app` (Team ID dan bundle ID; tidak pakai SHA).
- [ ] Cek: `curl -i https://app.hroasish.com/.well-known/apple-app-site-association` → `200` dan `application/json`.

Domain lain:

- [ ] Bila `dev.hroasish.com` dipakai untuk debug, deploy kedua file verifikasi ke sana juga (sudah live).
- [ ] Host baru di manifest wajib punya `assetlinks.json` valid sebelum rilis; di Android ≤ 11 satu host gagal menjatuhkan semua.

Halaman tujuan link (sudah dibuat, cek setelah deploy):

- [ ] `/approval/leaves/:id`, `/approval/overtimes/:id`, `/approval/attendances/:id`, `/approval/reimbursements/:id` (ada)
- [ ] `/approval/cash-advances/:id` → redirect ke `/reimbursement?cashAdvanceId=` (ada)
- [ ] `/approval/resignation/:id` → redirect ke `/approval/resignation` (ada)
- [ ] `/report/activities/:id` (ada)
- [ ] Belum login → `/login?redirect=<link>` lalu kembali ke link (ada)

## E. Setelah app terpasang dari Play Store

- [ ] Install dari **Internal testing** (atau track yang dipakai).
- [ ] Cek status verifikasi:

  ```bash
  adb shell pm get-app-links com.hroasish.app
  ```

  Harus `verified`. Kalau belum: `adb shell pm verify-app-links --re-verify com.hroasish.app`.

- [ ] Kirim link ke WA sendiri, klik, pastikan langsung masuk app di halaman detail.
- [ ] Tes dengan app belum login: harus ke login lalu kembali ke link.
- [ ] Tes link dari browser (laptop): harus ke web dan login.

## F. iOS (bila sudah dirilis)

- [ ] Aktifkan **Associated Domains** untuk App ID `com.hroasish.app` di Apple Developer.
- [ ] Buat ulang provisioning profile.
- [ ] Build dari Xcode dengan akun Apple yang login (signing otomatis).
- [ ] Tes Universal Link dari WA (bukan copy-paste ke Safari).

---

## Status saat ini

| Item | Status |
|---|---|
| Kode deep link Flutter (Android & iOS) | ✅ Selesai |
| Endpoint API `/approvers` | ✅ Selesai (belum dideploy) |
| File verifikasi di hris-web | ✅ Dibuat, ⏳ belum dideploy |
| Keystore release | ❌ Belum dibuat |
| `signingConfigs.release` | ❌ Belum dibuat |
| SHA app signing key (Play) | ❌ Menunggu upload pertama |
| Host manifest dipisah per build type (dev di debug/profile, prod di release) + `customHost` | ✅ Selesai, dev terverifikasi di Android 10 |
| `assetlinks.json` & AASA di `app.hroasish.com` | ⏳ Masih mengembalikan HTML, perlu deploy |
