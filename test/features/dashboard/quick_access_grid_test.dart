import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/presentation/widgets/quick_access_grid.dart';

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

  group('QuickAccessGrid widget', () {
    testWidgets('menus null menampilkan seluruh menu default', (tester) async {
      await tester.pumpWidget(_wrap(const QuickAccessGrid()));

      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Lembur'), findsOneWidget);
      expect(find.text('Izin & Cuti'), findsOneWidget);
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

      expect(find.text('Quick Access'), findsNothing);
      expect(find.text('Lembur'), findsNothing);
    });
  });
}
