import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/cash_advance_detail_screen.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;

  const sampleDetail = CashAdvanceDetailModel(
    id: 'adv-001',
    advanceNumber: 'ADV-2026-0001',
    title: 'Kasbon Pembelian Alat',
    purpose: 'Kebutuhan workshop',
    requestedAmount: 2000000.0,
    approvedAmount: 2000000.0,
    status: 'disbursed',
    createdAt: '2026-09-22T08:00:00.000Z',
    settlementDeadline: '2026-10-15T00:00:00.000Z',
    employee: ExpenseEmployeeModel(
      id: 'emp-1',
      firstName: 'Sarah',
      lastName: 'Connor',
      email: 'sarah@example.com',
      jobPosition: 'Procurement Specialist',
      department: 'Operations',
    ),
  );

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    repository = MockReimbursementRepository();
    repository.mockCashAdvanceDetail = sampleDetail;
  });

  Widget buildTestWidget({String id = 'adv-001'}) {
    return MaterialApp(
      home: CashAdvanceDetailScreen(
        id: id,
        repository: repository,
      ),
    );
  }

  group('CashAdvanceDetailScreen Widget Tests', () {
    testWidgets('renders detail info, employee card, and settlement action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Kasbon Pembelian Alat'), findsWidgets);
      expect(find.text('ADV-2026-0001'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsWidgets);
      expect(find.text('Status Penyelesaian Kasbon'), findsOneWidget);
      expect(find.text('Selesaikan Nota'), findsOneWidget);
      expect(find.text('Kembalikan Sisa'), findsOneWidget);
    });

    testWidgets('renders Setujui and Tolak buttons when status is requested', (tester) async {
      repository.mockCashAdvanceDetail = const CashAdvanceDetailModel(
        id: 'adv-002',
        advanceNumber: 'ADV-2026-0002',
        title: 'Kasbon Baru',
        purpose: 'Operasional',
        requestedAmount: 1000000.0,
        status: 'requested',
        createdAt: '2026-09-22T08:00:00.000Z',
        employee: ExpenseEmployeeModel(
          id: 'emp-2',
          firstName: 'Budi',
          email: 'budi@example.com',
        ),
      );

      await tester.pumpWidget(buildTestWidget(id: 'adv-002'));
      await tester.pumpAndSettle();

      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });
  });
}
