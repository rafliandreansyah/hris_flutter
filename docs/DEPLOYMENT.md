# Deployment — OASISH HRIS Mobile App (Flutter)

> **Cakupan**: panduan komprehensif alur build & deployment OASISH HRIS, mencakup **build development/staging** (Docker container backend API `muratech/oasish-api:dev` & APK/IPA Flutter dev untuk QA dogfooding), rilis produksi aplikasi mobile Android dan iOS ke Google Play Store, Apple App Store, internal testing (Play Console Internal & Apple TestFlight), distribusi APK langsung, konfigurasi keystore & provisioning profile, environment variable (`--dart-define`), integrasi Google Maps & Firebase FCM, serta automasi CI/CD.
> **Terakhir diverifikasi terhadap kode**: Oktober 2026 (Flutter 3.x, Dart 3.x, Android Gradle Plugin 8.x, Java JDK 17, iOS 17+, CocoaPods, Docker, Bun).

---

## Daftar Isi

1. [Gambaran & Perbedaan Mendasar Deployment Mobile vs Web/Server](#1-gambaran--perbedaan-mendasar-deployment-mobile-vs-webserver)
2. [Matriks Environment & Variabel Konfigurasi](#2-matriks-environment--variabel-konfigurasi)
3. [Prasyarat Lingkungan Build](#3-prasyarat-lingkungan-build)
4. [Panduan Build & Deployment Lingkungan Development](#4-panduan-build--deployment-lingkungan-development)
   - 4.1 [Mengapa Membutuhkan Build Khusus Development](#41-mengapa-membutuhkan-build-khusus-development)
   - 4.2 [Build Development Backend Server (`muratech_hris_server` / Docker)](#42-build-development-backend-server-muratech_hris_server--docker)
   - 4.3 [Build Development Mobile App (Flutter Android)](#43-build-development-mobile-app-flutter-android)
   - 4.4 [Build Development Mobile App (Flutter iOS)](#44-build-development-mobile-app-flutter-ios)
   - 4.5 [Menghubungkan Mobile Dev Build ke Backend Dev (Skenario Jaringan)](#45-menghubungkan-mobile-dev-build-ke-backend-dev-skenario-jaringan)
   - 4.6 [Kanal Distribusi Biner Development](#46-kanal-distribusi-biner-development)
   - 4.7 [Checklist Verifikasi Sebelum Menyerahkan Build Dev ke QA](#47-checklist-verifikasi-sebelum-menyerahkan-build-dev-ke-qa)
5. [Deployment Android Production (Play Store & Keystore)](#5-deployment-android-production-play-store--keystore)
   - 5.1 [Membuat Release Keystore](#51-membuat-release-keystore)
   - 5.2 [Konfigurasi `key.properties` & `build.gradle.kts`](#52-konfigurasi-keyproperties--buildgradlekts)
   - 5.3 [ProGuard, R8 & Code Obfuscation](#53-proguard-r8--code-obfuscation)
   - 5.4 [Build Android App Bundle (AAB)](#54-build-android-app-bundle-aab)
   - 5.5 [Build Universal APK & Split-per-ABI (Direct Distribution)](#55-build-universal-apk--split-per-abi-direct-distribution)
   - 5.6 [Rilis ke Google Play Console (Internal, Closed, Production)](#56-rilis-ke-google-play-console-internal-closed-production)
6. [Deployment iOS Production (App Store & TestFlight)](#6-deployment-ios-production-app-store--testflight)
   - 6.1 [Sertifikat & Provisioning Profile (Apple Developer)](#61-sertifikat--provisioning-profile-apple-developer)
   - 6.2 [Konfigurasi Runner & Capabilities di Xcode](#62-konfigurasi-runner--capabilities-di-xcode)
   - 6.3 [Build Release Archive (.xcarchive) & IPA](#63-build-release-archive-xcarchive--ipa)
   - 6.4 [Distribusi via Apple TestFlight](#64-distribusi-via-apple-testflight)
   - 6.5 [Rilis ke Apple App Store (Production)](#65-rilis-ke-apple-app-store-production)
7. [Konfigurasi Layanan Eksternal & Kredensial](#7-konfigurasi-layanan-eksternal--kredensial)
   - 7.1 [Firebase Cloud Messaging (FCM) & Google Services](#71-firebase-cloud-messaging-fcm--google-services)
   - 7.2 [Google Maps Mobile SDK (Android & iOS)](#72-google-maps-mobile-sdk-android--ios)
8. [Kepatuhan Kebijakan Privasi & App Review (Store Policy)](#8-kepatuhan-kebijakan-privasi--app-review-store-policy)
   - 8.1 [Izin Lokasi Latar Belakang (Android 14+ Foreground Service)](#81-izin-lokasi-latar-belakang-android-14-foreground-service)
   - 8.2 [Izin Kamera, Biometrik & Galeri](#82-izin-kamera-biometrik--galeri)
   - 8.3 [Akun Demo & Catatan Reviewer (App Review Notes)](#83-akun-demo--catatan-reviewer-app-review-notes)
9. [Automasi CI/CD & Fastlane](#9-automasi-cicd--fastlane)
   - 9.1 [Pipeline CI/CD Build & Distribusi Development (Firebase App Distribution)](#91-pipeline-cicd-build--distribusi-development-firebase-app-distribution)
   - 9.2 [Pipeline CI/CD Production Google Play Store](#92-pipeline-cicd-production-google-play-store)
10. [Troubleshooting & Solusi Kendala Rilis](#10-troubleshooting--solusi-kendala-rilis)

---

## 1. Gambaran & Perbedaan Mendasar Deployment Mobile vs Web/Server

Berbeda dengan `hris-web` dan `muratech_hris_server` yang di-deploy ke server VPS via Docker container dan Nginx reverse proxy, aplikasi mobile **OASISH HRIS** didistribusikan ke perangkat pengguna akhir (karyawan) melalui paket biner terkompilasi (*compiled binaries*) yang ditandatangani secara kriptografis (*digitally signed*):

```mermaid
graph LR
    subgraph Development["1. Sumber Kode"]
        Src["Flutter Source Code<br>(lib/, assets/, android/, ios/)"]
    end

    subgraph Compile["2. Kompilasi & Obfuscation"]
        A_Build["Flutter Build<br>Android (Gradle / R8)"]
        I_Build["Flutter Build<br>iOS (LLVM / Clang / Xcode)"]
    end

    subgraph Signing["3. Kriptografi & Signing"]
        A_Sign["Keystore Signing<br>(upload-keystore.jks)"]
        I_Sign["Apple Distribution Cert<br>+ Provisioning Profile"]
    end

    subgraph Distribution["4. Kanal Distribusi"]
        PlayStore["Google Play Console<br>(Internal / Beta / Prod)"]
        AppStore["Apple App Store<br>(TestFlight / Prod)"]
        DirectAPK["Direct APK Distribution<br>(Klien On-Premise)"]
    end

    Src --> A_Build --> A_Sign --> PlayStore
    A_Sign --> DirectAPK
    Src --> I_Build --> I_Sign --> AppStore
```

### Tabel Komparasi Deployment

| Aspek | Server Backend (`muratech_hris_server`) | Portal Web (`hris-web`) | Mobile App (`hris_flutter`) |
|---|---|---|---|
| **Target Runtime** | Bun + Docker di VPS Linux x86_64 | Bun + Docker di VPS Linux x86_64 | Android OS (API 21+) & iOS (13.0+) |
| **Bentuk Output** | Docker Container Image | Docker Container Image | `.aab` / `.apk` (Android) & `.ipa` (iOS) |
| **Sistem Signing** | Tidak ada (diatur SSL Nginx) | Tidak ada (diatur SSL Nginx) | Android Keystore (`.jks`) & Apple Distribution Certificate |
| **Kanal Rilis** | Docker Compose / Registry | Docker Compose / Registry | Google Play Console & Apple App Store / TestFlight |
| **Review Tim Luar** | Instan (langsung jalan setelah restart) | Instan (langsung jalan setelah restart) | Wajib melewati **App Review** Google & Apple (1–3 hari kerja) |
| **Izin Sistem Operasi** | Port firewall, database privilege | Browser permission prompt | Manifest runtime permissions (GPS, Background, Camera, Face ID) |

---

## 2. Matriks Environment & Variabel Konfigurasi

Aplikasi mobile tidak membaca berkas `.env` saat runtime produksi demi alasan performa dan keamanan. Konfigurasi endpoint diinjeksikan saat waktu kompilasi (*compile-time*) menggunakan flag `--dart-define`.

Logika penentuan host diatur di [`lib/core/constants/api_endpoints.dart`](file:///Users/rafliandreansyah/Documents/Dev/muratech-hris/hris_flutter/lib/core/constants/api_endpoints.dart):

```dart
static String get baseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return kReleaseMode ? _releaseApiBaseUrl : _devApiBaseUrl;
}
```

### Matriks Target API

| Lingkungan | Default Base URL | Kapan Digunakan | Perintah Build Flag |
|---|---|---|---|
| **Development** | `https://apidev.hroasish.com/api/v1` | Otomatis di mode `debug` dan `profile` | *(default)* |
| **Production Multi-Tenant** | `https://api.hroasish.com/api/v1` | Otomatis di mode `release` | *(default saat `--release`)* |
| **Staging / UAT** | `https://api-staging.hroasish.com/api/v1` | Pengujian tim QA sebelum rilis publik | `--dart-define=API_BASE_URL=https://api-staging.hroasish.com/api/v1` |
| **Dedicated Klien (On-Premise)** | `https://api-hris.namaklien.co.id/api/v1` | Build khusus pesanan perusahaan tertentu | `--dart-define=API_BASE_URL=https://api-hris.namaklien.co.id/api/v1` |

---

## 3. Prasyarat Lingkungan Build

Pastikan mesin build (laptop pengembang atau runner CI/CD) memiliki perangkat lunak berikut:

1. **Flutter SDK**: `v3.29.x` atau lebih baru (`flutter --version`).
2. **Dart SDK**: `v3.7.x` atau lebih baru.
3. **Java Development Kit (JDK)**: **JDK 17** (disarankan Azul Zulu JDK 17 atau OpenJDK 17). Android Gradle Plugin 8+ membutuhkan minimal Java 17.
4. **Android SDK & Build Tools**:
   - `compileSdk`: **37**
   - `minSdk`: **21** (Android 5.0 Lollipop)
   - `targetSdk`: **34** / **35** (sesuai regulasi Google Play terbaru)
   - Android Command-line Tools & CMake.
5. **Khusus Build iOS (Wajib macOS)**:
   - macOS Sonoma / Sequoia.
   - **Xcode**: 15.4 / 16.x dengan Command Line Tools aktif.
   - **CocoaPods**: `v1.14.0+` (`sudo gem install cocoapods` atau via Homebrew).
   - Akun berbayar **Apple Developer Program** ($99/tahun).

Verifikasi kesiapan mesin:
```bash
flutter doctor -v
```

---

## 4. Panduan Build & Deployment Lingkungan Development

Sebelum merilis aplikasi ke publik (Google Play Store dan Apple App Store), tim *engineering* dan *Quality Assurance* (QA) memerlukan lingkungan pengujian terisolasi (*staging / development environment*). Bagian ini memandu proses **build biner mobile (Flutter)** dan **build container backend API (`muratech_hris_server`)** khusus untuk tahap *development & dogfooding*.

```mermaid
graph TD
    subgraph Backend_Dev["1. Backend Service (muratech_hris_server)"]
        SrcAPI["Kode Backend<br>(Hono / Bun / Prisma 6)"]
        DockerDev["Build Docker Image<br><code>muratech/oasish-api:dev</code>"]
        VPSDev["Deploy ke VPS / Server Dev<br><code>apidev.hroasish.com:8000</code>"]
        LocalDocker["Container Lokal Docker<br><code>localhost:8000</code>"]
        SrcAPI --> DockerDev
        DockerDev --> VPSDev
        DockerDev --> LocalDocker
    end

    subgraph Mobile_Dev["2. Mobile App (hris_flutter)"]
        SrcMobile["Kode Flutter"]
        BuildDev["Build Dev APK / IPA<br><code>--dart-define=API_BASE_URL=...</code>"]
        DistDev["Distribusi Biner QA<br>(Firebase App Distribution / Sideload ADB)"]
        SrcMobile --> BuildDev --> DistDev
    end

    DistDev -.->|"Uji coba API Dev"| VPSDev
    DistDev -.->|"Uji coba Lokal via ADB Reverse"| LocalDocker
```

### 4.1 Mengapa Membutuhkan Build Khusus Development

1. **Isolasi Data Produksi**: Mencegah data pengujian absensi fiktif, foto selfie demo, cuti eksperimental, dan transaksi finansial mengotori database operasional klien nyata.
2. **Performa Riil Tanpa Lag Debugger**: Menggunakan opsi kompilasi `--release` yang di-override ke API development (`apidev.hroasish.com`) memberikan performa native optimal (60/120 FPS tanpa lag Dart VM) sehingga QA dapat menguji kelancaran animasi dan responsivitas sebenarnya.
3. **Diagnostik Terbuka (Alice HTTP Inspector)**: Pada build non-store, pengembang dapat menyalakan HTTP Inspector (cukup menggoyangkan perangkat) untuk melacak kegagalan response atau payload network secara langsung di layar smartphone.
4. **Validasi Lintasan Cepat (Fast Feedback Loop)**: QA dan tester internal dapat menginstal APK/IPA langsung tanpa harus menunggu masa review 1–3 hari kerja dari Google Play maupun Apple App Store.

---

### 4.2 Build Development Backend Server (`muratech_hris_server` / Docker)

Aplikasi mobile membutuhkan endpoint backend API yang aktif dan kompatibel dengan fitur-fitur terbaru.

#### A. Build Docker Image Development
Jalankan perintah build dari root direktori `muratech_hris_server`:

```bash
# Masuk ke direktori backend server
cd ../muratech_hris_server

# Build Docker image dengan tag khusus development
docker build -t muratech/oasish-api:dev .
```

#### B. Menjalankan Container Backend Dev Secara Mandiri (Docker Run)
Jika menjalankan server development mandiri pada port `8000`:

```bash
docker run -d \
  --name oasish-api-dev \
  -p 8000:8000 \
  --env-file .env.development \
  --restart unless-stopped \
  muratech/oasish-api:dev
```

#### C. Menjalankan dengan Docker Compose (Dev Environment Lengkap)
Untuk menjalankan service backend bersama database PostgreSQL dev dan Redis dev:

```yaml
# docker-compose.dev.yml (di direktori muratech_hris_server)
services:
  api:
    image: muratech/oasish-api:dev
    container_name: oasish-api-dev
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - NODE_ENV=development
      - PORT=8000
      - DATABASE_URL=postgresql://hris_dev:secret123@postgres-dev:5432/hris_dev_db?schema=public
      - JWT_ACCESS_SECRET=dev_jwt_access_secret_super_secure_key_123
      - JWT_REFRESH_SECRET=dev_jwt_refresh_secret_super_secure_key_123
    depends_on:
      - postgres-dev

  postgres-dev:
    image: postgres:16-alpine
    container_name: oasish-postgres-dev
    restart: unless-stopped
    environment:
      POSTGRES_USER: hris_dev
      POSTGRES_PASSWORD: secret123
      POSTGRES_DB: hris_dev_db
    ports:
      - "5433:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data

volumes:
  postgres_dev_data:
```

Jalankan service:
```bash
docker compose -f docker-compose.dev.yml up -d --build
```

#### D. Database Migration & Seed Data Development
Setelah container backend menyala, sinkronkan skema Prisma dan muat data demo:

```bash
# 1. Terapkan migrasi skema database Prisma terbaru ke database dev
docker exec -it oasish-api-dev bunx prisma migrate deploy

# 2. Isi database dengan data demo (Perusahaan, Karyawan, Shift, Hari Libur)
docker exec -it oasish-api-dev bun run seed:dev
```

#### E. Publikasi Image & Deploy ke Server Cloud Development (`apidev.hroasish.com`)
```bash
# Tag dan push ke Container Registry
docker tag muratech/oasish-api:dev registry.hroasish.com/muratech/oasish-api:dev
docker push registry.hroasish.com/muratech/oasish-api:dev

# Di server VPS Development (via SSH):
ssh deployer@apidev.hroasish.com
docker pull registry.hroasish.com/muratech/oasish-api:dev
docker compose -f /opt/oasish/docker-compose.dev.yml up -d --force-recreate
```

Reverse proxy Nginx di VPS development meneruskan trafik HTTPS domain `apidev.hroasish.com` ke container port `8000`.

---

### 4.3 Build Development Mobile App (Flutter Android)

Tersedia beberapa varian build Android untuk lingkungan development tergantung kebutuhan tim:

#### A. Build Release APK targeting Development API (Rekomendasi Utama QA ⭐)
Varian ini dikompilasi dengan optimasi release penuh (60/120 FPS tanpa overhead debug Dart VM), namun endpoint diarahkan ke server development melalui flag `--dart-define`:

```bash
# Bersihkan cache build & ambil dependensi
flutter clean && flutter pub get

# Build Split-per-ABI APK (Ukuran kecil ~18–25 MB per arsitektur)
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://apidev.hroasish.com/api/v1 \
  --dart-define=WEB_BASE_URL=https://dev.hroasish.com \
  --build-name=1.0.0-dev \
  --build-number=101
```

> [!TIP]
> **Otomatisasi Signing pada Dev Build**:
> Sesuai konfigurasi `android/app/build.gradle.kts`, jika berkas `android/key.properties` tidak ditemukan (misalnya di komputer QA atau laptop pengembang), Gradle secara otomatis menggunakan **`debug.keystore`**. Anda tidak memerlukan akses ke release keystore produksi untuk membuat build development!

Berkas output berada di:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` *(Untuk mayoritas smartphone fisik modern)*
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` *(Untuk perangkat Android 32-bit lawas)*
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` *(Untuk Android Emulator)*

#### B. Build Universal APK Development (Satu File Semua Arsitektur)
Jika ingin membagikan 1 berkas APK tunggal kepada seluruh tester tim:
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://apidev.hroasish.com/api/v1 \
  --dart-define=WEB_BASE_URL=https://dev.hroasish.com \
  --build-name=1.0.0-dev \
  --build-number=101
```
Output: `build/app/outputs/flutter-apk/app-release.apk` (~50–60 MB).

#### C. Build Debug APK (Pengujian Cepat Developer Lokal)
Mode debug mengaktifkan Dart VM, logging lengkap, hot-reload hooks, dan Alice inspector secara otomatis:
```bash
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://apidev.hroasish.com/api/v1 \
  --dart-define=WEB_BASE_URL=https://dev.hroasish.com
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`.

#### D. Build Profile APK (Profiling Memori, CPU, & Frame Jank)
Untuk menguji performa dan mendeteksi memory leak di DevTools tanpa jitter mode debug:
```bash
flutter build apk --profile \
  --dart-define=API_BASE_URL=https://apidev.hroasish.com/api/v1 \
  --dart-define=WEB_BASE_URL=https://dev.hroasish.com
```
Output: `build/app/outputs/flutter-apk/app-profile.apk`.

---

### 4.4 Build Development Mobile App (Flutter iOS)

Untuk pengujian di iPhone fisik tim tester, aplikasi harus di-build dengan provisioning profile tipe *Development* atau *Ad-Hoc* (UDID perangkat wajib terdaftar di Apple Developer Portal).

```bash
# 1. Update CocoaPods
cd ios && pod install --repo-update && cd ..

# 2. Build Development IPA
flutter build ipa --development \
  --dart-define=API_BASE_URL=https://apidev.hroasish.com/api/v1 \
  --dart-define=WEB_BASE_URL=https://dev.hroasish.com \
  --build-name=1.0.0-dev \
  --build-number=101
```

Berkas output berada di `build/ios/ipa/hris_flutter.ipa` atau `build/ios/archive/Runner.xcarchive`.
Bagi pengguna macOS, berkas ini dapat langsung di-install ke iPhone via **Apple Configurator**, **Xcode Devices and Simulators** (`Cmd + Shift + 2`), atau tools sideloading internal.

---

### 4.5 Menghubungkan Mobile Dev Build ke Backend Dev (Skenario Jaringan)

Tergantung pada lokasi backend yang sedang diuji, gunakan konfigurasi `--dart-define=API_BASE_URL=...` yang tepat:

| Skenario Pengujian | Parameter `API_BASE_URL` | Konfigurasi Pendukung & Catatan |
|---|---|---|
| **Cloud Dev Server (Paling Umum)** | `https://apidev.hroasish.com/api/v1` | Langsung jalan dari mana saja tanpa kabel, wajib koneksi internet. |
| **Android Emulator ke Localhost Docker** | `http://10.0.2.2:8000/api/v1` | `10.0.2.2` adalah gateway loopback virtual Android Emulator ke host PC. |
| **iOS Simulator ke Localhost Docker** | `http://localhost:8000/api/v1` | Simulator iOS berbagi loopback jaringan langsung dengan macOS host. |
| **Perangkat Fisik via USB (ADB Reverse)** | `http://localhost:8000/api/v1` | Wajib jalankan: `adb reverse tcp:8000 tcp:8000`. HP fisik bisa langsung panggil `localhost:8000`! |
| **Perangkat Fisik via Wi-Fi LAN** | `http://192.168.1.xxx:8000/api/v1` | HP dan laptop wajib tersambung ke Wi-Fi yang sama. Ganti `xxx` dengan IP LAN komputer. |

#### Trik ADB Reverse Proxy (Sangat Membantu Development! 🚀)
Jika ingin menguji perangkat fisik Android langsung ke container backend Docker dev di laptop:
```bash
# Sambungkan HP ke laptop via kabel USB dengan USB Debugging aktif
adb devices

# Teruskan port 8000 HP ke port 8000 laptop
adb reverse tcp:8000 tcp:8000

# Sekarang jalankan / build aplikasi menggunakan localhost:
flutter build apk --debug --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

---

### 4.6 Kanal Distribusi Biner Development

#### A. Firebase App Distribution (Rekomendasi Utama untuk Tim QA)
Kanal terbaik untuk mendistribusikan biner APK/IPA dev secara terpusat dengan notifikasi update in-app:
```bash
# Mengunggah APK ke grup tester QA via Firebase CLI
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  --app "1:XXXXXXXXX:android:XXXXXXXXX" \
  --groups "qa-internal,product-team" \
  --release-notes "Build Development: integrasi approval lembur dan geofencing radius"
```

#### B. Google Play Console — Internal App Sharing
1. Buka [Google Play Console Internal App Sharing](https://play.google.com/console/u/0/internal-app-sharing).
2. Tarik dan lepas berkas `.apk` atau `.aab` hasil build dev.
3. Salin link download dan bagikan ke tester internal (tester dapat mengunduh dan menerima update langsung dari Google Play Store tanpa antrean review).

#### C. Apple TestFlight — Grup Internal Tester
1. Unggah archive iOS via Xcode Organizer atau `xcrun altool`.
2. Di App Store Connect > TestFlight, masukkan ke grup **Internal Testing**.
3. Biner dapat diinstal seketika oleh maksimal 100 anggota tim developer tanpa perlu verifikasi review Apple.

#### D. Sideloading Langsung via ADB
```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

### 4.7 Checklist Verifikasi Sebelum Menyerahkan Build Dev ke QA

Sebelum membagikan file instalasi ke tim QA atau Product Manager, verifikasi checklist berikut:

- [ ] **Base URL Terverifikasi**: Host yang dituju adalah `https://apidev.hroasish.com/api/v1` (bukan production). Periksa log startup atau Alice HTTP Inspector.
- [ ] **Web Share URL Terverifikasi**: Tautan share pengajuan lembur/cuti mengarah ke `https://dev.hroasish.com`.
- [ ] **Akun Demo Berfungsi**: Kredensial tester dev (misal: NIK `EMP-DEV-001` / password demo) dapat login dan menerima token JWT.
- [ ] **Kamera & Geofencing GPS**: Fitur selfie ML Kit dan deteksi radius kantor dapat membaca data lokasi dummy atau koordinat kantor development.
- [ ] **Upload File & S3/MinIO**: Bukti selfie, nota reimbursement, dan lampiran sakit berhasil tersimpan dan dapat dimuat ulang.
- [ ] **Versi & Build Number**: Tertera jelas di halaman Pengaturan/Profil (misal: `v1.0.0-dev (Build 101)`).

---

## 5. Deployment Android Production (Play Store & Keystore)

### 5.1 Membuat Release Keystore

Keystore adalah kunci kriptografis untuk menandatangani berkas APK/AAB. **Jangan pernah menghilangkan berkas keystore ini**, karena jika hilang, aplikasi tidak akan pernah bisa di-update di Google Play Store!

Jalankan perintah ini di terminal (simpan di luar folder git atau pastikan tidak ter-commit):

```bash
keytool -genkey -v -keystore ~/oasish-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias oasish-key
```

Masukkan password aman, nama organisasi, unit, kota, dan kode negara (`ID`).

### 5.2 Konfigurasi `key.properties` & `build.gradle.kts`

1. Buat berkas `android/key.properties` (berkas ini telah diabaikan di `.gitignore`):

```properties
storePassword=PASSWORD_KEYSTORE_ANDA
keyPassword=PASSWORD_KEY_ANDA
keyAlias=oasish-key
storeFile=/Users/username/oasish-release-key.jks
```

> [!CAUTION]
> Jangan pernah meng-commit `key.properties` atau berkas `.jks` ke repositori git publik maupun privat!

2. Konfigurasi `android/app/build.gradle.kts` telah disiapkan untuk membaca `key.properties`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 5.3 ProGuard, R8 & Code Obfuscation

Untuk melindungi kekayaan intelektual kode dan memperkecil ukuran biner, aktifkan obfuscation Flutter dan ProGuard/R8:

1. Buat/perbarui aturan ProGuard di `android/app/proguard-rules.pro`:

```proguard
# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit Face Detection
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# Geolocator & Background Location
-keep class com.baseflow.geolocator.** { *; }
```

### 5.4 Build Android App Bundle (AAB)

Android App Bundle (`.aab`) adalah format **wajib** untuk publikasi di Google Play Store sejak 2021.

```bash
# 1. Bersihkan build lama & dapatkan package terbaru
flutter clean
flutter pub get

# 2. Build AAB Release dengan code shrinking & obfuscation
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/app/outputs/symbols \
  --build-name=1.0.0 \
  --build-number=1
```

Berkas output berada di:
`build/app/outputs/bundle/release/app-release.aab`

> [!TIP]
> Simpan folder `build/app/outputs/symbols` untuk melakukan de-obfuscation stack trace crash log di Google Play Console Vitals.

### 5.5 Build Universal APK & Split-per-ABI (Direct Distribution)

Untuk instalasi langsung tanpa melalui Google Play Store (sideloading, internal testing tim QA, atau distribusi MDM ke perangkat operasional perusahaan):

#### A. Build Split-per-ABI APK (Sangat Direkomendasikan ⭐)
Menghasilkan file APK terpisah per arsitektur CPU dengan ukuran jauh lebih kecil dan hemat kuota (~15–25 MB per file):
```bash
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://api.hroasish.com/api/v1
```

Berkas output di `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` *(Untuk mayoritas smartphone Android modern 64-bit)*
- `app-armeabi-v7a-release.apk` *(Untuk perangkat Android lawas 32-bit)*
- `app-x86_64-release.apk` *(Untuk Android Emulator)*

#### B. Build Universal APK (Satu File Semua Perangkat)
Jika membutuhkan 1 file APK tunggal yang bisa diinstal di perangkat tipe apa saja:
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.hroasish.com/api/v1
```

Berkas output di:
`build/app/outputs/flutter-apk/app-release.apk`

#### C. Build Debug APK (Pengujian Cepat Developer)
```bash
flutter build apk --debug
```

Berkas output di:
`build/app/outputs/flutter-apk/app-debug.apk`

#### D. Cara Pasang ke Perangkat via ADB
```bash
# Untuk perangkat fisik modern:
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Untuk universal:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 5.6 Rilis ke Google Play Console (Internal, Closed, Production)

1. Masuk ke [Google Play Console](https://play.google.com/console).
2. Buat aplikasi baru: **Oasish** (`com.hroasish.app`), Kategori: **Business**.
3. **Internal Testing**:
   - Buka menu **Testing** > **Internal testing**.
   - Buat rilis baru dan unggah berkas `app-release.aab`.
   - Tambahkan email tester tim internal untuk verifikasi fungsional instan (bebas review Google).
4. **Closed Testing (Alpha/Beta)**:
   - Uji coba dengan minimal 20 tester selama 14 hari (kebijakan akun developer Google perorangan).
5. **Production Release**:
   - Promosikan rilis yang telah lolos pengujian ke trek **Production**.
   - Isi deskripsi pembaruan (*What's new* dalam bahasa Indonesia dan Inggris).
   - Kirim untuk ditinjau (*Send for review*). Review memakan waktu 1–3 hari kerja.

---

## 6. Deployment iOS Production (App Store & TestFlight)

### 6.1 Sertifikat & Provisioning Profile (Apple Developer)

Sebelum build iOS release, siapkan aset di [Apple Developer Portal](https://developer.apple.com/account/resources):

1. **App ID**: Buat App ID dengan Bundle Identifier `com.hroasish.app`. Centang Capabilities:
   - *Push Notifications*
   - *Location Updates*
2. **Distribution Certificate**: Buat sertifikat *Apple Distribution* menggunakan CSR dari Mac Keychain.
3. **Provisioning Profile**: Buat profile tipe *App Store Distribution* untuk `com.hroasish.app`.

### 6.2 Konfigurasi Runner & Capabilities di Xcode

Buka folder iOS menggunakan Xcode:
```bash
open ios/Runner.xcworkspace
```

1. Pilih target **Runner** > tab **Signing & Capabilities**.
2. Centang **Automatically manage signing** dan pilih **Team** organisasi Anda.
3. Pastikan Capabilities terpasang:
   - **Background Modes**: centang `Location updates` dan `Background fetch`.
   - **Push Notifications**: aktif.
4. Periksa deskripsi privasi di [`ios/Runner/Info.plist`](file:///Users/rafliandreansyah/Documents/Dev/muratech-hris/hris_flutter/ios/Runner/Info.plist):
   - `NSLocationWhenInUseUsageDescription`
   - `NSLocationAlwaysAndWhenInUseUsageDescription`
   - `NSCameraUsageDescription`
   - `NSPhotoLibraryUsageDescription`
   - `NSFaceIDUsageDescription`

### 6.3 Build Release Archive (.xcarchive) & IPA

```bash
# 1. Bersihkan dan perbarui CocoaPods
cd ios
pod install --repo-update
cd ..

# 2. Build IPA release
flutter build ipa --release \
  --obfuscate --split-debug-info=build/ios/symbols \
  --build-name=1.0.0 \
  --build-number=1
```

Output direktori:
`build/ios/archive/Runner.xcarchive` dan `build/ios/ipa/hris_flutter.ipa`.

### 6.4 Distribusi via Apple TestFlight

TestFlight adalah kanal resmi Apple untuk pengujian aplikasi sebelum tayang di App Store:

1. **Upload Biner**:
   - Cara A (Xcode): Buka Xcode > **Window** > **Organizer** > Pilih Archive > Klik **Distribute App** > Pilih **App Store Connect** > **Upload**.
   - Cara B (CLI `altool`):
     ```bash
     xcrun altool --upload-app -f build/ios/ipa/*.ipa \
       -t ios -u "EMAIL_APPLE_ID" -p "APP_SPECIFIC_PASSWORD"
     ```
2. Buka [App Store Connect](https://appstoreconnect.apple.com) > menu **TestFlight**.
3. Tambahkan grup **Internal Testing** (akses langsung tanpa review Apple) atau **External Testing** (memerlukan review singkat 1–12 jam).

### 6.5 Rilis ke Apple App Store (Production)

1. Di App Store Connect, buat versi baru (misal `1.0.0`).
2. Pilih build TestFlight yang telah terverifikasi stabil.
3. Isi kelengkapan toko:
   - **Screenshots**: iPhone 6.7" (iPhone 15 Pro Max) dan 6.5" (iPhone 11 Pro Max / XS Max).
   - **Deskripsi & Keywords**: Aplikasi absensi, manajemen HR, slip gaji karyawan.
   - **URL Kebijakan Privasi**: `https://oasish.id/privacy-policy` (wajib HTTPS aktif).
   - **URL Dukungan Teknis**: `https://oasish.id/support`.
4. Klik **Submit for Review**.

---

## 7. Konfigurasi Layanan Eksternal & Kredensial

### 7.1 Firebase Cloud Messaging (FCM) & Google Services

Notifikasi push ditangani oleh Firebase Admin di server dan diterima oleh `firebase_messaging` di Flutter:

1. **Android**:
   - Berkas [`android/app/google-services.json`](file:///Users/rafliandreansyah/Documents/Dev/muratech-hris/hris_flutter/android/app/google-services.json) wajib berada di direktori `android/app/`.
   - **Wajib Daftarkan SHA-1 & SHA-256**:
     Dapatkan fingerprint release keystore:
     ```bash
     keytool -list -v -keystore ~/oasish-release-key.jks -alias oasish-key
     ```
     Daftarkan SHA-1 dan SHA-256 tersebut ke Firebase Console > Project Settings > Your Android App. Jika memakai **Google Play App Signing**, salin juga SHA-1 dari dashboard Play Console (App Signing Key Certificate).
2. **iOS**:
   - Letakkan `GoogleService-Info.plist` di `ios/Runner/`.
   - Unggah **Apple Push Notifications key (.p8)** ke Firebase Console > Project Settings > Cloud Messaging > Apple app configuration.

### 7.2 Google Maps Mobile SDK (Android & iOS)

Aplikasi membutuhkan Google Maps SDK untuk menampilkan geofence kantor dan peta presensi:

1. **Android API Key**:
   Telah didaftarkan di [`android/app/src/main/AndroidManifest.xml`](file:///Users/rafliandreansyah/Documents/Dev/muratech-hris/hris_flutter/android/app/src/main/AndroidManifest.xml):
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyAxluVQ5yX2bwyqDMxXRP066Q5xgxk83vQ"/>
   ```
   > [!IMPORTANT]
   > Di Google Cloud Console, kunci API ini **wajib dibatasi (Restrict Key)**:
   > - Application restrictions: *Android apps* -> Package name: `com.hroasish.app` + SHA-1 Fingerprint release keystore.
   > - API restrictions: *Maps SDK for Android*.
2. **iOS API Key**:
   Didaftarkan di [`lib/app/config/maps_config.dart`](file:///Users/rafliandreansyah/Documents/Dev/muratech-hris/hris_flutter/lib/app/config/maps_config.dart) dan `AppDelegate.swift`. Batasi kunci ke Bundle ID `com.hroasish.app` dan *Maps SDK for iOS*.

---

## 8. Kepatuhan Kebijakan Privasi & App Review (Store Policy)

Kebijakan Google Play dan Apple App Store sangat ketat terhadap aplikasi enterprise yang mengakses lokasi dan biometrik. Ikuti panduan ini agar terhindar dari penolakan (*rejection*):

### 8.1 Izin Lokasi Latar Belakang (Android 14+ Foreground Service)

Aplikasi OASISH HRIS menggunakan pelacakan latar belakang untuk fitur aktivitas lapangan dan pemantauan presensi jam kerja:

1. **Prominent Disclosure**:
   Sebelum meminta izin lokasi latar belakang, aplikasi memunculkan dialog persetujuan eksplisit (`AppDialogUtil.showPermissionDialog` via `PermissionUtil`) yang menjelaskan:
   - *Kenapa* lokasi dibutuhkan saat layar mati (pencatatan koordinat rute dinas).
   - Bahwa data tidak dijual ke pihak ketiga.
2. **Android 14+ Foreground Service Policy**:
   Di Android 14 (API 34+), service lokasi wajib menyertakan tipe service di manifest:
   ```xml
   <service
       android:name="com.baseflow.geolocator.GeolocatorLocationService"
       android:foregroundServiceType="location"
       android:exported="false" />
   ```
3. **Deklarasi Deklarasi Akses Lokasi di Google Play Console**:
   Saat submit ke Play Store, Google akan meminta rekaman video demo penggunaan. Buat video pendek berdurasi 30–60 detik yang memperlihatkan:
   - Munculnya dialog *Prominent Disclosure*.
   - Karyawan memulai tugas lapangan.
   - Aplikasi beralih ke latar belakang, dan notifikasi persisten status pelacakan muncul di notification shade.

### 8.2 Izin Kamera, Biometrik & Galeri

1. **Kamera & Biometrik**: Digunakan untuk verifikasi kehadiran wajah (Face Recognition dengan ML Kit) dan selfie bukti kegiatan.
2. **Apple Guideline 5.1.1 (Data Collection)**: Teks string pada `NSCameraUsageDescription` dan `NSFaceIDUsageDescription` di `Info.plist` tidak boleh generik ("Aplikasi butuh kamera"). Harus spesifik ("Aplikasi memerlukan akses kamera untuk mengambil foto profil, bukti kegiatan lapangan, dan verifikasi absensi biometrik").

### 8.3 Akun Demo & Catatan Reviewer (App Review Notes)

Sediakan akun pengujian khusus untuk tim reviewer Google dan Apple di menu **App Review Information**:

- **Username / Email**: `reviewer@oasish.id`
- **Password**: `ReviewerSecure2026!`
- **Catatan untuk Reviewer**:
  > *"This app is an enterprise HRIS and Employee Self Service portal for internal company employees. The demo credentials provide access to a staging company profile where reviewers can test Attendance Clock In (with camera & GPS geofencing simulation), Leave Requests, and Task Activity feeds. All test data can be freely submitted and approved."*

---

## 9. Automasi CI/CD & Fastlane

Otomatisasi pengujian, build, dan distribusi aplikasi menggunakan GitHub Actions.

### 9.1 Pipeline CI/CD Build & Distribusi Development (Firebase App Distribution)

Workflow ini otomatis aktif setiap kali ada push atau PR merge ke branch `develop`:

```yaml
# .github/workflows/deploy-dev.yml
name: Deploy Development (QA)

on:
  push:
    branches:
      - develop

jobs:
  build-and-distribute-dev:
    name: Build & Distribute Dev APK
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.29.x'
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        run: flutter pub get

      - name: Run Unit & BLoC Tests
        run: flutter test

      - name: Build Split-per-ABI APK (Target Dev API)
        run: |
          flutter build apk --release --split-per-abi \
            --dart-define=API_BASE_URL=https://apidev.hroasish.com/api/v1 \
            --dart-define=WEB_BASE_URL=https://dev.hroasish.com \
            --build-name=1.0.0-dev \
            --build-number=${{ github.run_number }}

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_ANDROID_APP_ID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_CREDENTIALS }}
          groups: qa-team,developers
          file: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
          releaseNotes: |
            Build Dev otomatis dari commit ${{ github.sha }}
            Pesan commit: ${{ github.event.head_commit.message }}
```

### 9.2 Pipeline CI/CD Production Google Play Store

Workflow ini aktif saat pembuatan tag rilis produksi (`v*`):

```yaml
# .github/workflows/deploy-mobile.yml
name: Deploy Mobile Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    name: Build & Release Android AAB
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.29.x'
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        run: flutter pub get

      - name: Decode Keystore & Key Properties
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          KEY_PROPERTIES: ${{ secrets.ANDROID_KEY_PROPERTIES }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > ~/oasish-release-key.jks
          echo "$KEY_PROPERTIES" > android/key.properties

      - name: Build App Bundle
        run: |
          flutter build appbundle --release \
            --dart-define=API_BASE_URL=https://api.hroasish.com/api/v1

      - name: Upload to Google Play Internal
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON_KEY }}
          packageName: com.hroasish.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
```

---

## 10. Troubleshooting & Solusi Kendala Rilis

### 1. Error: `Execution failed for task ':app:desugarDebugFileDependencies'`
- **Penyebab**: Android Gradle Plugin membutuhkan pustaka desugaring modern untuk mendukung API Java 17 di Android versi lama.
- **Solusi**: Pastikan `isCoreLibraryDesugaringEnabled = true` dan `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` aktif di `android/app/build.gradle.kts`.

### 2. Error: `Google Play Android App Signing mismatch`
- **Penyebab**: SHA-1 di Firebase Console berbeda dengan SHA-1 dari Google Play App Signing (Google mengganti kunci signing saat AAB diunggah).
- **Solusi**: Buka Google Play Console > **Release** > **Setup** > **App Integrity** > Salin SHA-1 dan SHA-256 dari **App signing key certificate**, lalu tambahkan ke Firebase Console.

### 3. Error CocoaPods pada macOS Apple Silicon: `Specs satisfying dependencies were not found`
- **Penyebab**: Cache CocoaPods usang atau arsitektur arsitektur gem bentrok.
- **Solusi**:
  ```bash
  cd ios
  rm -rf Podfile.lock Pods
  pod cache clean --all
  pod install --repo-update
  cd ..
  ```

### 4. Apple Rejection: `Guideline 2.1 - Information Needed (Location tracking in background)`
- **Penyebab**: Apple meminta klarifikasi mengapa aplikasi memerlukan izin `location` di `UIBackgroundModes`.
- **Solusi**: Balas pesan resolver dengan menyertakan dokumentasi teknis [`LOCATION_TRACKING.md`](./LOCATION_TRACKING.md) dan jelaskan bahwa fitur background tracking hanya aktif ketika karyawan secara sadar mengklik tombol "Mulai Aktivitas Lapangan" dan otomatis mati setelah jam shift kerja usai.

---

> Dokumen terkait:
> - Penjelasan teknis arsitektur aplikasi: [ARCHITECTURE.md](./ARCHITECTURE.md)
> - Panduan setup mesin pengembang lokal: [ONBOARDING.md](./ONBOARDING.md)
> - Pengujian otomatis unit & E2E: [TESTING.md](./TESTING.md)
> - Spesifikasi pelacakan lokasi latar belakang: [LOCATION_TRACKING.md](./LOCATION_TRACKING.md)
