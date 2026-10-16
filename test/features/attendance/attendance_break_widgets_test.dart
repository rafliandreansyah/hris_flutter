import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_break.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_break_sessions_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_break_sheet.dart';

AttendanceBreakItem _done(String id, DateTime start, int minutes, {String? note}) =>
    AttendanceBreakItem(
      id: id,
      attendanceId: 'att-1',
      startTime: start,
      endTime: start.add(Duration(minutes: minutes)),
      durationMinutes: minutes,
      note: note,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  final base = DateTime.utc(2026, 10, 15, 5, 0);

  group('AttendanceBreakStatus (kalkulasi)', () {
    test('total, sisa, dan lewat jatah menghitung sesi yang sedang berjalan', () {
      final active = AttendanceBreakItem(
        id: 'b2',
        attendanceId: 'att-1',
        startTime: base.add(const Duration(minutes: 100)),
      );
      final status = AttendanceBreakStatus(
        isOnBreak: true,
        activeBreak: active,
        allocatedBreakMinutes: 60,
        breaks: [_done('b1', base, 40), active],
      );

      final now = base.add(const Duration(minutes: 125)); // sesi aktif 25 mnt
      expect(status.totalMinutesAt(now), 65);
      expect(status.overbreakMinutesAt(now), 5);
      expect(status.remainingMinutesAt(now), 0);

      final earlier = base.add(const Duration(minutes: 110)); // sesi aktif 10 mnt
      expect(status.totalMinutesAt(earlier), 50);
      expect(status.remainingMinutesAt(earlier), 10);
      expect(status.overbreakMinutesAt(earlier), 0);
    });

    test('tanpa jatah: remaining null dan overbreak 0', () {
      const status = AttendanceBreakStatus();
      expect(status.remainingMinutesAt(base), isNull);
      expect(status.overbreakMinutesAt(base), 0);
    });

    test('minutesAt tidak pernah negatif bila jam perangkat mundur', () {
      final item = AttendanceBreakItem(id: 'x', attendanceId: 'a', startTime: base);
      expect(item.minutesAt(base.subtract(const Duration(minutes: 5))), 0);
    });
  });

  group('AttendanceBreakSessionsCard', () {
    testWidgets('belum ada istirahat', (tester) async {
      await tester.pumpWidget(
        _wrap(const AttendanceBreakSessionsCard(status: AttendanceBreakStatus())),
      );

      expect(find.text('Istirahat'), findsOneWidget);
      expect(find.text('Belum mulai'), findsOneWidget);
      expect(find.text('Belum ada istirahat hari ini'), findsOneWidget);
      expect(find.byKey(const ValueKey('attendance_break_timer')), findsNothing);
    });

    testWidgets('sedang istirahat: timer berjalan dan sisa jatah turun tiap detik', (tester) async {
      var now = base.add(const Duration(minutes: 10, seconds: 5));
      final active = AttendanceBreakItem(id: 'b1', attendanceId: 'att-1', startTime: base);
      final status = AttendanceBreakStatus(
        isOnBreak: true,
        activeBreak: active,
        allocatedBreakMinutes: 60,
        breaks: [active],
      );

      await tester.pumpWidget(
        _wrap(AttendanceBreakSessionsCard(status: status, nowProvider: () => now)),
      );

      expect(find.text('Sedang istirahat'), findsOneWidget);
      expect(find.text('10:05'), findsOneWidget);
      expect(find.text('Sisa jatah 50 menit'), findsOneWidget);
      expect(find.textContaining('– sekarang'), findsOneWidget);

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('10:06'), findsOneWidget);
    });

    testWidgets('melewati jatah: menampilkan "Lewat jatah" dan tambahan menit', (tester) async {
      final now = base.add(const Duration(minutes: 70));
      final active = AttendanceBreakItem(id: 'b1', attendanceId: 'att-1', startTime: base);
      final status = AttendanceBreakStatus(
        isOnBreak: true,
        activeBreak: active,
        allocatedBreakMinutes: 60,
        breaks: [active],
      );

      await tester.pumpWidget(
        _wrap(AttendanceBreakSessionsCard(status: status, nowProvider: () => now)),
      );

      expect(find.text('Lewat jatah 10 menit'), findsOneWidget);
      expect(find.byKey(const ValueKey('attendance_break_over_text')), findsOneWidget);
      expect(find.text('+10 menit'), findsOneWidget);
    });

    testWidgets('mode fleksibel tanpa jatah: tampil total hari ini', (tester) async {
      final now = base.add(const Duration(minutes: 90));
      final active = AttendanceBreakItem(
        id: 'b2',
        attendanceId: 'att-1',
        startTime: base.add(const Duration(minutes: 80)),
      );
      final status = AttendanceBreakStatus(
        isOnBreak: true,
        activeBreak: active,
        isFlexibleBreak: true,
        breaks: [_done('b1', base, 30), active],
      );

      await tester.pumpWidget(
        _wrap(AttendanceBreakSessionsCard(status: status, nowProvider: () => now)),
      );

      expect(find.text('Total hari ini 40 menit'), findsOneWidget);
      expect(find.byKey(const ValueKey('attendance_break_over_text')), findsNothing);
    });

    testWidgets('selesai: daftar semua sesi beserta catatan dan total', (tester) async {
      final status = AttendanceBreakStatus(
        allocatedBreakMinutes: 60,
        totalBreakMinutes: 50,
        breaks: [
          _done('b1', base, 20, note: 'ngopi'),
          _done('b2', base.add(const Duration(minutes: 120)), 30),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          AttendanceBreakSessionsCard(
            status: status,
            nowProvider: () => base.add(const Duration(hours: 6)),
          ),
        ),
      );

      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('ngopi'), findsOneWidget);
      expect(find.text('20 mnt'), findsOneWidget);
      expect(find.text('30 mnt'), findsOneWidget);
      expect(find.text('Total 50 dari 60 menit'), findsOneWidget);
      expect(find.byKey(const ValueKey('attendance_break_timer')), findsNothing);
    });
  });

  group('AttendanceBreakSheet', () {
    late String? result;
    var resolved = false;

    Future<void> openSheet(
      WidgetTester tester, {
      required bool isEnding,
      required bool gpsReady,
      AttendanceBreakStatus? status,
    }) async {
      result = 'belum';
      resolved = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showAttendanceBreakSheet(
                      context,
                      isEnding: isEnding,
                      isGpsReady: gpsReady,
                      status: status,
                    );
                    resolved = true;
                  },
                  child: const Text('buka'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
    }

    testWidgets('mulai: judul, jatah, dan lokasi terdeteksi', (tester) async {
      await openSheet(
        tester,
        isEnding: false,
        gpsReady: true,
        status: const AttendanceBreakStatus(allocatedBreakMinutes: 60, totalBreakMinutes: 15),
      );

      expect(find.text('Mulai Istirahat'), findsNWidgets(2)); // judul + tombol
      expect(find.text('Jatah istirahat: 60 menit • terpakai 15 menit'), findsOneWidget);
      expect(find.text('Lokasi terdeteksi'), findsOneWidget);
    });

    testWidgets('selesai: judul "Selesai Istirahat"', (tester) async {
      await openSheet(tester, isEnding: true, gpsReady: true);

      expect(find.text('Selesai Istirahat'), findsNWidgets(2));
      expect(find.text('Mulai Istirahat'), findsNothing);
    });

    testWidgets('GPS belum siap: konfirmasi dinonaktifkan dan ada peringatan', (tester) async {
      await openSheet(tester, isEnding: false, gpsReady: false);

      expect(find.textContaining('Menunggu lokasi GPS'), findsOneWidget);
      final confirm = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Mulai Istirahat'),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('konfirmasi mengembalikan catatan ter-trim', (tester) async {
      await openSheet(tester, isEnding: false, gpsReady: true);

      await tester.enterText(find.byType(TextField), '  makan siang  ');
      await tester.tap(find.widgetWithText(AppButton, 'Mulai Istirahat'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(result, 'makan siang');
    });

    testWidgets('konfirmasi tanpa catatan mengembalikan string kosong', (tester) async {
      await openSheet(tester, isEnding: true, gpsReady: true);

      await tester.tap(find.widgetWithText(AppButton, 'Selesai Istirahat'));
      await tester.pumpAndSettle();

      expect(result, '');
    });

    testWidgets('Batal mengembalikan null', (tester) async {
      await openSheet(tester, isEnding: false, gpsReady: true);

      await tester.tap(find.widgetWithText(AppButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(result, isNull);
    });
  });
}
