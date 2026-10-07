# 📚 Dokumentasi Project Muratech HRIS (Oasish) — Flutter Mobile

Selamat datang di repositori dokumentasi resmi aplikasi mobile **Muratech HRIS (Oasish)** (`hris_flutter`).

### Dokumen yang Tersedia:

1. **[Developer Onboarding Guide](ONBOARDING.md)**
   * Panduan setup environment (Flutter, Dart, SDK, Simulator).
   * Menjalankan aplikasi dan menghubungkan ke server lokal backend.
   * Perintah esensial & tips produktivitas.

2. **[Architecture & Code Standards](ARCHITECTURE.md)**
   * Struktur folder berbasis *Feature-First Clean Architecture*.
   * Tanggung jawab layer (`data`, `domain`, `presentation`, `core`, `app`).
   * Panduan step-by-step menambahkan fitur baru.
   * Standar keamanan dan manajemen token API.

3. **[Design System (Google Stitch)](DESIGN_SYSTEM.md)**
   * Sinkronisasi token desain langsung dari Google Stitch (Project ID: `17152850901645837896`).
   * Palet warna *Teal Oasis*, aturan tipografi *Plus Jakarta Sans*, dan geometri radius.
   * Standar styling komponen (*Buttons*, *Cards*, *Inputs*, *Chips*).

4. **[Panduan Hak Akses, Menu & Permission](AUTHORIZATION_AND_PERMISSIONS.md)**
   * Pengelolaan visibilitas menu Bento Grid (`GET /auth/menus`).
   * Penegakan hak akses aksi fungsional (`GET /auth/profile`).
   * Pemetaan 12 menu Quick Access dan penanganan error `403 Forbidden`.

5. **[Panduan Pelacakan Lokasi & Background Service](LOCATION_TRACKING.md)**
   * Arsitektur pelacakan GPS latar belakang (Foreground Service Android & CoreLocation iOS).
   * **Resolusi Prioritas Ganda**: Aturan presedensi Aktivitas Lapangan vs Presensi Harian.
   * Mekanisme pemulihan otomatis (*Graceful Fallback*) dan penghentian penuh (*Full Stop*).
   * Kontrak pengiriman data batch (`POST /tracking/batch`), *offline buffering*, dan deteksi Fake GPS.
