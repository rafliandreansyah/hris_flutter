# Pengujian Sistem (Testing Guide) — OASISH HRIS Mobile App (Flutter)

> **Cakupan**: arsitektur pengujian piramida 6-layer aplikasi mobile Flutter, unit testing (Model, Datasource, Repository), BLoC testing (`bloc_test`), widget & component testing (`WidgetTester`), End-to-End (E2E) testing dengan automasi native permission OS (**Patrol by LeanCode**), strategi mocking (`mocktail`), evaluasi coverage, dan quality gate pra-commit.
> **Terakhir diverifikasi terhadap kode**: Oktober 2026 (220+ file unit/widget test di `test/`, 20 skenario E2E di `integration_test/`).

---

## Daftar Isi

1. [Strategi & Piramida Pengujian Mobile](#1-strategi--piramida-pengujian-mobile)
2. [Menjalankan Pengujian (Commands)](#2-menjalankan-pengujian-commands)
3. [Unit Testing: Model, Datasource & Repository](#3-unit-testing-model-datasource--repository)
4. [BLoC Testing: State & Event Verification (`bloc_test`)](#4-bloc-testing-state--event-verification-bloc_test)
5. [Widget & UI Component Testing (`WidgetTester`)](#5-widget--ui-component-testing-widgettester)
6. [End-to-End (E2E) Testing dengan Patrol & Native OS Mocking](#6-end-to-end-e2e-testing-dengan-patrol--native-os-mocking)
7. [Standar Mocking & Test Helpers](#7-standar-mocking--test-helpers)
8. [Quality Gate & Continuous Integration (CI)](#8-quality-gate--continuous-integration-ci)

---

## 1. Strategi & Piramida Pengujian Mobile

Aplikasi **OASISH HRIS** menerapkan piramida pengujian berlapis untuk memastikan kestabilan kode, mencegah regresi, dan menjamin keandalan interaksi hardware native (Kamera, GPS Geofencing, Biometrik, Notifikasi OS):

```
                     ▲
                    / \
                   /   \
                  / E2E \       <-- Patrol & AndroidX Test Orchestrator
                 /-------\          (20 skenario integrasi native OS)
                / Widget  \     <-- WidgetTester & golden UI verification
               /-----------\        (Validasi form, cards, error state)
              /  BLoC Test  \   <-- bloc_test & mocktail
             /---------------\      (Verifikasi transisi state & event)
            /   Unit Testing  \ <-- test (Model JSON, Datasource, Repositories)
           /-------------------\
```

| Lapisan Tes | Framework / Tool | Lokasi Berkas | Tujuan Utama |
|---|---|---|---|
| **Unit Test** | `flutter_test`, `test` | `test/features/*/data/` | Serialisasi JSON DTO, konversi mata uang/tanggal, sanitasi data |
| **BLoC Test** | `bloc_test`, `mocktail` | `test/features/*/presentation/bloc/` | Memastikan event memicu urutan state yang tepat (*loading -> loaded/failure*) |
| **Widget Test** | `flutter_test` (`WidgetTester`) | `test/features/*/presentation/widgets/` | Rendering visual, validasi input, disable tombol saat loading |
| **E2E Integration** | `patrol`, `integration_test` | `integration_test/*_e2e_test.dart` | Alur kerja nyata di perangkat (izin OS, navigasi login hingga submit) |

---

## 2. Menjalankan Pengujian (Commands)

### 1. Menjalankan Seluruh Unit & Widget Tests
```bash
flutter test
```

### 2. Menjalankan Pengujian Spesifik per Modul
```bash
# Menjalankan pengujian fitur presensi saja
flutter test test/features/attendance/

# Menjalankan pengujian fitur cuti
flutter test test/features/leave/

# Menjalankan pengujian komponen global
flutter test test/core/widgets/
```

### 3. Menjalankan Analisis Statis Kode (Linter)
```bash
flutter analyze
```

### 4. Menjalankan Pengujian E2E Patrol
Pastikan emulator atau perangkat fisik Android/iOS terhubung (`adb devices` atau `xcrun simctl list`):

```bash
# Uji satu modul (contoh: Login & Dashboard)
patrol test -t integration_test/auth_e2e_test.dart \
  --dart-define=E2E_EMAIL=karyawan@muratech.com \
  --dart-define=E2E_PASSWORD=PasswordAman2026!

# Menjalankan seluruh test bundle E2E
patrol test -t integration_test/test_bundle.dart
```

---

## 3. Unit Testing: Model, Datasource & Repository

Unit test berfokus pada logika murni tanpa ketergantungan framework UI:

```dart
// Contoh: test/features/attendance/data/models/attendance_model_test.dart
void main() {
  group('AttendanceModel JSON Serialization', () {
    test('harus berhasil mem-parse JSON valid dari backend', () {
      final json = {
        'id': 'att-123',
        'clock_in': '2026-10-17T08:00:00Z',
        'is_mocked': false,
        'status': 'ON_TIME',
      };

      final model = AttendanceModel.fromJson(json);

      expect(model.id, equals('att-123'));
      expect(model.isMocked, isFalse);
      expect(model.status, equals('ON_TIME'));
    });
  });
}
```

---

## 4. BLoC Testing: State & Event Verification (`bloc_test`)

Setiap BLoC wajib memiliki cakupan tes lengkap menggunakan `blocTest` dari `package:bloc_test`:

```dart
// Contoh pola penulisan:
blocTest<LeaveBloc, LeaveState>(
  'mengeluarkan [LeaveLoading, LeaveLoaded] saat FetchLeaveRequests berhasil',
  build: () {
    when(() => mockLeaveRepository.getMyRequests())
        .thenAnswer((_) async => [sampleLeaveRequest]);
    return LeaveBloc(leaveRepository: mockLeaveRepository);
  },
  act: (bloc) => bloc.add(const FetchLeaveRequests()),
  expect: () => [
    const LeaveLoading(),
    LeaveLoaded(requests: [sampleLeaveRequest]),
  ],
  verify: (_) {
    verify(() => mockLeaveRepository.getMyRequests()).called(1);
  },
);

blocTest<LeaveBloc, LeaveState>(
  'mengeluarkan [LeaveLoading, LeaveFailure] saat Repository melempar ApiException',
  build: () {
    when(() => mockLeaveRepository.getMyRequests())
        .thenThrow(ApiException(message: 'Koneksi terputus', statusCode: 500));
    return LeaveBloc(leaveRepository: mockLeaveRepository);
  },
  act: (bloc) => bloc.add(const FetchLeaveRequests()),
  expect: () => [
    const LeaveLoading(),
    const LeaveFailure(message: 'Koneksi terputus', statusCode: 500),
  ],
);
```

---

## 5. Widget & UI Component Testing (`WidgetTester`)

Widget testing memastikan komponen visual merender teks, warna token, dan merespons interaksi pengguna dengan benar tanpa meluncurkan aplikasi penuh:

1. **Aturan Uji Tombol Loading**:
   Memastikan tombol `AppButton` merender `CircularProgressIndicator` saat `isLoading: true` dan memblokir ketukan `onPressed`.
2. **Aturan Uji Dialog Form**:
   Memverifikasi bahwa form validasi memunculkan pesan error ketika field wajib kosong.
3. **Penyediaan Mock Dependency**:
   Gunakan helper pengujian `test/helpers/pump_app.dart` untuk membungkus widget di dalam `MaterialApp`, `AppLocalizations`, dan tema global `AppTheme.light`.

---

## 6. End-to-End (E2E) Testing dengan Patrol & Native OS Mocking

Aplikasi mobile HRIS memiliki ketergantungan tinggi pada dialog izin sistem operasi native (*native OS permission dialogs*). Patrol memecahkan limitasi `flutter_test` standar dengan mengotomasi interaksi OS:

```dart
// integration_test/attendance_e2e_test.dart
patrolTest('Alur presensi Clock-In dengan izin GPS dan Kamera', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());

  // Otomasi native permission Android/iOS
  if (await $.native.isPermissionDialogVisible()) {
    await $.native.grantPermissionWhenInUse();
  }

  // Interaksi antarmuka Flutter
  await $(#btnClockIn).tap();
  expect($('Presensi Berhasil'), findsOneWidget);
});
```

### Isolasi State Antar Pengujian (Clear Package Data):
Diatur di `android/app/build.gradle.kts`:
```kotlin
testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
testInstrumentationRunnerArguments["clearPackageData"] = "true"
testOptions {
    execution = "ANDROIDX_TEST_ORCHESTRATOR"
}
```
Setiap kali satu skenario tes selesai, memori dan penyimpanan lokal aplikasi dihapus bersih, mencegah kebocoran sesi login (*state leakage*) antar skenario tes.

---

## 7. Standar Mocking & Test Helpers

1. **Gunakan `mocktail`**: Lebih disukai dibanding `mockito` karena tidak memerlukan generasi kode `build_runner` untuk membuat mock class sederhana.
2. **Dilarang Menelan Error**: Semua mock yang menyimulasikan kegagalan jaringan wajib melempar instans `ApiException` resmi, bukan `Exception` generik mentah.
3. **Register Fallback Values**: Jika metode mock menerima objek parameter kustom, daftarkan `registerFallbackValue(FakeObject())` di blok `setUpAll`.

---

## 8. Quality Gate & Continuous Integration (CI)

Sebelum mengajukan pull request atau mem-build rilis biner, setiap developer wajib melewati pintu gerbang kualitas (*Quality Gate*):

```bash
# 1. Pastikan tidak ada lint error atau warning
flutter analyze

# 2. Pastikan 220+ unit test lulus 100%
flutter test

# 3. Format kode sesuai standar Dart
dart format --set-exit-if-changed lib test
```

> Panduan skenario uji mendalam per modul dan checklist operasional tersedia di:
> - Detail skenario E2E & Checklist: [`TESTING_FLOW_AND_CHECKLIST.md`](./TESTING_FLOW_AND_CHECKLIST.md)
> - Panduan deploy mobile: [DEPLOYMENT.md](./DEPLOYMENT.md)
> - Arsitektur aplikasi: [ARCHITECTURE.md](./ARCHITECTURE.md)
