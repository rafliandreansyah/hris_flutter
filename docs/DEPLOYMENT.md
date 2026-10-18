# Deployment — OASISH HRIS Mobile App (Flutter)

> **Cakupan**: panduan komprehensif rilis aplikasi mobile Android dan iOS ke Google Play Store, Apple App Store, internal testing (Play Console Internal & Apple TestFlight), distribusi APK langsung untuk klien on-premise, konfigurasi keystore & provisioning profile, environment variable (`--dart-define`), integrasi Google Maps & Firebase FCM, serta automasi CI/CD.
> **Terakhir diverifikasi terhadap kode**: Oktober 2026 (Flutter 3.x, Dart 3.x, Android Gradle Plugin 8.x, Java JDK 17, iOS 17+, CocoaPods).

---

## Daftar Isi

1. [Gambaran & Perbedaan Mendasar Deployment Mobile vs Web/Server](#1-gambaran--perbedaan-mendasar-deployment-mobile-vs-webserver)
2. [Matriks Environment & Variabel Konfigurasi](#2-matriks-environment--variabel-konfigurasi)
3. [Prasyarat Lingkungan Build](#3-prasyarat-lingkungan-build)
4. [Deployment Android](#4-deployment-android)
   - 4.1 [Membuat Release Keystore](#41-membuat-release-keystore)
   - 4.2 [Konfigurasi `key.properties` & `build.gradle.kts`](#42-konfigurasi-keyproperties--buildgradlekts)
   - 4.3 [ProGuard, R8 & Code Obfuscation](#43-proguard-r8--code-obfuscation)
   - 4.4 [Build Android App Bundle (AAB)](#44-build-android-app-bundle-aab)
   - 4.5 [Build Universal APK & Split-per-ABI (Direct Distribution)](#45-build-universal-apk--split-per-abi-direct-distribution)
   - 4.6 [Rilis ke Google Play Console (Internal, Closed, Production)](#46-rilis-ke-google-play-console-internal-closed-production)
5. [Deployment iOS](#5-deployment-ios)
   - 5.1 [Sertifikat & Provisioning Profile (Apple Developer)](#51-sertifikat--provisioning-profile-apple-developer)
   - 5.2 [Konfigurasi Runner & Capabilities di Xcode](#52-konfigurasi-runner--capabilities-di-xcode)
   - 5.3 [Build Release Archive (.xcarchive)](#53-build-release-archive-xcarchive)
   - 5.4 [Distribusi via Apple TestFlight](#54-distribusi-via-apple-testflight)
   - 5.5 [Rilis ke Apple App Store (Production)](#55-rilis-ke-apple-app-store-production)
6. [Konfigurasi Layanan Eksternal & Kredensial](#6-konfigurasi-layanan-eksternal--kredensial)
   - 6.1 [Firebase Cloud Messaging (FCM) & Google Services](#61-firebase-cloud-messaging-fcm--google-services)
   - 6.2 [Google Maps Mobile SDK (Android & iOS)](#62-google-maps-mobile-sdk-android--ios)
7. [Kepatuhan Kebijakan Privasi & App Review (Store Policy)](#7-kepatuhan-kebijakan-privasi--app-review-store-policy)
   - 7.1 [Izin Lokasi Latar Belakang (Android 14+ Foreground Service)](#71-izin-lokasi-latar-belakang-android-14-foreground-service)
   - 7.2 [Izin Kamera, Biometrik & Galeri](#72-izin-kamera-biometrik--galeri)
   - 7.3 [Akun Demo & Catatan Reviewer (App Review Notes)](#73-akun-demo--catatan-reviewer-app-review-notes)
8. [Automasi CI/CD & Fastlane](#8-automasi-cicd--fastlane)
9. [Troubleshooting & Solusi Kendala Rilis](#9-troubleshooting--solusi-kendala-rilis)

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

## 4. Deployment Android

### 4.1 Membuat Release Keystore

Keystore adalah kunci kriptografis untuk menandatangani berkas APK/AAB. **Jangan pernah menghilangkan berkas keystore ini**, karena jika hilang, aplikasi tidak akan pernah bisa di-update di Google Play Store!

Jalankan perintah ini di terminal (simpan di luar folder git atau pastikan tidak ter-commit):

```bash
keytool -genkey -v -keystore ~/oasish-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias oasish-key
```

Masukkan password aman, nama organisasi, unit, kota, dan kode negara (`ID`).

### 4.2 Konfigurasi `key.properties` & `build.gradle.kts`

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

### 4.3 ProGuard, R8 & Code Obfuscation

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

### 4.4 Build Android App Bundle (AAB)

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

### 4.5 Build Universal APK & Split-per-ABI (Direct Distribution)

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

### 4.6 Rilis ke Google Play Console

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

## 5. Deployment iOS

### 5.1 Sertifikat & Provisioning Profile (Apple Developer)

Sebelum build iOS release, siapkan aset di [Apple Developer Portal](https://developer.apple.com/account/resources):

1. **App ID**: Buat App ID dengan Bundle Identifier `com.hroasish.app`. Centang Capabilities:
   - *Push Notifications*
   - *Location Updates*
2. **Distribution Certificate**: Buat sertifikat *Apple Distribution* menggunakan CSR dari Mac Keychain.
3. **Provisioning Profile**: Buat profile tipe *App Store Distribution* untuk `com.hroasish.app`.

### 5.2 Konfigurasi Runner & Capabilities di Xcode

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

### 5.3 Build Release Archive (.xcarchive) & IPA

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

### 5.4 Distribusi via Apple TestFlight

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

### 5.5 Rilis ke Apple App Store (Production)

1. Di App Store Connect, buat versi baru (misal `1.0.0`).
2. Pilih build TestFlight yang telah terverifikasi stabil.
3. Isi kelengkapan toko:
   - **Screenshots**: iPhone 6.7" (iPhone 15 Pro Max) dan 6.5" (iPhone 11 Pro Max / XS Max).
   - **Deskripsi & Keywords**: Aplikasi absensi, manajemen HR, slip gaji karyawan.
   - **URL Kebijakan Privasi**: `https://oasish.id/privacy-policy` (wajib HTTPS aktif).
   - **URL Dukungan Teknis**: `https://oasish.id/support`.
4. Klik **Submit for Review**.

---

## 6. Konfigurasi Layanan Eksternal & Kredensial

### 6.1 Firebase Cloud Messaging (FCM) & Google Services

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

### 6.2 Google Maps Mobile SDK (Android & iOS)

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

## 7. Kepatuhan Kebijakan Privasi & App Review (Store Policy)

Kebijakan Google Play dan Apple App Store sangat ketat terhadap aplikasi enterprise yang mengakses lokasi dan biometrik. Ikuti panduan ini agar terhindar dari penolakan (*rejection*):

### 7.1 Izin Lokasi Latar Belakang (Android 14+ Foreground Service)

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

### 7.2 Izin Kamera, Biometrik & Galeri

1. **Kamera & Biometrik**: Digunakan untuk verifikasi kehadiran wajah (Face Recognition dengan ML Kit) dan selfie bukti kegiatan.
2. **Apple Guideline 5.1.1 (Data Collection)**: Teks string pada `NSCameraUsageDescription` dan `NSFaceIDUsageDescription` di `Info.plist` tidak boleh generik ("Aplikasi butuh kamera"). Harus spesifik ("Aplikasi memerlukan akses kamera untuk mengambil foto profil, bukti kegiatan lapangan, dan verifikasi absensi biometrik").

### 7.3 Akun Demo & Catatan Reviewer (App Review Notes)

Sediakan akun pengujian khusus untuk tim reviewer Google dan Apple di menu **App Review Information**:

- **Username / Email**: `reviewer@oasish.id`
- **Password**: `ReviewerSecure2026!`
- **Catatan untuk Reviewer**:
  > *"This app is an enterprise HRIS and Employee Self Service portal for internal company employees. The demo credentials provide access to a staging company profile where reviewers can test Attendance Clock In (with camera & GPS geofencing simulation), Leave Requests, and Task Activity feeds. All test data can be freely submitted and approved."*

---

## 8. Automasi CI/CD & Fastlane

Fastlane mempermudah build dan upload otomatis tanpa harus membuka Android Studio atau Xcode secara manual.

### Contoh Alur GitHub Actions (`.github/workflows/deploy-mobile.yml`)

```yaml
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

## 9. Troubleshooting & Solusi Kendala Rilis

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
