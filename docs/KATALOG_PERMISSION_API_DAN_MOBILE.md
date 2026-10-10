# 📖 Katalog Lengkap Hak Akses & Permission (Backend API & Mobile App)

Dokumen ini merupakan referensi resmi dan terpadu mengenai seluruh kode wewenang fungsional (*Functional Permissions*), sistem otorisasi multi-layer, pemetaan endpoint backend (`muratech_hris_server`), serta implementasi proteksi dan adaptasi UI pada aplikasi mobile (`hris_flutter`).

---

## 🏛️ 1. Arsitektur Otorisasi Tiga Lapis (Defense in Depth)

Sistem MURATECH HRIS memisahkan otorisasi menjadi 3 lapisan independen:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        3 LAPISAN OTORISASI HRIS                        │
├──────────────────┬───────────────────────┬─────────────────────────────┤
│ 1. MENU ACCESS   │ 2. FUNCTIONAL PERMS   │ 3. DATA SCOPE               │
│ (Navigasi Modul) │ (Wewenang Aksi/Fitur) │ (Batasan Baris Data di DB)  │
├──────────────────┼───────────────────────┼─────────────────────────────┤
│ • GET /auth/menus│ • GET /auth/profile   │ • Prisma Scoped Query       │
│ • Menentukan     │ • Menentukan tombol   │ • Menentukan data bawahan,  │
│   modul mana     │   Setujui, Tolak,     │   satu divisi, satu cabang, │
│   yang tampil di │   Cairkan Dana, dsb.  │   atau lintas perusahaan.   │
│   Bento Grid     │ • Evaluasi O(1) via   │ • Diinjeksi otomatis via    │
│   Dashboard.     │   In-Memory Cache.    │   getScopedEmployeeWhere.   │
└──────────────────┴───────────────────────┴─────────────────────────────┘
```

### Prinsip Keamanan & User Experience:
1. **API adalah Security Boundary Mutlak**:
   - Jika pengguna tidak memiliki wewenang yang dipersyaratkan, Backend API wajib menolak permintaan dengan **HTTP 403 Forbidden**.
2. **Mobile App Mengadaptasi UX (Adaptive UX)**:
   - **Hide Action Button**: Tombol *Setujui*, *Tolak*, *Cairkan Dana*, atau *Terbitkan SP* disembunyikan jika izin tidak ada di memori.
   - **Context-Aware Tabs**: Pengguna tanpa hak akses approver diarahkan langsung ke tampilan data pribadi tanpa menampilkan tab persetujuan tim yang kosong / 403.
   - **Smart Navigation**: Klik menu pada Dashboard (misal: "Jadwal Kerja") mengarahkan langsung ke jadwal kerja pribadi user (`Routes.WORK_SCHEDULE`), bukan ke halaman seleksi rekan kerja yang berisiko memicu 403.

---

## 🔑 2. Matriks Katalog Permission: Backend API & Mobile Client

Setiap permission di bawah memiliki konstanta resmi di:
- **Backend API**: `src/core/constant/permissions.ts` (`PERMISSIONS.<KEY>`)
- **Mobile Client**: `lib/core/constants/app_permissions.dart` (`AppPermissions.<camelCase>`)

---

### A. Modul Izin & Cuti (Leave & Time Off)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `approval.leave.view` | `APPROVAL_LEAVE_VIEW` | `approvalLeaveView` | `GET /leave-request?approver=true` | Membuka tab "Persetujuan Tim" pada daftar cuti |
| `approval.leave.action`| `APPROVAL_LEAVE_ACTION`| `approvalLeaveAction` | `POST /leave-request/:id/approve` | Menampilkan tombol **Setujui** & **Tolak** di `LeaveDetailScreen` |
| `leave.manage` | `LEAVE_MANAGE` | `leaveManage` | `POST /leave-request` (koreksi langsung) | Koreksi cuti tanpa flow approval |
| `report.leave.view` | `REPORT_LEAVE_VIEW` | `reportLeaveView` | `GET /report/leaves` | Rekapitulasi laporan cuti perusahaan |
| `leave_balance.view` | `LEAVE_BALANCE_VIEW` | - | `GET /leave-balance` | Melihat kuota sisa cuti tahunan |
| `leave_balance.adjust`| `LEAVE_BALANCE_ADJUST`| - | `POST /leave-balance/adjust` | Koreksi manual kuota saldo cuti oleh HRD |

---

### B. Modul Lembur (Overtime)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `approval.overtime.view` | `APPROVAL_OVERTIME_VIEW` | `approvalOvertimeView` | `GET /overtime?approver=true` | Membuka tab "Persetujuan Tim" pada daftar lembur |
| `approval.overtime.action`| `APPROVAL_OVERTIME_ACTION`| `approvalOvertimeAction` | `POST /overtime/:id/approve` | Menampilkan tombol **Setujui** & **Tolak** di `OvertimeDetailScreen` |
| `overtime.manage` | `OVERTIME_MANAGE` | `overtimeManage` | `POST /overtime/direct` | Manajemen lembur langsung tanpa persetujuan berjenjang |
| `report.overtime.view` | `REPORT_OVERTIME_VIEW` | `reportOvertimeView` | `GET /report/overtimes` | Rekapitulasi laporan lembur karyawan |

---

### C. Modul Absensi & Permohonan Absen Luar (Attendance)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `approval.attendance.view` | `APPROVAL_ATTENDANCE_VIEW` | `approvalAttendanceView` | `GET /attendance-request?approver=true` | Membuka tab permohonan absen luar kantor bawahan |
| `approval.attendance.action`| `APPROVAL_ATTENDANCE_ACTION`| `approvalAttendanceAction` | `POST /attendance-request/:id/approve` | Menampilkan tombol **Setujui** & **Tolak** di `AttendanceRequestDetailScreen` |
| `attendance.manage` | `ATTENDANCE_MANAGE` | `attendanceManage` | `POST /attendance/manual` | Koreksi manual log kehadiran karyawan |
| `report.attendance.view` | `REPORT_ATTENDANCE_VIEW` | `reportAttendanceView` | `GET /report/attendances` | Melihat log presensi tim di `AttendanceLogsScreen` |

---

### D. Modul Aktivitas Harian (Employee Activity)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `report.activity.view` | `REPORT_ACTIVITY_VIEW` | `reportActivityView` | `GET /activity?approver=true` | Melihat feed aktivitas tim pada tab "Tim Saya" di `ActivityScreen` |
| `activity.manage` | `ACTIVITY_MANAGE` | `activityManage` | `POST /activity/plan` | Menugaskan rencana aktivitas (*planned activity*) ke bawahan |

---

### E. Modul Klaim & Kasbon (Reimbursement & Cash Advance)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `reimbursement.create` | `REIMBURSEMENT_CREATE` | `reimbursementCreate` | `POST /reimbursement`, `POST /cash-advance` | Tombol FAB **Ajukan Klaim / Kasbon** |
| `reimbursement.view` | `REIMBURSEMENT_VIEW` | `reimbursementView` | `GET /reimbursement`, `GET /cash-advance` | Melihat riwayat pengeluaran & nota |
| `approval.reimbursement.manager`| `APPROVAL_REIMBURSEMENT_MANAGER`| `approvalReimbursementManager` | `POST /reimbursement/:id/approve` | Menampilkan tombol **Setujui** & **Tolak** level atasan |
| `approval.reimbursement.finance`| `APPROVAL_REIMBURSEMENT_FINANCE`| `approvalReimbursementFinance` | `POST /reimbursement/:id/disburse` | Menampilkan tombol **Cairkan Dana (Kasir/Finance)** |
| `reimbursement.disburse` | `REIMBURSEMENT_DISBURSE` | - | `POST /cash-advance/:id/disburse` | Pencairan kasbon fisik / bank transfer |
| `reimbursement.settle_refund` | `REIMBURSEMENT_SETTLE_REFUND` | - | `POST /cash-advance/:id/refund` | Verifikasi pengembalian sisa kelebihan kasbon |
| `report.reimbursement.view` | `REPORT_REIMBURSEMENT_VIEW` | `reportReimbursementView` | `GET /report/reimbursements` | Rekapitulasi keuangan operasional |

---

### F. Modul Jadwal Kerja & Shift (Work Schedule)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `work_schedule.view` | `WORK_SCHEDULE_VIEW` | `workScheduleView` | `GET /work-schedule/accessible-employees` | Menampilkan ikon grup di AppBar `WorkScheduleScreen` untuk melihat jadwal rekan kerja |
| `work_schedule.assign` | `WORK_SCHEDULE_ASSIGN` | `workScheduleAssign` | `POST /work-schedule/assign` | Menetapkan shift kerja pada kalender |

---

### G. Modul Slip Gaji (Payroll)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `payroll.slip.view` | `PAYROLL_SLIP_VIEW` | `payrollSlipView` | `GET /payroll/accessible-employees` | Membuka tab "Slip Gaji Tim" di `PayrollScreen`. Karyawan biasa hanya melihat slip pribadinya |
| `payroll.generate` | `PAYROLL_GENERATE` | - | `POST /payroll/generate` | Kalkulasi penggajian bulanan otomatis |
| `payroll.remuneration.view` | `PAYROLL_REMUNERATION_VIEW` | - | `GET /payroll/remuneration` | Melihat master komponen gaji pokok & tunjangan |
| `payroll.remuneration.manage`| `PAYROLL_REMUNERATION_MANAGE`| - | `POST /payroll/remuneration` | Mengubah nominal gaji & tunjangan karyawan |

---

### H. Modul Pengunduran Diri (Resignation & Offboarding)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `resignation.create` | `RESIGNATION_CREATE` | `resignationCreate` | `POST /resignation` | Mengajukan resign mandiri di `CreateResignationScreen` |
| `resignation.view` | `RESIGNATION_VIEW` | `resignationView` | `GET /resignation/subordinates` | Melihat daftar bawahan yang mengajukan pengunduran diri |
| `approval.resignation.manager`| `APPROVAL_RESIGNATION_MANAGER`| `approvalResignationManager` | `POST /resignation/:id/manager-approval` | Menampilkan form wawancara 1-on-1 manajer |
| `approval.resignation.hr` | `APPROVAL_RESIGNATION_HR` | `approvalResignationHr` | `POST /resignation/:id/hr-approval` | Checklist clearance aset & hak pesangon/cuti |
| `resignation.settle` | `RESIGNATION_SETTLE` | - | `POST /resignation/:id/settle` | Finalisasi offboarding & penonaktifan akun karyawan |

---

### I. Modul Fasilitas & Aset (Asset Management)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `asset.my_assets` | `ASSET_MY_ASSETS` | `assetMyAssets` | `GET /asset/my-assets` | Melihat aset yang dipegang & inisiasi alih tangan di mobile |
| `asset.view` | `ASSET_VIEW` | `assetView` | `GET /asset` | Melihat katalog master aset kantor |
| `asset.create` | `ASSET_CREATE` | - | `POST /asset` | Input aset baru perusahaan |
| `asset.handover` | `ASSET_HANDOVER` | - | `POST /asset/handover` | Verifikasi serah terima fisik aset |
| `asset.return` | `ASSET_RETURN` | - | `POST /asset/return` | Penerimaan kembali aset saat resign / rotasi |

---

### J. Modul Surat Peringatan (Warning Letter)

| Kode Permission | Konstanta Backend | Konstanta Mobile | Endpoint Backend Terkait | Aksi & Adaptasi Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `warning_letter.view` | `WARNING_LETTER_VIEW` | `warningLetterView` | `GET /warning-letter` | Melihat daftar arsip surat peringatan |
| `warning_letter.create`| `WARNING_LETTER_CREATE`| `warningLetterCreate`| `POST /warning-letter` | Menerbitkan surat peringatan (SP1, SP2, SP3) |
| `warning_letter.edit` | `WARNING_LETTER_EDIT` | - | `PUT /warning-letter/:id` | Mengoreksi data surat peringatan |
| `warning_letter.revoke`| `WARNING_LETTER_REVOKE`| - | `POST /warning-letter/:id/revoke` | Mencabut status masa berlaku SP |

---

## 👥 3. Standar Matriks Peran Pengguna (Role vs Default Permissions)

| Peran (Role) | Ruang Lingkup Data (*Data Scope*) | Deskripsi Tanggung Jawab & Hak Akses |
| :--- | :--- | :--- |
| **`user`** (Pegawai Biasa) | `SELF` | Mengajukan absensi, cuti, lembur, aktivitas, reimbursement, dan resign sendiri. Hanya melihat slip gaji dan jadwal kerja miliknya. |
| **`approver`** (Manager / Spv) | `SUBORDINATES` | Seluruh hak `user` + wewenang melihat pengajuan bawahan dan tombol **Setujui / Tolak** (cuti, lembur, koreksi absen, wawancara resign 1-on-1). |
| **`finance`** (Kasir / Akuntan) | `COMPANY` | Hak approval tahap 2 klaim reimbursement dinas & pencairan dana (*disburse*) kasbon/nota. |
| **`hr_admin`** (HRD Operasional)| `COMPANY` | Hak kelola data karyawan, jadwal shift, kalender libur, penerbitan SP, approval cuti/lembur darurat, dan clearance resign. |
| **`admin_company`** (Pimpinan) | `COMPANY` | Hak akses penuh atas seluruh modul dan laporan pada lingkup satu perusahaan bersangkutan. |
| **`admin_system`** (Superadmin) | `ALL` | **Bypass Otorisasi**. Akses multi-tenant, billing, langganan, manajemen master menu, dan permission. |

---

## 💻 4. Panduan Implementasi di Aplikasi Mobile (`hris_flutter`)

### 1. Inisialisasi Cache Permission Saat Login / Profile Fetch
Saat memuat profile karyawan (`GET /api/v1/auth/profile`), permissions disimpan ke dalam `SecureStorageService`:

```dart
// hris_flutter/lib/core/storage/secure_storage_service.dart
await SecureStorageService.instance.saveUserPermissions(profile.permissions);
```

### 2. Pengecekan Cepat Sinkron (O(1) In-Memory)
Gunakan `hasPermissionInMemory` atau `hasAnyPermissionInMemory` pada method `build` widget tanpa perlu `await`:

```dart
// Contoh di LeaveDetailScreen:
final hasApprovalPermission = SecureStorageService.instance
    .hasPermissionInMemory(AppPermissions.approvalLeaveAction);

if (state.isApprover && hasApprovalPermission && detail.isPending) {
  return _buildApprovalActionBar();
}
```

### 3. Pengecekan Tab Persetujuan Tim
Jika user tidak memiliki hak akses approver, jangan tampilkan Tab Persetujuan Tim yang memicu error 403:

```dart
final canViewTeam = SecureStorageService.instance.hasAnyPermissionInMemory([
  AppPermissions.approvalLeaveAction,
  AppPermissions.approvalLeaveView,
  AppPermissions.reportLeaveView,
]);

// Di dalam body:
child: canViewTeam 
    ? TabBarView(children: [_myTab(), _teamTab()]) 
    : _myTab();
```

---

## 🛡️ 5. Panduan Implementasi di Backend API (`muratech_hris_server`)

### Proteksi Endpoint via Hono Middleware
Setiap endpoint API yang memutasi data atau melihat data orang lain wajib diproteksi:

```typescript
import { requirePermission, requireAnyPermission } from '@/middlewares/permission'
import { PERMISSIONS } from '@/core/constant/permissions'

// Proteksi tunggal
app.post(
  '/reimbursement/:id/disburse',
  requirePermission(PERMISSIONS.APPROVAL_REIMBURSEMENT_FINANCE),
  ReimbursementController.disburseClaim
)

// Proteksi multi-izin
app.get(
  '/report/activities',
  requireAnyPermission([
    PERMISSIONS.REPORT_ACTIVITY_VIEW,
    PERMISSIONS.ACTIVITY_MANAGE,
  ]),
  ActivityController.getAllActivity
)
```

---

*Dokumen ini diperbarui secara berkala dan menjadi acuan utama sinkronisasi fitur antara Web Dashboard dan Mobile Client.*
