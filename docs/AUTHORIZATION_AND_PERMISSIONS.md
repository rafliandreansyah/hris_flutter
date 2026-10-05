# 📱 Panduan Hak Akses, Menu & Permission — HRIS Flutter

Dokumen ini merupakan panduan implementasi resmi bagi pengembang Flutter dalam mengelola **visibilitas menu** dan **hak wewenang aksi (Functional Permissions)** di aplikasi mobile `hris_flutter`.

---

## 📋 Daftar Isi

1. [Arsitektur Hak Akses Mobile (Two-Layer Access Control)](#1-arsitektur-hak-akses-mobile-two-layer-access-control)
2. [Lapisan 1: Visibilitas Menu Bento Grid (`GET /auth/menus`)](#2-lapisan-1-visibilitas-menu-bento-grid-get-authmenus)
3. [Lapisan 2: Hak Aksi & Permission Fungsional (`GET /auth/profile`)](#3-lapisan-2-hak-aksi--permission-fungsional-get-authprofile)
4. [Tabel Pemetaan 12 Menu Quick Access Dashboard](#4-tabel-pemetaan-12-menu-quick-access-dashboard)
5. [Pola Penggunaan Permission di BLoC & Presentation](#5-pola-penggunaan-permission-di-bloc--presentation)
6. [Standar Penanganan Error 403 Forbidden](#6-standar-penanganan-error-403-forbidden)

---

## 1. Arsitektur Hak Akses Mobile (Two-Layer Access Control)

Aplikasi mobile mengonsumsi dua API otorisasi dari backend:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   HAK AKSES PENGGUNA DI APLIKASI MOBILE                │
├───────────────────────────────────┬────────────────────────────────────┤
│ 1. VISIBILITAS MENU BENTO GRID    │ 2. PERMISSION AKSI & FUNGSIONAL    │
├───────────────────────────────────┼────────────────────────────────────┤
│ • API: GET /api/v1/auth/menus     │ • API: GET /api/v1/auth/profile    │
│ • Kapan dipanggil:                │ • Kapan dipanggil:                 │
│   Saat Dashboard dimuat           │   Saat Login & Refresh Profile     │
│ • Fungsi:                         │ • Fungsi:                          │
│   Menyaring 12 icon menu yang     │   Menyimpan list string permission │
│   tampil di QuickAccessGrid       │   ke SecureStorageService          │
│ • Jika tidak ada di API:          │ • Penggunaan:                      │
│   Icon menu otomatis tersembunyi  │   Cek izin tombol / tab approval   │
└───────────────────────────────────┴────────────────────────────────────┘
```

---

## 2. Lapisan 1: Visibilitas Menu Bento Grid (`GET /auth/menus`)

### Alur Kerja di Flutter:
1. `DashboardBloc` mengeksekusi `_dashboardRepository.getMenus()` (`lib/features/dashboard/data/repositories/dashboard_repository_impl.dart`).
2. Endpoint `GET /auth/menus` mengembalikan daftar objek `MenuItemModel`.
3. State `DashboardLoaded` menyimpan list menu tersebut (`state.menus`).
4. Komponen `QuickAccessGrid` (`lib/features/dashboard/presentation/widgets/quick_access_grid.dart`) memeriksa ketersediaan menu via:
   ```dart
   final displayMenus = (menus != null && menus!.isNotEmpty)
       ? _defaultMenus.where((item) => isMenuAvailable(item.code, item.title, menus)).toList()
       : _defaultMenus;
   ```
5. Jika suatu menu dinonaktifkan untuk perusahaan atau dicabut hak lihatnya untuk karyawan bersangkutan oleh admin, menu tersebut **langsung hilang** dari grid tanpa merusak susunan antarmuka (auto-layout responsive).

---

## 3. Lapisan 2: Hak Aksi & Permission Fungsional (`GET /auth/profile`)

### Alur Penyimpanan:
Saat login berhasil atau aplikasi mengambil profil (`GET /auth/profile`), `AuthRepositoryImpl` otomatis menyimpannya ke `SecureStorageService`:

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
if (profile.permissions.isNotEmpty) {
  await SecureStorageService.instance.saveUserPermissions(profile.permissions);
}
```

### Cara Memeriksa Permission:
`SecureStorageService` menyediakan metode asinkron dan sinkron (in-memory cache):

```dart
// 1. Pengecekan cepat dari memory cache (ideal untuk build widget):
final hasManage = SecureStorageService.instance.hasPermissionInMemory('activity.manage');

// 2. Pengecekan asinkron dengan fallback ke secure storage:
final canApprove = await SecureStorageService.instance.hasPermission('approval.leave.action');
```

---

## 4. Tabel Pemetaan 12 Menu Quick Access Dashboard

| Icon & Label Mobile | Kode Menu (`code`) | Route Aplikasi (`Routes`) | Permission Aksi Terkait |
| :--- | :--- | :--- | :--- |
| **Aktivitas** | `mobile_activity` | `Routes.ACTIVITY` | `activity.manage` |
| **Lembur** | `mobile_overtime` | `Routes.OVERTIME` | `approval.overtime.action`, `report.overtime.view` |
| **Izin & Cuti** | `mobile_leave` | `Routes.LEAVE` | `approval.leave.action`, `report.leave.view` |
| **Absen Luar** | `mobile_attendance_request_live` | `Routes.ATTENDANCE_REQUESTS` | `approval.attendance.action` |
| **Presensi** | `mobile_attendance` | `Routes.ATTENDANCE_LOGS` | `attendance.manage`, `report.attendance.view` |
| **Pegawai** | `mobile_employee` | `Routes.EMPLOYEE_DIRECTORY` | `employee.view` |
| **Surat Peringatan** | `mobile_warning_letter`| `Routes.WARNING_LETTER` | `warning_letter.view`, `warning_letter.create` |
| **Slip Gaji** | `mobile_payroll` | `Routes.PAYROLL` | `payroll.slip.view` |
| **Jadwal Kerja** | `mobile_schedule` | `Routes.EMPLOYEE_SCHEDULE_SELECT` | `work_schedule.view` |
| **Klaim & Kasbon** | `mobile_reimbursement`| `Routes.EXPENSES` | `reimbursement.create`, `approval.reimbursement.manager` |
| **Fasilitas & Aset** | `mobile_asset` | `Routes.ASSETS` | `asset.my_assets` |
| **Resign** | `mobile_resignation` | `Routes.RESIGNATION` | `resignation.view`, `approval.resignation.manager` |

---

## 5. Pola Penggunaan Permission di BLoC & Presentation

### A. Pola Tab Persetujuan Tim (Context-Aware Tabs)
Pada modul yang memiliki 2 tab (`Pengajuan Saya` dan `Persetujuan Tim`), tab persetujuan hanya boleh melakukan aksi persetujuan jika user memiliki wewenang:

```dart
// Contoh di BLoC Event Handler:
final canApprove = _storageService.hasPermissionInMemory('approval.leave.action');
emit(state.copyWith(canApprove: canApprove));
```

### B. Pola Tombol Aksi / Floating Action Button (FAB)
Sembunyikan atau nonaktifkan tombol aksi jika user tidak memiliki permission:

```dart
// Contoh tombol Terbitkan SP baru:
if (SecureStorageService.instance.hasPermissionInMemory('warning_letter.create')) ...[
  FloatingActionButton.extended(
    onPressed: () => context.push(Routes.CREATE_WARNING_LETTER),
    icon: const Icon(LucideIcons.plus),
    label: const Text('Terbitkan SP'),
  ),
]
```

---

## 6. Standar Penanganan Error 403 Forbidden

Jika pengguna entah bagaimana memicu pemanggilan API mutasi tanpa izin, backend akan mengembalikan respons status **HTTP 403 Forbidden**:

```json
{
  "success": false,
  "message": "Forbidden: Anda tidak memiliki wewenang untuk fitur (approval.leave.action)"
}
```

### Standar Penanganan di Flutter:
1. `ApiClient` menangkap HTTP 403 dan melempar `ApiException(message: e.message, statusCode: 403)`.
2. BLoC memancarkan failure state dengan pesan error asli dari API.
3. UI menampilkan pesan kesalahan menggunakan dialog standar `AppDialogUtil.showError`:
   ```dart
   AppDialogUtil.showError(
     context,
     title: 'Akses Ditolak',
     message: state.message ?? 'Anda tidak memiliki wewenang untuk tindakan ini.',
   );
   ```
4. **Dilarang** melakukan *hardcode* pesan error statis, karena backend mengonfigurasi bahasa respons sesuai profil karyawan.
