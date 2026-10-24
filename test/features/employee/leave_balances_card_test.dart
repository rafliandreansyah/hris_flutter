import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/leave_balances_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/metrics_strip_card.dart';

DetailLeaveBalance _balance({
  required String name,
  required double entitlement,
  required double used,
  String? expiredDate,
}) => DetailLeaveBalance(
  id: name,
  periodYear: 2026,
  entitlement: entitlement,
  used: used,
  remaining: entitlement - used,
  expiredDate: expiredDate,
  leaveType: DetailLeaveType(id: name, name: name),
);

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('LeaveBalancesCard', () {
    testWidgets('menampilkan saldo dari API, bukan angka bawaan', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LeaveBalancesCard(
            balances: [
              _balance(name: 'Cuti Tahunan', entitlement: 12, used: 5, expiredDate: '2026-12-31T00:00:00.000Z'),
              _balance(name: 'Cuti Besar', entitlement: 30, used: 0),
            ],
          ),
        ),
      );

      expect(find.text('SALDO & KUOTA CUTI'), findsOneWidget);
      expect(find.text('Cuti Tahunan'), findsOneWidget);
      expect(find.text('7 Hari Tersisa'), findsOneWidget);
      expect(find.text('Cuti Besar'), findsOneWidget);
      expect(find.text('30 Hari Tersisa'), findsOneWidget);
      expect(find.text('Berlaku hingga 31 Desember 2026'), findsOneWidget);
      expect(find.text('Tanpa batas waktu'), findsOneWidget);
      // Tidak ada lagi teks statis lama.
      expect(find.textContaining('2024'), findsNothing);
      expect(find.text('Cuti Sakit'), findsNothing);
      expect(find.text('Cuti Khusus'), findsNothing);
    });

    testWidgets('saldo kosong menampilkan pesan, bukan kuota palsu', (tester) async {
      await tester.pumpWidget(_wrap(const LeaveBalancesCard()));

      expect(find.textContaining('Belum ada saldo cuti aktif'), findsOneWidget);
      expect(find.text('Cuti Tahunan'), findsNothing);
    });

    testWidgets('kuota 0 tidak membagi dengan nol', (tester) async {
      await tester.pumpWidget(
        _wrap(LeaveBalancesCard(balances: [_balance(name: 'Cuti Khusus Baru', entitlement: 0, used: 0)])),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('0 Hari Tersisa'), findsOneWidget);
    });

    testWidgets('saldo setengah hari tidak dipotong menjadi bilangan bulat', (tester) async {
      await tester.pumpWidget(
        _wrap(LeaveBalancesCard(balances: [_balance(name: 'Cuti Tahunan', entitlement: 12, used: 2.5)])),
      );

      expect(find.text('9,5 Hari Tersisa'), findsOneWidget);
      expect(find.text('2,5'), findsOneWidget);
      expect(LeaveBalancesCard.formatDays(12), '12');
    });

    test('expiryLabel menangani tanggal kosong dan tidak valid', () {
      expect(LeaveBalancesCard.expiryLabel(null), 'Tanpa batas waktu');
      expect(LeaveBalancesCard.expiryLabel('bukan-tanggal'), 'Tanpa batas waktu');
      expect(LeaveBalancesCard.expiryLabel('2026-12-31T00:00:00.000Z'), 'Berlaku hingga 31 Desember 2026');
    });
  });

  group('MetricsStripCard', () {
    test('formatMinutes memperlakukan angka sebagai menit', () {
      expect(MetricsStripCard.formatMinutes(360), '6 Jam 0 Menit');
      expect(MetricsStripCard.formatMinutes(150), '2 Jam 30 Menit');
      expect(MetricsStripCard.formatMinutes(0), '0 Jam 0 Menit');
      expect(MetricsStripCard.formatMinutes(-5), '0 Jam 0 Menit');
    });

    testWidgets('menampilkan lembur dalam jam dan cuti dalam hari', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MetricsStripCard(
            overtimeFormatted: MetricsStripCard.formatMinutes(360),
            overtimeTotalMinutes: 360,
            leaveRequestCount: 3,
          ),
        ),
      );

      expect(find.text('TOTAL OVERTIME'), findsOneWidget);
      expect(find.text('6 Jam 0 Menit'), findsOneWidget);
      expect(find.text('360 Total Menit'), findsOneWidget);
      expect(find.text('CUTI DISETUJUI'), findsOneWidget);
      expect(find.text('3 Hari'), findsOneWidget);
      expect(find.text('Disetujui periode ini'), findsOneWidget);
    });
  });
}
