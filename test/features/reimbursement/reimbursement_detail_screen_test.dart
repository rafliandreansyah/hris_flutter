import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/reimbursement_detail_screen.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;

  const sampleDetail = ReimbursementDetailModel(
    id: 'clm-001',
    claimNumber: 'CLM-2026-0001',
    title: 'Klaim Tiket Pesawat',
    description: 'Kunjungan cabang Bali',
    totalRequestedAmount: 1850000.0,
    totalApprovedAmount: 1850000.0,
    status: 'requested',
    type: 'out_of_pocket',
    bankName: 'BCA',
    bankAccountNumber: '987654321',
    bankAccountHolder: 'Budi Santoso',
    createdAt: '2026-09-22T08:00:00.000Z',
    employee: ExpenseEmployeeModel(
      id: 'emp-1',
      firstName: 'Budi',
      lastName: 'Santoso',
      email: 'budi@example.com',
      jobPosition: 'Product Lead',
      department: 'Technology',
    ),
    items: [
      ReimbursementLineItemModel(
        id: 'item-1',
        categoryId: 'cat-1',
        categoryName: 'Transportasi',
        categoryCode: 'TRN',
        transactionDate: '2026-09-20T00:00:00.000Z',
        merchantName: 'Garuda Indonesia',
        description: 'Tiket CGK-DPS',
        requestedAmount: 1850000.0,
        status: 'pending',
      ),
    ],
    approvalHistories: [],
  );

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    repository = MockReimbursementRepository();
    repository.mockReimbursementDetail = sampleDetail;
  });

  Widget buildTestWidget({String id = 'clm-001'}) {
    return MaterialApp(
      home: ReimbursementDetailScreen(
        id: id,
        repository: repository,
      ),
    );
  }

  group('ReimbursementDetailScreen Widget Tests', () {
    testWidgets('renders detail info, employee card and line items', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Klaim Tiket Pesawat'), findsWidgets);
      expect(find.text('CLM-2026-0001'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('Garuda Indonesia • 20/09/2026'), findsOneWidget);
      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });

    testWidgets('renders Cairkan Dana button when claim is approved', (tester) async {
      repository.mockReimbursementDetail = const ReimbursementDetailModel(
        id: 'clm-002',
        claimNumber: 'CLM-2026-0002',
        title: 'Klaim Approved',
        totalRequestedAmount: 500000.0,
        totalApprovedAmount: 500000.0,
        status: 'approved',
        type: 'out_of_pocket',
        createdAt: '2026-09-22T08:00:00.000Z',
        employee: ExpenseEmployeeModel(
          id: 'emp-1',
          firstName: 'Budi',
          email: 'budi@example.com',
        ),
      );

      await tester.pumpWidget(buildTestWidget(id: 'clm-002'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cairkan Dana'), findsOneWidget);
    });
  });
}
