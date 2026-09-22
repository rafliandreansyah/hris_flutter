import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/disburse_action_screen.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;

  const sampleArgs = DisburseScreenArgs(
    claimId: 'clm-001',
    claimNumber: 'CLM-2026-0001',
    amount: 1500000.0,
    employeeName: 'Sarah Jenkins',
    bankName: 'BCA',
    bankAccountNumber: '123456789',
    bankAccountHolder: 'Sarah Jenkins',
    isCashAdvance: false,
  );

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    repository = MockReimbursementRepository();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: DisburseActionScreen(
        args: sampleArgs,
        repository: repository,
      ),
    );
  }

  group('DisburseActionScreen Widget Tests', () {
    testWidgets('renders claim summary and all 3 disbursement method options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pencairan Dana'), findsOneWidget);
      expect(find.textContaining('Sarah Jenkins'), findsWidgets);
      expect(find.textContaining('Transfer Manual'), findsOneWidget);
      expect(find.textContaining('Uang Tunai'), findsOneWidget);
      expect(find.textContaining('Payroll'), findsOneWidget);
      expect(find.textContaining('Konfirmasi Pencairan'), findsOneWidget);
    });

    testWidgets('switching methods renders appropriate form sections', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Uang Tunai method
      await tester.tap(find.textContaining('Uang Tunai'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Uang Tunai (Petty Cash)'), findsWidgets);

      // Tap Payroll method
      await tester.tap(find.textContaining('Payroll'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Siklus Payroll'), findsWidgets);
    });
  });
}
