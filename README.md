# OASISH HRIS — Mobile App (Flutter)

Aplikasi mobile Employee Self Service (ESS) dan manajemen operasional HRIS untuk platform **Android** dan **iOS**. Dibangun menggunakan **Flutter 3.x**, **Dart 3.x**, **flutter_bloc**, **Clean Architecture**, **Google Stitch M3 Design System (Teal Oasis)**, **Firebase Cloud Messaging (FCM)**, **Google ML Kit Face Detection**, dan terintegrasi secara penuh dengan REST API backend **`muratech_hris_server`**.

> **Skema API dan Kontrak Data dimiliki `muratech_hris_server`**. Aplikasi mobile bertindak sebagai client yang mengonsumsi endpoint RESTful API dan menyelaraskan otorisasi via token JWT serta katalog permission. Detail arsitektur: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (`v3.29.x+`) / [Dart](https://dart.dev/) (`v3.7.x+`)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (`v9.1.1`) & [equatable](https://pub.dev/packages/equatable)
- **HTTP Client**: [Dio](https://pub.dev/packages/dio) (`v5.11.0`) dengan silent token refresher, pretty logger, dan [Alice](https://pub.dev/packages/alice) HTTP Inspector
- **Navigasi & Routing**: [go_router](https://pub.dev/packages/go_router) (`v17.3.0`) dengan declarative routes & auth guards
- **Design System**: Google Stitch M3 *Teal Oasis* (Google Fonts Plus Jakarta Sans & [Lucide Icons](https://pub.dev/packages/lucide_icons_flutter))
- **Keamanan & Storage**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (AES-256 Android Keystore & iOS Keychain) dan [local_auth](https://pub.dev/packages/local_auth) (Biometrik Sidik Jari & Face ID)
- **Peta & Lokasi**: [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) dan [geolocator](https://pub.dev/packages/geolocator) (Foreground Service Android & CoreLocation iOS)
- **Kamera & AI Biometrik**: [camera](https://pub.dev/packages/camera) dan [google_mlkit_face_detection](https://pub.dev/packages/google_mlkit_face_detection)
- **Notifikasi Push**: [firebase_messaging](https://pub.dev/packages/firebase_messaging) & [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Dokumen & PDF**: [syncfusion_flutter_pdfviewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer) dan [share_plus](https://pub.dev/packages/share_plus)
- **Pengujian & E2E**: `flutter_test`, `bloc_test`, dan [Patrol by LeanCode](https://patrol.leancode.co/) dengan AndroidX Test Orchestrator

---

## Struktur Proyek

```
hris_flutter/
├── android/           # Konfigurasi native Android, Gradle, Keystore & Manifest
├── ios/               # Konfigurasi native iOS, Xcode Workspace, Podfile & Info.plist
├── assets/            # Aset gambar, ikon logo, dan ilustrasi SVG
├── lib/
│   ├── app/           # Konfigurasi tema Material 3, warna, tipografi, dan go_router
│   ├── core/          # ApiClient, interceptors, secure storage, dialogs, dan global widgets
│   ├── features/      # 17 Modul Bisnis (Feature-First Clean Architecture):
│   │   ├── activity/        # Pelaporan aktivitas lapangan & geotagging
│   │   ├── announcement/    # Pengumuman internal perusahaan
│   │   ├── asset/           # Manajemen aset & serah terima inventaris
│   │   ├── attendance/      # Presensi selfie ML Kit, geofencing GPS, dan riwayat
│   │   ├── auth/            # Otentikasi NIK/Email, biometrik, dan reset password
│   │   ├── dashboard/       # Beranda Bento Grid 12 menu & live shift clock
│   │   ├── employee/        # Direktori rekan kerja & profil lengkap karyawan
│   │   ├── leave/           # Pengajuan cuti/izin, kuota saldo, dan approval
│   │   ├── lifecycle/       # Perubahan status karyawan & riwayat karir
│   │   ├── notification/    # Pusat notifikasi in-app & FCM push receiver
│   │   ├── overtime/        # Pengajuan lembur, SPK, dan approval
│   │   ├── payroll/         # Slip gaji bulanan & penampil PDF interaktif
│   │   ├── reimbursement/   # Klaim pengeluaran nota & kasbon dinas
│   │   ├── resignation/     # Pengajuan resign & checklist exit clearance
│   │   ├── schedule/        # Kalender shift & hari libur nasional
│   │   ├── splash/          # Splash screen & inisialisasi sesi
│   │   ├── tracking/        # Background location tracking engine
│   │   └── warning_letter/  # Surat peringatan sanksi disiplin (SP1/SP2/SP3)
│   ├── gen/           # Aset hasil auto-generate (flutter_gen)
│   ├── l10n/          # Lokalisasi bahasa Indonesia (id) dan Inggris (en)
│   └── main.dart      # Entry point aplikasi mobile
├── test/              # 220+ file unit testing, BLoC testing, dan widget testing
├── integration_test/  # 20 skenario E2E testing dengan Patrol & izin native OS
└── docs/              # Dokumentasi lengkap (lihat indeks di bawah)
```

---

## Memulai (Quick Start)

Prasyarat: **Flutter SDK** `v3.29.x+`, **Dart SDK** `v3.7.x+`, **Java JDK 17**, serta **Android Studio** atau **Xcode** (khusus macOS).

```bash
# 1. Unduh seluruh dependensi paket
flutter pub get

# 2. Setup CocoaPods (khusus pengguna macOS untuk target iOS)
cd ios && pod install --repo-update && cd ..

# 3. Generate kelas aset aman (type-safe)
dart run build_runner build --delete-conflicting-outputs

# 4. Jalankan aplikasi di Emulator / Perangkat Fisik (Target Default: Cloud Dev API)
flutter run

# 5. Atau hubungkan ke server backend lokal:
# Untuk Android Emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Untuk iOS Simulator:
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Panduan setup lengkap langkah demi langkah ada di [docs/ONBOARDING.md](docs/ONBOARDING.md).

---

## Pengujian & Quality Gate

```bash
# Menjalankan seluruh pengujian unit & widget (220+ file test)
flutter test

# Analisis statis kualitas kode (linter)
flutter analyze

# Menjalankan E2E testing dengan automasi dialog izin native OS (Patrol)
patrol test -t integration_test/test_bundle.dart
```

Panduan pengujian lengkap ada di [docs/TESTING.md](docs/TESTING.md).

---

## Dokumentasi (`docs/`)

Indeks lengkap dan alur belajar tersedia di [docs/README.md](docs/README.md).

| Dokumen | Isi |
|---|---|
| [ONBOARDING.md](docs/ONBOARDING.md) | Setup lokal, emulator/device, koneksi backend lokal, generator kode, debugging Alice |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Feature-First Clean Architecture, BLoC, Dio client, silent refresh, storage, Stitch tokens |
| [AUTHORIZATION.md](docs/AUTHORIZATION.md) | Otorisasi 3-lapis, visibilitas menu Bento Grid, wewenang aksi memori, katalog permission |
| [FEATURES.md](docs/FEATURES.md) | Perilaku 17 modul domain: UI, alur bisnis, kamera & GPS geofencing, endpoint API |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | **Deploy & Rilis**: Build Docker backend dev (`muratech/oasish-api:dev`), APK/IPA Dev QA, Android Keystore & AAB, iOS TestFlight & App Store |
| [TESTING.md](docs/TESTING.md) | Piramida pengujian mobile, BLoC test, Widget test, E2E Patrol, mocking, quality gate |
| [ROADMAP.md](docs/ROADMAP.md) | Rencana masa depan: offline-first SQLite, integrasi smartwatch, widgets, BLE beacon |
| [BUG_FIX_CHECKLIST.md](docs/BUG_FIX_CHECKLIST.md) | Audit kepatuhan hardware (GPS, Fake GPS, Kamera, Biometrik, Baterai, Izin OS) |

---

## Ekosistem Proyek Terkait

- **Backend REST API**: [`muratech_hris_server`](../muratech_hris_server) — Hono.js, Bun, Prisma ORM 6, PostgreSQL, Firebase Admin, oasish_ai.
- **Web Management Portal**: [`hris-web`](../hris-web) — React 19, TanStack Start, Radix UI, Prisma ORM 6.
