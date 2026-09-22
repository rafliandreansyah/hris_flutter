import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/expenses_list_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/expense_request_card.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;

  const sampleItem = ExpenseFeedItemModel(
    id: 'exp-1',
    referenceNumber: 'CLM-2026-001',
    expenseType: 'reimbursement',
    title: 'Klaim Bensin Dinas',
    requestedAmount: 250000.0,
    status: 'requested',
    createdAt: '2026-09-22T08:00:00.000Z',
    employee: ExpenseEmployeeModel(
      id: 'emp-1',
      firstName: 'Sarah',
      lastName: 'Jenkins',
      email: 'sarah@example.com',
    ),
  );

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    repository = MockReimbursementRepository();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: ExpensesListScreen(repository: repository),
    );
  }

  group('ExpensesListScreen Widget Tests', () {
    testWidgets('renders tabs, search field and filter button', (tester) async {
      repository.mockMyFeed = const ExpensesFeedResponseModel(
        items: [sampleItem],
        meta: ExpensesPaginationMeta(page: 1, limit: 10, total: 1, totalPages: 1),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Klaim & Kasbon'), findsOneWidget);
      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('Persetujuan Tim'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ExpenseRequestCard), findsOneWidget);
      expect(find.text('Klaim Bensin Dinas'), findsOneWidget);
    });

    testWidgets('renders empty state when there are no expenses', (tester) async {
      repository.mockMyFeed = const ExpensesFeedResponseModel(
        items: [],
        meta: ExpensesPaginationMeta(page: 1, limit: 10, total: 0, totalPages: 1),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Pengajuan'), findsOneWidget);
    });

    testWidgets('switching to Persetujuan Tim tab shows forbidden state when user has no approver access', (tester) async {
      repository.mockMyFeed = const ExpensesFeedResponseModel(
        items: [],
        meta: ExpensesPaginationMeta(page: 1, limit: 10, total: 0, totalPages: 1),
      );
      repository.teamForbidden = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap tab Persetujuan Tim
      await tester.tap(find.text('Persetujuan Tim'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);
    });
  });
}
