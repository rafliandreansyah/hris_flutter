# 🏛️ Architecture & Code Standards Guide

Dokumen ini menjelaskan arsitektur perangkat lunak, pembagian layer, dan alur kerja pembuatan fitur baru pada project **Muratech HRIS (Oasish)**.

---

## 🧩 1. Filosofi Arsitektur: Feature-First Clean Architecture

Project ini mengombinasikan **Feature-First Organization** dengan **Clean Architecture (Layered)**.  
Setiap fitur besar diisolasi dalam foldernya masing-masing di bawah `lib/features/`, sehingga memudahkan scaling aplikasi dan kolaborasi antar developer.

### Pembagian Layer per Fitur

```text
features/[feature_name]/
├── data/
│   ├── models/            # Data Transfer Objects (DTO) / JSON Mapping
│   ├── datasources/       # Remote (API Client) & Local (SQLite/SecureStorage) Sources
│   └── repositories/      # Implementasi Repository konkret
├── domain/                # (Opsional jika domain logic kompleks)
│   ├── entities/          # Pure Dart Data Class (immutable)
│   ├── repositories/      # Interface/Abstract class kontrak Repository
│   └── usecases/          # Business logic unit / Interactor
└── presentation/
    ├── bloc/ / notifier/  # State Management (Cubit, BLoC, atau ChangeNotifier)
    ├── pages/             # Layar utama (Screen/Page)
    └── widgets/           # Sub-widget khusus yang hanya digunakan di fitur ini
```

---

## 📂 2. Tanggung Jawab Folder Global

### `lib/app/`
Folder untuk konfigurasi dasar seluruh aplikasi:
* **`app/config/`**: Definisi tema Material 3 (`app_theme.dart`), token warna (`app_colors.dart`), tipografi font (`app_typography.dart`), dan dimensi komponen (`app_design.dart`).
* **`app/routes/`**: Konfigurasi navigasi deklaratif menggunakan `GoRouter` (`app_router.dart`) dan konstanta rute (`route_name.dart`).

### `lib/core/`
Folder untuk kode utilitas yang dipakai lintas fitur:
* **`core/constants/`**: Konstanta global seperti URL endpoint, key penyimpanan, timeout limit.
* **`core/network/`**: Client wrapper untuk HTTP request, interceptor header autentikasi JWT, dan error handling.
* **`core/utils/`**: Format tanggal/mata uang (Intl), validator form (email, password), extensions (Dart helper methods).
* **`core/widgets/`**: Widget umum yang dapat dipakai di berbagai fitur (misal: `AppNameVersionText`, Custom Button, Shimmer Loading, Custom Dialog).

### `lib/gen/`
Folder yang dikelola secara otomatis oleh `flutter_gen` dan `build_runner`.  
**Jangan mengedit file di folder ini secara manual.**

---

## 🚦 3. Alur Pembuatan Fitur Baru (Step-by-Step)

Ketika Anda menambahkan modul fitur baru (contoh: `attendance` / absensi):

1. **Buat Struktur Folder Fitur:**
   ```bash
   mkdir -p lib/features/attendance/data \
            lib/features/attendance/domain \
            lib/features/attendance/presentation/pages \
            lib/features/attendance/presentation/widgets \
            lib/features/attendance/presentation/bloc
   ```

2. **Definisikan Data Layer:**
   * Buat Model JSON di `data/models/attendance_model.dart` dengan method `fromJson` dan `toJson`.
   * Buat Data Source di `data/datasources/attendance_remote_datasource.dart`.
   * Buat Repository implementation di `data/repositories/attendance_repository_impl.dart`.

3. **Definisikan Presentation Layer:**
   * Buat State Manager (BLoC/Cubit/ViewModel) di `presentation/bloc/`.
   * Buat Halaman Screen di `presentation/pages/attendance_screen.dart`.
   * Ekstrak komponen berulang ke `presentation/widgets/`.

4. **Daftarkan Rute di `AppRouter`:**
   * Tambahkan konstanta rute di `lib/app/routes/route_name.dart`:
     ```dart
     static const String attendance = '/attendance';
     ```
   * Daftarkan `GoRoute` di `lib/app/routes/app_router.dart`:
     ```dart
     GoRoute(
       path: Routes.attendance,
       name: Routes.attendance,
       builder: (context, state) => const AttendanceScreen(),
     ),
     ```

5. **Validasi & Linter:**
   Jalankan pemeriksaan static analyzer:
   ```bash
   dart analyze
   ```

---

## 🔒 4. Keamanan & Penanganan Token

* Token autentikasi disimpan secara terenkripsi menggunakan `flutter_secure_storage` atau wrapper aman lainnya.
* Interceptor HTTP secara otomatis menyisipkan header:
  ```http
  Authorization: Bearer <access_token>
  ```
* Jika server mengembalikan status code `401 Unauthorized`, interceptor akan otomatis mengarahkan user kembali ke `Routes.LOGIN`.
