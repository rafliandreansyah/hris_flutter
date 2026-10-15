import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/main.dart' as app;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

/// Helper bersama untuk seluruh E2E test (Patrol).
///
/// Prasyarat akun E2E:
///  * Bahasa profil = Indonesia (label tab/judul diverifikasi dalam Bahasa).
///  * Akun memiliki akses ke menu yang diuji (kalau tidak, test GAGAL dengan
///    pesan jelas — bukan lolos diam-diam).
///
/// Kredensial TIDAK boleh di-hardcode. Berikan lewat `--dart-define`:
///   patrol test --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
class E2EConfig {
  static const String email = String.fromEnvironment('E2E_EMAIL');
  static const String password = String.fromEnvironment('E2E_PASSWORD');

  static void ensureCredentials() {
    if (email.isEmpty || password.isEmpty) {
      fail(
        'E2E_EMAIL / E2E_PASSWORD belum diberikan. Jalankan dengan '
        '--dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...',
      );
    }
  }
}

/// True bila [finder] ada DAN bisa di-tap (berada di route paling atas).
bool isShown(Finder finder) => finder.hitTestable().evaluate().isNotEmpty;

/// Pump bertahap tanpa menunggu animasi selesai (aman untuk shimmer/spinner).
Future<void> pumpFor(
  PatrolIntegrationTester $,
  Duration duration, {
  Duration step = const Duration(milliseconds: 100),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await $.pump(step);
    elapsed += step;
  }
}

/// Menunggu sampai [finder] tampil; GAGAL (bukan skip) jika timeout.
Future<void> waitFor(
  PatrolIntegrationTester $,
  Finder finder, {
  required String reason,
  Duration timeout = const Duration(seconds: 30),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    if (isShown(finder)) return;
    await $.pump(const Duration(milliseconds: 200));
    elapsed += const Duration(milliseconds: 200);
  }
  fail('Timeout ${timeout.inSeconds}s menunggu: $reason');
}

/// Menunggu sampai [finder] hilang; GAGAL jika masih ada setelah timeout.
Future<void> waitGone(
  PatrolIntegrationTester $,
  Finder finder, {
  required String reason,
  Duration timeout = const Duration(seconds: 30),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    if (finder.evaluate().isEmpty) return;
    await $.pump(const Duration(milliseconds: 200));
    elapsed += const Duration(milliseconds: 200);
  }
  fail('Timeout ${timeout.inSeconds}s menunggu hilang: $reason');
}

/// Menangani dialog izin native (notifikasi/lokasi/kamera) bila sedang tampil.
Future<void> grantPermissionIfVisible(PatrolIntegrationTester $) async {
  try {
    if (await $.platformAutomator.mobile.isPermissionDialogVisible(
      timeout: const Duration(milliseconds: 500),
    )) {
      await $.platformAutomator.mobile.grantPermissionWhenInUse();
    }
  } catch (_) {
    // Platform automator tidak tersedia (mis. dijalankan di desktop).
  }
}

/// Menjalankan aplikasi, melayani dialog izin yang muncul SELAMA inisialisasi
/// (`main()` menunggu izin notifikasi sebelum `runApp`), lalu menunggu layar
/// awal (Login atau Dashboard bila sesi masih tersimpan).
Future<void> launchApp(PatrolIntegrationTester $) async {
  var mainDone = false;
  final started = app.main();
  started.whenComplete(() => mainDone = true);

  var elapsed = Duration.zero;
  const limit = Duration(seconds: 60);
  while (!mainDone && elapsed < limit) {
    await grantPermissionIfVisible($);
    await $.pump(const Duration(milliseconds: 300));
    elapsed += const Duration(milliseconds: 800);
  }
  if (!mainDone) fail('app.main() tidak selesai dalam ${limit.inSeconds}s');
  await started;

  var waited = Duration.zero;
  while (!isShown(find.byType(LoginScreen)) &&
      !isShown(find.byType(DashboardScreen))) {
    if (waited >= const Duration(seconds: 40)) {
      fail('Timeout menunggu LoginScreen/DashboardScreen setelah app start');
    }
    await grantPermissionIfVisible($);
    await $.pump(const Duration(milliseconds: 300));
    waited += const Duration(milliseconds: 300);
  }
}

/// Login memakai kredensial dari `--dart-define` bila masih di halaman Login.
/// Selesai ketika Dashboard tampil dan Quick Access Grid sudah termuat.
Future<void> loginIfNeeded(PatrolIntegrationTester $) async {
  if (isShown(find.byType(LoginScreen))) {
    E2EConfig.ensureCredentials();
    await $.tester.enterText(
      find.byType(TextField).first,
      E2EConfig.email,
    );
    await $.tester.enterText(
      find.byType(TextField).last,
      E2EConfig.password,
    );
    await $.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.text('Login'));
    await $.pump();
  }

  await waitFor(
    $,
    find.byType(DashboardScreen),
    reason: 'DashboardScreen setelah login (kredensial salah / backend down?)',
    timeout: const Duration(seconds: 45),
  );
  await waitFor(
    $,
    find.byType(QuickAccessGrid),
    reason: 'QuickAccessGrid termuat (menu dari GET /auth/menus)',
    timeout: const Duration(seconds: 45),
  );
}

/// Launch + login dalam satu panggilan; kembalinya selalu di Dashboard siap.
Future<void> launchAndLogin(PatrolIntegrationTester $) async {
  await launchApp($);
  await loginIfNeeded($);
}

/// Membuka modul dari Quick Access Grid dan menunggu [screen] tampil.
/// GAGAL jika menu tidak tersedia untuk akun E2E.
Future<void> openMenu(
  PatrolIntegrationTester $,
  String menuTitle, {
  required Type screen,
}) async {
  final tile = find.descendant(
    of: find.byType(QuickAccessGrid),
    matching: find.text(menuTitle),
  );
  if (tile.evaluate().isEmpty) {
    fail(
      'Menu "$menuTitle" tidak ada di Quick Access Grid. '
      'Pastikan akun E2E punya akses ke menu ini.',
    );
  }
  await $.tester.ensureVisible(tile.first);
  await $.pump(const Duration(milliseconds: 300));
  await $.tester.tap(tile.first);
  await $.pump();
  await waitFor(
    $,
    find.byType(screen),
    reason: 'layar $screen setelah menekan menu "$menuTitle"',
  );
}

/// Kembali satu layar lewat tombol back (ikon panah / BackButton).
Future<void> goBack(PatrolIntegrationTester $) async {
  final arrow = find.byIcon(LucideIcons.arrowLeft).hitTestable();
  final back = find.byType(BackButton).hitTestable();
  if (arrow.evaluate().isNotEmpty) {
    await $.tester.tap(arrow.last);
  } else if (back.evaluate().isNotEmpty) {
    await $.tester.tap(back.last);
  } else {
    fail('Tombol kembali tidak ditemukan pada layar saat ini');
  }
  await $.pump();
  await pumpFor($, const Duration(milliseconds: 600));
}

/// Kembali ke Dashboard dan memastikannya tampil.
Future<void> goBackToDashboard(PatrolIntegrationTester $) async {
  await goBack($);
  await waitFor(
    $,
    find.byType(DashboardScreen),
    reason: 'kembali ke DashboardScreen',
    timeout: const Duration(seconds: 10),
  );
}

/// Mengetuk tab berdasarkan label teks dan memastikan label tersebut tampil.
Future<void> tapTab(PatrolIntegrationTester $, String label) async {
  final tab = find.text(label).hitTestable();
  if (tab.evaluate().isEmpty) {
    fail('Tab "$label" tidak ditemukan (bahasa profil harus Indonesia)');
  }
  await $.tester.tap(tab.first);
  await $.pump();
  await pumpFor($, const Duration(milliseconds: 800));
}

/// Menunggu daftar selesai memuat: shimmer/spinner awal hilang dan salah satu
/// hasil (kartu [card] atau teks kosong) muncul. Mengembalikan true bila ada
/// minimal satu kartu.
Future<bool> waitForListLoaded(
  PatrolIntegrationTester $, {
  required Type card,
  Duration timeout = const Duration(seconds: 30),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    if (find.byType(card).evaluate().isNotEmpty) return true;
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        elapsed > const Duration(seconds: 3)) {
      // Tidak ada spinner & tidak ada kartu setelah jeda wajar = daftar kosong.
      return false;
    }
    await $.pump(const Duration(milliseconds: 250));
    elapsed += const Duration(milliseconds: 250);
  }
  return find.byType(card).evaluate().isNotEmpty;
}

/// Membuka & menutup filter bottom sheet standar. Penanda sheet terbuka adalah
/// tombol "Terapkan Filter" (ada di seluruh filter sheet); ditutup lewat
/// "Batal" bila tersedia, jika tidak lewat tap pada barrier.
Future<void> openAndCancelFilterSheet(PatrolIntegrationTester $) async {
  final filterIcon = find.byIcon(LucideIcons.slidersHorizontal).hitTestable();
  if (filterIcon.evaluate().isEmpty) {
    fail('Ikon filter (slidersHorizontal) tidak ditemukan');
  }
  await $.tester.tap(filterIcon.first);
  await $.pump();
  await waitFor(
    $,
    find.text('Terapkan Filter'),
    reason: 'filter bottom sheet terbuka',
    timeout: const Duration(seconds: 10),
  );

  final cancel = find.text('Batal').hitTestable();
  if (cancel.evaluate().isNotEmpty) {
    await $.tester.tap(cancel.last);
  } else {
    await $.tester.tapAt(const Offset(10, 60));
  }
  await $.pump();
  await waitGone(
    $,
    find.text('Terapkan Filter'),
    reason: 'filter bottom sheet tertutup',
    timeout: const Duration(seconds: 5),
  );
}

/// Tidak boleh ada state error generik pada layar daftar.
void expectNoErrorState() {
  expect(
    find.text('Coba Lagi'),
    findsNothing,
    reason: 'Daftar menampilkan state error (tombol "Coba Lagi")',
  );
}

/// Membuka kartu pertama pada daftar saat ini, memverifikasi salah satu
/// [detailScreens] tampil beserta kartu "INFORMASI PENGAJU" (standar AGENTS.md
/// #19), lalu kembali ke layar [screen].
Future<void> openFirstCardAndVerifyDetail(
  PatrolIntegrationTester $, {
  required Type card,
  required List<Type> detailScreens,
  required Type screen,
}) async {
  final target = find.byType(card).hitTestable();
  await $.tester.ensureVisible(target.first);
  await $.pump(const Duration(milliseconds: 300));
  await $.tester.tap(target.first);
  await $.pump();

  var elapsed = Duration.zero;
  while (!detailScreens.any((t) => isShown(find.byType(t)))) {
    if (elapsed >= const Duration(seconds: 30)) {
      fail('Layar detail ${detailScreens.join(' / ')} tidak tampil');
    }
    await $.pump(const Duration(milliseconds: 250));
    elapsed += const Duration(milliseconds: 250);
  }
  await waitFor(
    $,
    find.text('INFORMASI PENGAJU'),
    reason: 'kartu INFORMASI PENGAJU pada layar detail',
  );

  await goBack($);
  await waitFor($, find.byType(screen), reason: 'kembali ke daftar');
}

/// Skenario standar modul pengajuan 2-tab (Pengajuan Saya / Persetujuan Tim):
/// judul, kedua tab, daftar tiap tab (kartu → detail bila ada data, atau
/// tanpa error bila kosong), serta filter sheet.
Future<void> verifyRequestModule(
  PatrolIntegrationTester $, {
  required Type screen,
  required String screenTitle,
  required Type card,
  required List<Type> detailScreens,
  String leftTab = 'Pengajuan Saya',
  String rightTab = 'Persetujuan Tim',
}) async {
  expect(find.text(screenTitle), findsOneWidget);
  expect(find.text(leftTab), findsOneWidget);
  expect(find.text(rightTab), findsOneWidget);

  // Tab kiri (milik sendiri)
  var hasData = await waitForListLoaded($, card: card);
  expectNoErrorState();
  if (hasData) {
    await openFirstCardAndVerifyDetail(
      $,
      card: card,
      detailScreens: detailScreens,
      screen: screen,
    );
  }

  // Tab kanan (tim/approver)
  await tapTab($, rightTab);
  hasData = await waitForListLoaded($, card: card);
  expectNoErrorState();
  if (hasData) {
    await openFirstCardAndVerifyDetail(
      $,
      card: card,
      detailScreens: detailScreens,
      screen: screen,
    );
  }

  await tapTab($, leftTab);
  expect(find.byType(screen), findsOneWidget);

  await openAndCancelFilterSheet($);
}
