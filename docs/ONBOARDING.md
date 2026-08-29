# 🚀 Muratech HRIS (Oasish) - Developer Onboarding Guide

Selamat datang di project **Muratech HRIS Mobile (Oasish)**!  
Panduan ini dirancang untuk membantu developer baru memahami setup lingkungan kerja, arsitektur aplikasi, standar penulisan kode, serta alur pengembangan fitur.

---

## 📋 Daftar Isi
1. [Tentang Project](#-tentang-project)
2. [Prasyarat Sistem (Prerequisites)](#-prasyarat-sistem-prerequisites)
3. [Langkah Awal & Setup (Getting Started)](#-langkah-awal--setup-getting-started)
4. [Koneksi ke Backend](#-koneksi-ke-backend)
5. [Struktur Folder & Arsitektur](#-struktur-folder--arsitektur)
6. [Design System & Styling](#-design-system--styling)
7. [Perintah Penting (Essential Commands)](#-perintah-penting-essential-commands)
8. [Standar & Best Practices](#-standar--best-practices)

---

## 📱 Tentang Project

* **Nama Aplikasi:** Oasish (Muratech HRIS)
* **Framework:** Flutter (Dart 3+)
* **Routing:** `go_router`
* **Styling & Icons:** Custom Design System (Theme, Colors, Typography), `google_fonts`, `lucide_icons_flutter`
* **Asset Management:** `flutter_gen`

---

## 💻 Prasyarat Sistem (Prerequisites)

Pastikan lingkungan lokal Anda telah terinstal:
* **Flutter SDK:** >= 3.24.0 (disarankan channel `stable`)
* **Dart SDK:** >= 3.5.0 (sesuai SDK constraint `^3.12.2`)
* **Xcode** (untuk macOS / iOS Simulator & Device) & **CocoaPods**
* **Android Studio** & **Android SDK / Emulator** (untuk Android)
* **VS Code** atau **Cursor / Antigravity IDE** dengan ekstensi Dart & Flutter

Jalankan perintah berikut untuk memeriksa kelengkapan environment:
```bash
flutter doctor -v
```

---

## 🛠️ Langkah Awal & Setup (Getting Started)

### 1. Masuk ke Direktori Project
```bash
cd hris_flutter
```

### 2. Download Dependensi
```bash
flutter pub get
```

### 3. Generate Assets (jika ada penambahan file di `assets/`)
Project ini menggunakan `flutter_gen_runner` untuk auto-generate class aset yang aman (type-safe):
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Menjalankan Aplikasi
Pilih simulator/device target, lalu jalankan:
```bash
# Debug mode
flutter run

# Menentukan target device tertentu
flutter run -d chrome # Web (jika diaktifkan)
flutter run -d "iPhone 15" # iOS Simulator
flutter run -d emulator-5554 # Android Emulator
```

---

## 🔌 Koneksi ke Backend

Backend HRIS berjalan menggunakan **Bun** di direktori server (`muratech_hris_server`).

* **Host Lokal:** `http://localhost:3000` (atau port yang dikonfigurasi)
* **Android Emulator:** Gunakan `http://10.0.2.2:3000` untuk mengakses localhost laptop/PC dari emulator Android.
* **iOS Simulator:** Dapat langsung mengakses `http://localhost:3000`.
* **Real Device:** Gunakan IP LAN laptop Anda (misal `http://192.168.1.X:3000`) dan pastikan satu jaringan WiFi.

---

## 🏗️ Struktur Folder & Arsitektur

Project mengadopsi pola **Feature-First Clean Architecture**:

```text
lib/
├── app/                             # Konfigurasi level aplikasi
│   ├── config/                      # Tema, Palet Warna, Tipografi, Token Desain
│   │   ├── app_colors.dart
│   │   ├── app_design.dart
│   │   ├── app_theme.dart
│   │   └── app_typography.dart
│   └── routes/                      # Navigasi & Routing (GoRouter)
│       ├── app_router.dart
│       └── route_name.dart
│
├── core/                            # Komponen global lintas fitur
│   ├── constants/                   # Konstanta aplikasi & API endpoints
│   ├── network/                     # HTTP Client, Error Interceptor, Token Handler
│   ├── utils/                       # Helpers, Extensions, Validators
│   └── widgets/                     # Shared UI Widgets (Reusable)
│       └── app_name_version_text.dart
│
├── features/                        # Modul fitur mandiri (Feature-First)
│   ├── splash/                      # Layar Splash & inisialisasi awal
│   │   └── presentation/pages/splash_screen.dart
│   ├── auth/                        # Fitur Autentikasi (Login, Reset Password, dll)
│   │   ├── data/                    # Models, Data Sources, Repositories
│   │   ├── domain/                  # Entities, Use Cases (opsional)
│   │   └── presentation/
│   │       ├── bloc/                # State Management (BLoC/Cubit/Notifier)
│   │       ├── pages/
│   │       │   ├── login_screen.dart
│   │       │   └── reset_password_screen.dart
│   │       └── widgets/             # Widget khusus halaman auth
│   └── dashboard/                   # Fitur Beranda & Menu Utama
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── bloc/
│           ├── pages/
│           │   └── dashboard_screen.dart
│           └── widgets/
│
├── gen/                             # Auto-generated code oleh build_runner (flutter_gen)
│   └── assets.gen.dart
│
└── main.dart                        # Entry point aplikasi
```

---

## 🎨 Design System & Styling

Semua nilai warna, typography, dan spacing wajib mengacu ke konfigurasi di `lib/app/config/`:

* **`AppColors`**: Warna primer, sekunder, background, text, dan semantic colors (success, warning, error).
* **`AppTypography`**: Definisi gaya font berbasis `GoogleFonts.plusJakartaSans` / `GoogleFonts.inter`.
* **`AppTheme`**: Konfigurasi `ThemeData` Material 3 untuk light & dark theme.
* **`AppDesign`**: Token padding, border radius, elevation, dan margin terstandar.
* **Ikon:** Menggunakan library **`lucide_icons_flutter`** (contoh: `LucideIcons.mail`, `LucideIcons.lock`).

---

## ⚡ Perintah Penting (Essential Commands)

| Perintah | Deskripsi |
|---|---|
| `flutter pub get` | Mengunduh dependensi baru |
| `dart analyze` | Memeriksa kepatuhan linter dan warning kode |
| `dart fix --apply` | Memperbaiki isu linter otomatis yang aman |
| `dart run build_runner build --delete-conflicting-outputs` | Regenerasi aset file `Assets.icons.*` dan model code-gen |
| `flutter test` | Menjalankan seluruh unit & widget test |

---

## 🔔 Setup Firebase & Push Notifications (FCM)

Project ini telah dilengkapi dengan **`firebase_core`**, **`firebase_messaging`**, dan **`flutter_local_notifications`** (`lib/core/services/notification_service.dart`).

### Langkah Menghubungkan ke Firebase Console:
1. **Otomatis (Menggunakan FlutterFire CLI):**
   ```bash
   # Install FlutterFire CLI jika belum ada
   dart pub global activate flutterfire_cli

   # Hubungkan ke proyek Firebase
   flutterfire configure
   ```
2. **Manual:**
   * **Android:** Unduh file `google-services.json` dari Firebase Console dan letakkan di `android/app/google-services.json`.
   * **iOS:** Unduh file `GoogleService-Info.plist` dan masukkan ke `ios/Runner/GoogleService-Info.plist` via Xcode.
3. Token FCM perangkat otomatis diambil saat user melakukan Login dan diteruskan ke backend untuk notifikasi persetujuan cuti, lembur, dan absensi.

---

## 🛡️ Standar & Best Practices

1. **Gunakan Type-Safe Assets:**  
   Gunakan `Assets.icons.logo.path` dari `package:hris_flutter/gen/assets.gen.dart`, hindari *hardcoded string* path seperti `'assets/icons/logo.png'`.
2. **Pisahkan UI & Logic:**  
   Jangan letakkan query API langsung di dalam method `build()` widget. Gunakan layer data & state management.
3. **Responsive & Adaptive:**  
   Gunakan layout dinamis (`Expanded`, `Flexible`, `SingleChildScrollView`, `LayoutBuilder`) untuk mencegah *RenderFlex overflow* pada berbagai ukuran layar.
4. **Analisis Berkala:**  
   Selalu jalankan `dart analyze` sebelum melakukan commit kode baru.
