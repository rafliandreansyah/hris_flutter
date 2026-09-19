import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/schedule_location_picker_modal.dart';

Widget _wrapWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  setUp(() {
    PermissionUtil.bypassInTest = true;
    ScheduleLocationPickerModal.bypassInTest = true;
  });

  group('ScheduleLocationPickerModal Widget Tests', () {
    testWidgets('merender judul, koordinat, alamat, dan tombol Cek Alamat',
        (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const ScheduleLocationPickerModal(
            initialLatitude: -6.2088,
            initialLongitude: 106.8456,
            initialAddress: 'Gedung Wisma 46, Jakarta Pusat',
            title: 'Pilih Lokasi Presensi Masuk',
          ),
        ),
      );
      await tester.pump();

      // Judul modal
      expect(find.text('Pilih Lokasi Presensi Masuk'), findsOneWidget);

      // Format koordinat
      expect(find.text('-6.20880°, 106.84560°'), findsOneWidget);

      // Alamat terpilih
      expect(find.text('Gedung Wisma 46, Jakarta Pusat'), findsOneWidget);

      // Tombol manual "Cek Alamat"
      expect(find.text('Cek Alamat'), findsOneWidget);
      expect(
        find.byKey(
            const Key('schedule-location-picker-check-address-button')),
        findsOneWidget,
      );

      // Tombol konfirmasi
      expect(
        find.byKey(
            const Key('schedule-location-picker-confirm-button')),
        findsOneWidget,
      );
    });

    testWidgets('mengetuk Cek Alamat dapat ditekan tanpa melempar exception',
        (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const ScheduleLocationPickerModal(
            initialLatitude: -6.2088,
            initialLongitude: 106.8456,
            initialAddress: 'Gedung Wisma 46, Jakarta Pusat',
          ),
        ),
      );
      await tester.pump();

      final checkBtn = find.byKey(
          const Key('schedule-location-picker-check-address-button'));
      expect(checkBtn, findsOneWidget);

      await tester.tap(checkBtn);
      await tester.pump();

      // Tetap ter-render stabil
      expect(find.text('Cek Alamat'), findsOneWidget);
    });

    testWidgets(
        'showScheduleLocationPickerModal mengembalikan ScheduleLocationResult saat dikonfirmasi',
        (tester) async {
      ScheduleLocationResult? pickedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    pickedResult = await showScheduleLocationPickerModal(
                      context,
                      initialLatitude: -6.1754,
                      initialLongitude: 106.8272,
                      initialAddress: 'Monumen Nasional, Gambir',
                    );
                  },
                  child: const Text('Buka Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Buka bottom sheet
      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Monumen Nasional, Gambir'), findsOneWidget);
      expect(find.text('-6.17540°, 106.82720°'), findsOneWidget);

      // Ketuk Pilih Lokasi Ini
      await tester.tap(
          find.byKey(const Key('schedule-location-picker-confirm-button')));
      await tester.pumpAndSettle();

      expect(pickedResult, isNotNull);
      expect(pickedResult!.latitude, -6.1754);
      expect(pickedResult!.longitude, 106.8272);
      expect(pickedResult!.address, 'Monumen Nasional, Gambir');
    });
  });
}
