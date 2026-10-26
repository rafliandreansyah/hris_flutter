import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

MenuItemModel _menu(String code, String name) =>
    MenuItemModel(id: code, name: name, code: code);

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('QuickAccessGrid.isMenuAvailable', () {
    test('null (belum dimuat/offline) = semua menu aktif', () {
      expect(QuickAccessGrid.isMenuAvailable('mobile_leave', 'Izin & Cuti', null), isTrue);
    });

    test('list kosong dari API = tidak ada menu yang tersedia', () {
      expect(QuickAccessGrid.isMenuAvailable('mobile_leave', 'Izin & Cuti', const []), isFalse);
    });

    test('cocok persis berdasarkan code (case-insensitive)', () {
      final menus = [_menu('MOBILE_OVERTIME', 'Apa saja')];
      expect(QuickAccessGrid.isMenuAvailable('mobile_overtime', 'Lembur', menus), isTrue);
      expect(QuickAccessGrid.isMenuAvailable('mobile_leave', 'Izin & Cuti', menus), isFalse);
    });

    test('cocok berdasarkan nama umum Indonesia/Inggris', () {
      expect(
        QuickAccessGrid.isMenuAvailable('mobile_leave', 'Izin & Cuti', [_menu('x', 'Cuti Tahunan')]),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable('mobile_payroll', 'Slip Gaji', [_menu('x', 'Payroll')]),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable('mobile_asset', 'Asset', [_menu('x', 'Fasilitas')]),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable('mobile_attendance', 'Riwayat Absen', [_menu('x', 'Riwayat Absensi')]),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable('mobile_attendance', 'Riwayat Absen', [_menu('x', 'Attendance History')]),
        isTrue,
      );
    });

    test('Absen Luar tersedia bila salah satu (live/schedule) ada', () {
      expect(
        QuickAccessGrid.isMenuAvailable(
          'mobile_attendance_request_live',
          'Absen Luar',
          [_menu('mobile_attendance_request_schedule', 'Schedule')],
        ),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable(
          'mobile_attendance_request_live',
          'Absen Luar',
          [_menu('mobile_leave', 'Cuti')],
        ),
        isFalse,
      );
    });

    test('Surat Peringatan: "sp" hanya cocok sebagai kata utuh, bukan substring', () {
      const code = 'mobile_warning_letter';
      expect(
        QuickAccessGrid.isMenuAvailable(code, 'Surat Peringatan', [_menu('x', 'Respons Cepat')]),
        isFalse,
      );
      expect(
        QuickAccessGrid.isMenuAvailable(code, 'Surat Peringatan', [_menu('x', 'Tracking Spending')]),
        isFalse,
      );
      expect(
        QuickAccessGrid.isMenuAvailable(code, 'Surat Peringatan', [_menu('x', 'SP')]),
        isTrue,
      );
      expect(
        QuickAccessGrid.isMenuAvailable(code, 'Surat Peringatan', [_menu('x', 'Surat Peringatan')]),
        isTrue,
      );
    });
  });

  group('QuickAccessGrid menu Pegawai butuh izin employee.view', () {
    tearDown(() => SecureStorageService.instance.setPermissionsInMemory(const []));

    testWidgets('disembunyikan bila izin sudah dimuat tetapi tanpa employee.view', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory(const [AppPermissions.reimbursementView]);
      await tester.pumpWidget(
        _wrap(QuickAccessGrid(menus: [_menu('mobile_leave', 'Cuti'), _menu('mobile_employee', 'Pegawai')])),
      );

      expect(find.text('Izin & Cuti'), findsOneWidget);
      expect(find.text('Pegawai'), findsNothing);
    });

    testWidgets('tampil bila pengguna punya employee.view', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory(const [AppPermissions.employeeView]);
      await tester.pumpWidget(
        _wrap(QuickAccessGrid(menus: [_menu('mobile_leave', 'Cuti'), _menu('mobile_employee', 'Pegawai')])),
      );

      expect(find.text('Pegawai'), findsOneWidget);
    });

    testWidgets('tampil bila izin belum dimuat (perilaku lama dipertahankan)', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory(const []);
      await tester.pumpWidget(
        _wrap(QuickAccessGrid(menus: [_menu('mobile_employee', 'Pegawai')])),
      );

      expect(find.text('Pegawai'), findsOneWidget);
    });
  });

  group('QuickAccessGrid widget', () {
    testWidgets('menus null menampilkan 7 menu utama + tile Lainnya', (tester) async {
      await tester.pumpWidget(_wrap(const QuickAccessGrid()));

      expect(find.text('Akses Cepat'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Lembur'), findsOneWidget);
      expect(find.text('Izin & Cuti'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_access_more')), findsOneWidget);
    });

    testWidgets('menu ≤ 8 ditampilkan semua tanpa tile Lainnya', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QuickAccessGrid(
            menus: [
              _menu('mobile_leave', 'Cuti'),
              _menu('mobile_employee', 'Pegawai'),
            ],
          ),
        ),
      );

      expect(find.text('Izin & Cuti'), findsOneWidget);
      expect(find.text('Pegawai'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_access_more')), findsNothing);
    });

    testWidgets('hanya menu yang ada di API yang ditampilkan (grid tidak rusak)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QuickAccessGrid(
            menus: [
              _menu('mobile_leave', 'Cuti'),
              _menu('mobile_overtime', 'Lembur'),
            ],
          ),
        ),
      );

      expect(find.text('Izin & Cuti'), findsOneWidget);
      expect(find.text('Lembur'), findsOneWidget);
      expect(find.text('Aktivitas'), findsNothing);
      expect(find.text('Slip Gaji'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('API mengembalikan list kosong: seluruh section disembunyikan', (tester) async {
      await tester.pumpWidget(_wrap(const QuickAccessGrid(menus: [])));

      expect(find.text('Akses Cepat'), findsNothing);
      expect(find.text('Lembur'), findsNothing);
    });

    testWidgets('judul menu mengikuti bahasa aplikasi (en)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessGrid(
                menus: [
                  _menu('mobile_leave', 'Cuti'),
                  _menu('mobile_overtime', 'Lembur'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('Overtime'), findsOneWidget);
      expect(find.text('Izin & Cuti'), findsNothing);
    });

    testWidgets('mobile_attendance menampilkan Riwayat Absen (id) dan icon calendarCheck2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessGrid(
                menus: [
                  _menu('mobile_attendance', 'Riwayat Absen'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Riwayat Absen'), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendarCheck2), findsOneWidget);
    });

    testWidgets('mobile_attendance menampilkan Attendance History (en)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAccessGrid(
                menus: [
                  _menu('mobile_attendance', 'Attendance History'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Attendance History'), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendarCheck2), findsOneWidget);
    });

    group('badge antrean', () {
      testWidgets('tile menampilkan angka, "99+" di atas 99, dan tanpa badge bila 0', (tester) async {
        await tester.pumpWidget(
          _wrap(
            QuickAccessGrid(
              menus: [
                _menu('mobile_leave', 'Cuti'),
                _menu('mobile_overtime', 'Lembur'),
                _menu('mobile_employee', 'Pegawai'),
              ],
              badges: const {'mobile_leave': 3, 'mobile_overtime': 120},
            ),
          ),
        );

        final leave = find.descendant(
          of: find.byKey(const ValueKey('menu_mobile_leave')),
          matching: find.byKey(const ValueKey('menu_badge')),
        );
        expect(leave, findsOneWidget);
        expect(find.descendant(of: leave, matching: find.text('3')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('menu_mobile_overtime')),
            matching: find.text('99+'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('menu_mobile_employee')),
            matching: find.byKey(const ValueKey('menu_badge')),
          ),
          findsNothing,
        );
      });

      testWidgets('tile Lainnya menjumlahkan badge menu yang tersembunyi', (tester) async {
        // menus null → semua menu default; menu non-prioritas masuk ke "Lainnya"
        await tester.pumpWidget(
          _wrap(const QuickAccessGrid(badges: {'mobile_resignation': 2, 'mobile_lifecycle': 1})),
        );

        final more = find.byKey(const ValueKey('quick_access_more'));
        expect(more, findsOneWidget);
        expect(
          find.descendant(of: more, matching: find.byKey(const ValueKey('menu_badge'))),
          findsOneWidget,
        );
        expect(find.descendant(of: more, matching: find.text('3')), findsOneWidget);
      });
    });
  });
}
