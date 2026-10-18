# Panduan Memulai (Developer Onboarding Guide) — OASISH HRIS Mobile App (Flutter)

> **Cakupan**: panduan langkah-demi-langkah bagi pengembang baru untuk menyiapkan lingkungan lokal (*local setup*), menginstal dependensi Flutter & Dart, mengonfigurasi Android Studio & Xcode, menghubungkan aplikasi ke backend server lokal (`muratech_hris_server`), menjalankan generator kode (`build_runner`), melakukan debugging dengan Alice HTTP Inspector, serta konvensi penambahan fitur baru.
> **Terakhir diverifikasi terhadap kode**: Oktober 2026 (Flutter 3.x, Dart 3.x, Java JDK 17).

---

## Daftar Isi

1. [Spesifikasi Teknis & Prasyarat Sistem](#1-spesifikasi-teknis--prasyarat-sistem)
2. [Setup Lingkungan Kerja Lokal](#2-setup-lingkungan-kerja-lokal)
3. [Koneksi ke Backend Server Lokal](#3-koneksi-ke-backend-server-lokal)
4. [Menjalankan Aplikasi di Emulator & Perangkat Fisik](#4-menjalankan-aplikasi-di-emulator--perangkat-fisik)
5. [Generasi Kode & Pengelolaan Aset (`build_runner`)](#5-generasi-kode--pengelolaan-aset-build_runner)
6. [Debugging, HTTP Logging & Alice Inspector](#6-debugging-http-logging--alice-inspector)
7. [Panduan Langkah-demi-Langkah Menambah Fitur Baru](#7-panduan-langkah-demi-langkah-menambah-fitur-baru)
8. [Perintah Esensial & Shortcut Produktivitas](#8-perintah-esensial--shortcut-produktivitas)

---

## 1. Spesifikasi Teknis & Prasyarat Sistem

Sebelum memulai, pastikan perangkat keras dan perangkat lunak Anda memenuhi prasyarat minimum:

- **Sistem Operasi**: macOS Sonoma/Sequoia (disarankan untuk build iOS + Android), Ubuntu 22.04+, atau Windows 11.
- **Flutter SDK**: `v3.29.x` atau lebih baru (Channel `stable`).
- **Dart SDK**: `v3.7.x` atau lebih baru (termasuk di dalam Flutter SDK).
- **Java JDK**: **JDK 17** (wajib untuk Android Gradle Plugin 8+; disarankan Azul Zulu JDK 17).
- **Android Studio**: Ladybug / Koala dengan Android SDK, Command-line Tools, dan Emulator Android 14/15.
- **Xcode (Khusus macOS)**: Xcode 15.4 / 16.x dengan iOS 17/18 Simulator dan **CocoaPods** `v1.14.0+`.

Periksa kesiapan komputer Anda:
```bash
flutter doctor -v
```
Pastikan seluruh tanda centang berwarna hijau (Android toolchain, Xcode, VS Code/Android Studio).

---

## 2. Setup Lingkungan Kerja Lokal

### 1. Kloning Repositori & Masuk ke Folder Project
```bash
cd /Users/username/Documents/Dev/muratech-hris/hris_flutter
```

### 2. Unduh Paket Dependensi
```bash
flutter pub get
```

### 3. Setup CocoaPods (Khusus Pengguna macOS untuk Target iOS)
```bash
cd ios
pod install --repo-update
cd ..
```

---

## 3. Koneksi ke Backend Server Lokal

Aplikasi mobile berkomunikasi dengan REST API `muratech_hris_server`. Karena simulator/emulator memiliki arsitektur loopback jaringan yang berbeda dengan laptop host, perhatikan aturan URL di bawah ini:

| Target Menjalankan Aplikasi | Host Base URL yang Digunakan | Penjelasan |
|---|---|---|
| **iOS Simulator** | `http://localhost:8000/api/v1` | Berbagi jaringan loopback yang sama dengan macOS host |
| **Android Emulator** | `http://10.0.2.2:8000/api/v1` | IP virtual Android Emulator untuk mengakses `localhost` komputer host |
| **Perangkat Fisik (Wi-Fi)** | `http://192.168.1.xxx:8000/api/v1` | IP LAN komputer host (HP dan laptop wajib berada di jaringan Wi-Fi yang sama) |
| **Server Dev Cloud (Default)** | `https://apidev.hroasish.com/api/v1` | Server cloud development aktif tanpa perlu menyalakan API lokal |

Jalankan aplikasi dengan mengoper URL backend lokal:
```bash
# Menghubungkan Android Emulator ke API server lokal
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Menghubungkan iOS Simulator ke API server lokal
flutter run -d "iPhone 16" --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

---

## 4. Menjalankan Aplikasi di Emulator & Perangkat Fisik

### 1. Melihat Perangkat yang Terhubung
```bash
flutter devices
```

### 2. Menjalankan Aplikasi (Mode Debug)
```bash
flutter run
```

### 3. Tombol Pintas Saat Aplikasi Berjalan (Flutter Hot Reload):
- Ketik **`r`** di terminal: **Hot Reload** (memperbarui perubahan UI tanpa me-reset state aplikasi).
- Ketik **`R`** di terminal: **Hot Restart** (me-reset seluruh state BLoC dan mengulang dari SplashScreen).
- Ketik **`p`** di terminal: Menampilkan overlay visual panduan layout (*Display RenderBox*).
- Ketik **`q`** di terminal: Menghentikan aplikasi (*Quit*).

---

## 5. Generasi Kode & Pengelolaan Aset (`build_runner`)

Project ini menggunakan `build_runner` dan `flutter_gen` untuk menghasilkan referensi aset statis (gambar, ikon SVG) yang aman terhadap tipe data (*type-safe*).

Setiap kali Anda menambahkan berkas baru di folder `assets/images/` atau `assets/icons/`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

> [!CAUTION]
> Dilarang mengedit berkas di dalam direktori `lib/gen/` secara manual, karena berkas tersebut digenerate otomatis oleh sistem.

---

## 6. Debugging, HTTP Logging & Alice Inspector

### 1. Pretty Dio Logger (Terminal Output)
Pada mode debug, setiap request HTTP, query parameters, multipart data, headers, status code, dan respons JSON dicetak rapi dan berwarna di console terminal debug.

### 2. Alice HTTP Inspector
Aplikasi mobile telah terintegrasi dengan **Alice HTTP Inspector** (`lib/core/network/alice_service.dart`):
- **Cara Membuka**: Cukup **goyangkan perangkat fisik (*shake gesture*)** atau ketuk notifikasi persisten Alice di notification shade Android.
- **Kemampuan**: Melihat seluruh log pemanggilan API secara grafis di layar HP, menyaring respons error (4xx / 5xx), serta membagikan log cURL atau detail respons ke developer lain via tombol share.

---

## 7. Panduan Langkah-demi-Langkah Menambah Fitur Baru

Untuk menjaga kepatuhan terhadap arsitektur **Feature-First Clean Architecture**, ikuti tahapan berikut saat membuat modul baru (misal: fitur `medical_claim`):

### Langkah 1: Buat Struktur Direktori Modul
```bash
mkdir -p lib/features/medical_claim/data/models \
         lib/features/medical_claim/data/datasources \
         lib/features/medical_claim/data/repositories \
         lib/features/medical_claim/domain/repositories \
         lib/features/medical_claim/presentation/bloc \
         lib/features/medical_claim/presentation/pages \
         lib/features/medical_claim/presentation/widgets
```

### Langkah 2: Buat Model DTO di `data/models/`
Buat `medical_claim_model.dart` dengan factory `fromJson` dan method `toJson`.

### Langkah 3: Buat Remote Datasource di `data/datasources/`
Gunakan singleton `ApiClient.instance`:
```dart
class MedicalClaimRemoteDatasource {
  Future<List<MedicalClaimModel>> getClaims() async {
    final response = await ApiClient.instance.get(ApiEndpoints.medicalClaims);
    final list = response.data['data'] as List;
    return list.map((json) => MedicalClaimModel.fromJson(json)).toList();
  }
}
```

### Langkah 4: Buat Repository Interface & Implementation
- Deklarasikan interface di `domain/repositories/medical_claim_repository.dart`.
- Terapkan implementasi di `data/repositories/medical_claim_repository_impl.dart`. Tangkap error dengan `on ApiException catch (e)`.

### Langkah 5: Buat BLoC di `presentation/bloc/`
Buat `medical_claim_event.dart`, `medical_claim_state.dart`, dan `medical_claim_bloc.dart`. Pastikan semua state dan event memperluas `Equatable`.

### Langkah 6: Buat Screen di `presentation/pages/`
- Gunakan token desain dari `AppColors`, `AppTypography`, `AppSpacing`, dan `AppRadius`.
- Gunakan komponen global: `AppButton` untuk tombol aksi, `EmployeeInfoRow` untuk identitas karyawan, `AppRequestFilterBottomSheet` untuk filter.

### Langkah 7: Daftarkan Rute di `AppRouter`
- Tambahkan konstanta di `lib/app/routes/route_name.dart`.
- Daftarkan `GoRoute` di `lib/app/routes/app_router.dart`.

### Langkah 8: Buat Unit & BLoC Test
Tambahkan berkas tes di `test/features/medical_claim/presentation/bloc/medical_claim_bloc_test.dart`.

---

## 8. Perintah Esensial & Shortcut Produktivitas

```bash
# Mengunduh dependensi
flutter pub get

# Menjalankan pembersihan cache build
flutter clean

# Analisis kualitas kode (Linter)
flutter analyze

# Menjalankan seluruh pengujian unit
flutter test

# Format kode otomatis
dart format lib test

# Build APK Release
flutter build apk --release

# Build Android App Bundle (AAB) untuk Google Play Store
flutter build appbundle --release
```

---

> Dokumen terkait:
> - Arsitektur aplikasi & BLoC: [ARCHITECTURE.md](./ARCHITECTURE.md)
> - Panduan deploy mobile Android & iOS: [DEPLOYMENT.md](./DEPLOYMENT.md)
> - Panduan pengujian sistem: [TESTING.md](./TESTING.md)
> - Penjelasan fitur aplikasi: [FEATURES.md](./FEATURES.md)
