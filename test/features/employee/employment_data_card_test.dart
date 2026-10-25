import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employment_data_card.dart';

void main() {
  group('EmploymentDataCard', () {
    test('formatTenure menghitung masa kerja tahun & bulan', () {
      final now = DateTime(2026, 10, 25);
      expect(EmploymentDataCard.formatTenure('2024-07-10', now: now), '2 tahun 3 bulan');
      expect(EmploymentDataCard.formatTenure('2026-10-01', now: now), 'Kurang dari 1 bulan');
      expect(EmploymentDataCard.formatTenure('2025-10-25', now: now), '1 tahun');
      expect(EmploymentDataCard.formatTenure(null, now: now), '-');
    });

    testWidgets('menyembunyikan field kosong dan menampilkan bagian kontak',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EmploymentDataCard(
                joinDate: '10 Juli 2024',
                employeeId: 'EMP-001',
                email: 'budi@example.com',
              ),
            ),
          ),
        ),
      );

      expect(find.text('KEPEGAWAIAN'), findsOneWidget);
      expect(find.text('KONTAK'), findsOneWidget);
      expect(find.text('PERSONAL'), findsNothing);
      expect(find.text('Akhir Kontrak'), findsNothing);
      expect(find.text('EMP-001'), findsOneWidget);
    });
  });
}
