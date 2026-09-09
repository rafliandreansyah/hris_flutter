# ✅ Checklist Slicing Halaman — Google Stitch → Flutter (Oasish HRIS)

> Dokumen tugas slicing UI dari desain Google Stitch ke aplikasi Flutter **Muratech HRIS (Oasish)**.
> Legend: `[x]` = sudah di-slicing · `[ ]` = belum (task) · `[~]` = sebagian.

## ⚠️ Catatan Sumber Desain

Desain mengacu pada project Stitch aktif berjudul **"Oasish Website"** (project id `9700142064912906631`).

> Project id `17152850901645837896` (yang tertulis di `docs/DESIGN_SYSTEM.md`) **tidak ditemukan** di akun Stitch.
> Yang benar & aktif adalah `9700142064912906631` ("Oasish Website"). Silakan konfirmasi bila desain mobile ada di project lain.

Jumlah screen desain: **26** (sudah dikurangi asset non-halaman: logo "Acme Inc.", "DESIGN.md", dan gambar interior kantor). Mayoritas adalah desain **web/desktop admin** (2560px); aplikasi Flutter bersifat **mobile**, sehingga pemetaan dilakukan per-domain fitur.

---

## 1. Sudah Di-Slicing (Done)

| # | Screen Desain (Stitch) | Implementasi Flutter | File |
|---|---|---|---|
| [x] | Login - HRIS Web | `LoginScreen` | `lib/features/auth/presentation/pages/login_screen.dart` |
| [x] | Karyawan - HRIS Web | `EmployeeDirectoryScreen` | `lib/features/employee/presentation/pages/employee_directory_screen.dart` |
| [x] | Detail Karyawan - HRIS Web | `EmployeeDetailScreen` | `lib/features/employee/presentation/pages/employee_detail_screen.dart` |
| [x] | Detail Kehadiran - Budi Santoso | `AttendanceDetailScreen` | `lib/features/attendance/presentation/pages/attendance_detail_screen.dart` |
| [x] | Laporan Kehadiran - HRIS Web | `AttendanceLogsScreen` + `EmployeeAttendanceLogsScreen` | `lib/features/attendance/presentation/pages/attendance_logs_screen.dart`, `employee_attendance_logs_screen.dart` |
| [x] | Laporan Aktivitas Karyawan — HRIS Web / Mint HR / (Full Width) | `ActivityScreen` | `lib/features/activity/presentation/pages/activity_screen.dart` |
| [x] | Detail Laporan Aktivitas - Rafli Andreansyah | `ActivityDetailScreen` | `lib/features/activity/presentation/pages/activity_detail_screen.dart` |

Ekstra (mobile-only, belum ada padanan desain web tapi **sudah** dibangun):
- Splash Screen — `lib/features/splash/presentation/pages/splash_screen.dart`
- Reset Password — `lib/features/auth/presentation/pages/reset_password_screen.dart`
- Dashboard / Home — `lib/features/dashboard/presentation/pages/dashboard_screen.dart`
- Create Activity (form input) — `lib/features/activity/presentation/pages/create_activity_screen.dart`
- Attendance (check-in utama) — `lib/features/attendance/presentation/pages/attendance_screen.dart`

**Total selesai: 7 screen desain + 5 screen mobile = 12 layar.**

---

## 2. Belum Di-Slicing (Task)

### A. Payroll / Penggajian
- [ ] Laporan Penggajian - HRIS Web  → module baru `payroll` (list + laporan gaji)
- [ ] Generate Payroll Run - HRIS Web  → form run payroll

### B. Cuti / Izin (Leave)
- [ ] Laporan Izin & Cuti - HRIS Web  → module `leave` (list request izin/cuti)
- [ ] Kebijakan Cuti - HRIS Web  → halaman info kebijakan cuti

### C. Lembur (Overtime)
- [ ] Laporan Lembur - HRIS Web  → module `overtime` (list + laporan lembur)

### D. Laporan Pegawai
- [ ] Detail Laporan Pegawai - Budi Santoso  → detail laporan/rekap per pegawai

### E. Hak Akses Menu (Role & Permission)
- [ ] Hak Akses Menu - Oasish HRIS  → daftar role/permission
- [ ] Hak Akses Menu (Updated Filter) - Oasish HRIS  → varian dg filter
- [ ] Assign Hak Akses Menu - Oasish HRIS  → form assign akses
- [ ] Detail Hak Akses Menu - Budi Santoso  → detail hak akses user
- [ ] Edit & Revoke Hak Akses - Budi Santoso  → edit/cabut akses

### F. Pengaturan (Settings)
- [ ] Settings - HRIS Web
- [ ] Settings - Mint HR
- [ ] System Settings - Mint HR
- [ ] Pengaturan Sistem - Mint HR
  → module `settings` (profil, sistem, notifikasi)

### G. Parsial (perlu penyempurnaan)
- [~] Detail Kehadiran (Dual Map) - Budi Santoso  → view "Dual Map" belum diimplementasikan di `AttendanceDetailScreen`

**Total task belum selesai: 17 (16 penuh + 1 parsial).**

---

## 3. Rekap

| Status | Jumlah |
|---|---|
| ✅ Sudah di-slicing | 7 screen desain |
| ☐ Belum di-slicing (penuh) | 16 |
| 🔶 Parsial | 1 |
| ➕ Layar mobile (tanpa desain web) | 5 (sudah build) |

Korelasi dengan menu dashboard (`quick_access_grid.dart`) yang masih "segera hadir":
**Overtime, Leave, Payroll, Schedule, Helpdesk** → belum ada screen-nya (Overtime/Leave/Payroll terpetakan ke task A–C di atas; Schedule & Helpdesk belum punya desain di Stitch).

---

## 4. Cara Menambah Task Baru

Saat screen baru selesai di-slicing, pindahkan baris dari seksi 2 → seksi 1 dan ganti `[ ]`/`[~]` menjadi `[x]` beserta path file Flutter-nya, mengacu standar di `docs/ARCHITECTURE.md` dan skill `flutter-bloc-development`.
