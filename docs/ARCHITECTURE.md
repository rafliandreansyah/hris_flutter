# 🏛️ Architecture & Code Standards Guide

Dokumen ini menjelaskan arsitektur perangkat lunak, pembagian layer, integrasi jaringan (Dio & Logging), dan alur kerja pembuatan fitur baru pada project **Muratech HRIS (Oasish)**.

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

## 🌐 2. Network Client (Dio & PrettyDioLogger)

Semua komunikasi HTTP REST API ditangani melalui layer terpusat di `lib/core/network/`:

* **`ApiClient` (`lib/core/network/api_client.dart`)**:
  * Singleton client berbasis `Dio` dengan base URL dinamis (mendukung Android Emulator `10.0.2.2`, iOS Simulator `localhost`, dan real device).
  * Method terstandar: `get()`, `post()`, `put()`, `patch()`, `delete()`.
  * Menangani error otomatis dan mengembalikannya dalam bentuk `ApiException`.

* **`PrettyDioLogger` (`lib/core/network/interceptors/logging_interceptor.dart`)**:
  * Logging HTTP request dan response yang rapi, berwarna, dan informatif di console (hanya aktif pada `kDebugMode`).

* **`AuthInterceptor` (`lib/core/network/interceptors/auth_interceptor.dart`)**:
  * Otomatis menyisipkan header `Authorization: Bearer <token>` pada setiap request.
  * Mendeteksi response `401 Unauthorized` untuk penanganan *session expired* / auto-logout.

* **`ApiException` (`lib/core/network/api_exception.dart`)**:
  * Memetakan error HTTP (`400`, `401`, `403`, `404`, `422`, `500`, `Connection Timeout`, `Connection Error`) menjadi pesan yang ramah pengguna (*user-friendly*).

* **`ApiEndpoints` (`lib/core/constants/api_endpoints.dart`)**:
  * Daftar konstanta URL endpoint terpusat untuk seluruh fitur (`/auth/login`, `/attendance`, `/leave-requests`, `/overtime`, dll).

---

### Contoh Pemanggilan API dengan `ApiClient`

```dart
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';

Future<void> loginUser(String email, String password) async {
  try {
    final response = await ApiClient.instance.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final token = response.data['data']['token'];
    ApiClient.instance.setAuthToken(token);
  } on ApiException catch (e) {
    print('Gagal login: ${e.message} (Status: ${e.statusCode})');
  }
}
```

---

## 📂 3. Tanggung Jawab Folder Global

### `lib/app/`
Folder untuk konfigurasi dasar seluruh aplikasi:
* **`app/config/`**: Definisi tema Material 3 (`app_theme.dart`), token warna (`app_colors.dart`), tipografi font (`app_typography.dart`), token desain (`app_design.dart`), dan ThemeExtension (`app_theme_extension.dart`).
* **`app/routes/`**: Konfigurasi navigasi deklaratif menggunakan `GoRouter` (`app_router.dart`) dan konstanta rute (`route_name.dart`).

### `lib/core/`
Folder untuk kode utilitas yang dipakai lintas fitur:
* **`core/constants/`**: `api_endpoints.dart`, `app_constants.dart`.
* **`core/network/`**: `api_client.dart`, `api_exception.dart`, `api_response.dart`, `interceptors/`.
* **`core/utils/`**: Format tanggal/mata uang, validator form, extensions.
* **`core/widgets/`**: Shared widgets (misal: `AppNameVersionText`, custom buttons, dll).

### `lib/gen/`
Folder yang dikelola secara otomatis oleh `flutter_gen` dan `build_runner`.  
**Jangan mengedit file di folder ini secara manual.**

---

## 🚦 4. Alur Pembuatan Fitur Baru (Step-by-Step)

Ketika Anda menambahkan modul fitur baru (contoh: `attendance` / absensi):

1. **Buat Folder Fitur:**
   ```bash
   mkdir -p lib/features/attendance/data \
            lib/features/attendance/domain \
            lib/features/attendance/presentation/pages \
            lib/features/attendance/presentation/widgets \
            lib/features/attendance/presentation/bloc
   ```

2. **Definisikan Data Layer:**
   * Buat Model JSON di `data/models/attendance_model.dart`.
   * Panggil `ApiClient.instance` di `data/datasources/attendance_remote_datasource.dart`.
   * Buat implementasi Repository di `data/repositories/attendance_repository_impl.dart`.

3. **Definisikan Presentation Layer:**
   * Buat State Manager (BLoC/Cubit/Notifier) di `presentation/bloc/`.
   * Buat Halaman Screen di `presentation/pages/attendance_screen.dart`.
   * Ekstrak komponen berulang ke `presentation/widgets/`.

4. **Daftarkan Rute di `AppRouter`:**
   * Daftarkan nama rute di `lib/app/routes/route_name.dart`.
   * Tambahkan `GoRoute` di `lib/app/routes/app_router.dart`.

5. **Validasi & Linter:**
   ```bash
   dart analyze
   ```
