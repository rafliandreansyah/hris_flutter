# Checklist Perbaikan Bug & Konsistensi HRIS Flutter

Diperbarui 2026-10-15. Item yang sudah selesai dihapus dari daftar ini; yang tersisa hanya pekerjaan yang belum selesai.
Belum dijalankan: `flutter analyze` dan `flutter test`. Kerjakan dari atas ke bawah.

## Prioritas 2: Stabilitas & penanganan error

- [ ] **Subscription tanpa `cancel()`.** `core/services/notification_service.dart` punya `FirebaseMessaging.onMessage.listen` dan `onMessageOpenedApp.listen` (baris ~141 dan ~147). Batalkan saat service dihentikan, atau dokumentasikan bila memang singleton seumur app.
- [ ] **`mounted` belum dicek setelah `await`.** Masih perlu ditambahkan di: `resignation_screen.dart`, `pdf_viewer_screen.dart`, `schedule_location_picker_modal.dart`, `overtime_detail_screen.dart`, `leave_detail_screen.dart`, `warning_letter_detail_screen.dart`, `attendance_logs_screen.dart`, `activity_filter_bottom_sheet.dart`.
- [ ] **`int.parse` jam shift belum aman.** `attendance/data/models/attendance_detail_model.dart` baris ~183-193. Sudah di dalam try, tetapi ganti ke `tryParse` dan tangani `null`.
- [ ] **Uji router guard di device.** Deep link dan notifikasi saat sesi sudah habis belum diuji.

## Prioritas 3: Konsistensi terhadap `.agents/rules/flutter_bloc_standards.md`

- [ ] **Warna hardcoded.** Sekitar 458 literal `Color(0xFF...)` tersisa di 86 file (di luar `app_colors.dart`, `app_theme*`, `gen/`, dan `l10n/`). Pemakaian `Colors.*` sekitar 4.470 kemunculan belum dimigrasi. Putuskan dulu apakah warna yang belum punya token perlu ditambahkan ke `AppColors`.
- [ ] **URL gambar di kode.** Masih ada di `activity/data/models/activity_item.dart`, `employee/data/models/employee_directory_item.dart`, `core/widgets/app_photo_picker_card.dart`, dan `employee/presentation/widgets/account_settings_bottom_sheet.dart`. Pindahkan ke konstanta atau config.
- [ ] **Konstanta attendance ganda.** `ApiEndpoints.attendanceLogs = '/attendances'` sama dengan `attendances`. Sisakan satu per fungsi, lalu cek pemakaiannya.
- [ ] **pubspec.yaml.** `alice`, `alice_dio`, dan `pretty_dio_logger` masih di `dependencies` karena dipakai `logging_interceptor.dart` dan `alice_service.dart`. Pisahkan dulu kode debug-nya. `flutter_gen_runner` belum diberi versi. `dependency_overrides: material_ui: 1.2.0` belum diverifikasi.
- [ ] **Test untuk perbaikan terbaru belum ada.** Tambahkan test untuk `resolveFileUrl`, `ActivityDetailBloc` tanpa fallback sample, dan `LiveTrackingBloc` reset filter.

## Verifikasi API (cross-check dengan `muratech_hris_server`)

- [ ] **Pembacaan `code` di `ApiException`.** Server kini mengirim `code` di semua error, tetapi Flutter masih memakai `errorCode` di 8 tempat. Samakan.
- [ ] **Pesan 409.** Approve atau disburse yang ditolak karena sudah diproses sekarang mengembalikan 409. Pastikan Flutter menampilkan pesannya.
- [ ] **Uji alur 401 dari token kedaluwarsa di device.** Server sudah mengeluarkan JWT dengan `exp`, tetapi alurnya belum diuji langsung.

## Perintah verifikasi yang disarankan

- `flutter analyze`
- `flutter test`
- `grep -rn "Color(0xFF" lib` untuk memantau sisa warna hardcoded
