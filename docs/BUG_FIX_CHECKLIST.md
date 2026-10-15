# Checklist Perbaikan Bug & Konsistensi HRIS Flutter

Diperbarui 2026-10-15. Item selesai dihapus; hanya pekerjaan yang belum selesai.
Belum dijalankan (tidak tersedia di sandbox): `flutter analyze` dan `flutter test`. Jalankan keduanya dulu, karena ada ~485 perubahan massal (`const AppColors.x` -> `AppColors.x`) yang belum dikompilasi.

## Verifikasi

- [ ] `flutter analyze` dan `flutter test`, perbaiki error yang muncul.
- [ ] Tampilkan pesan 409 (`ApiException.message`/`.code`) di layar approve/disburse; `ApiException` sudah menyediakannya, UI belum diuji.
- [ ] Uji di device: router guard (deep link/notifikasi saat sesi habis) dan alur 401 dari token kedaluwarsa.

## Konsistensi (`.agents/rules/flutter_bloc_standards.md`)

- [ ] **Warna hardcoded.** Sisa ~458 `Color(0xFF...)` di 86 file dan ~4.470 `Colors.*`. Putuskan token baru di `AppColors` lebih dulu.
- [ ] **URL gambar di kode:** `activity_item.dart`, `employee_directory_item.dart`, `app_photo_picker_card.dart`, `account_settings_bottom_sheet.dart`. Pindahkan ke konstanta/config.
- [ ] **Konstanta ganda** `ApiEndpoints.attendanceLogs` vs `attendances` (cek pemakaian dulu).
- [ ] **pubspec.yaml:** `alice`, `alice_dio`, `pretty_dio_logger` masih di `dependencies`; `flutter_gen_runner` tanpa versi; override `material_ui: 1.2.0` perlu diverifikasi lewat `flutter pub deps`.
- [ ] **Test baru:** `resolveFileUrl`, `ActivityDetailBloc` tanpa fallback sample, `LiveTrackingBloc` reset filter.
- [ ] Kosmetik: indentasi blok `catch (silentError)`.
