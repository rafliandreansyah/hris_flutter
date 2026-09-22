import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/create_reimbursement_screen.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1080,
      2400,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    repository = MockReimbursementRepository();
  });

  Widget buildTestWidget({String? cashAdvanceId}) {
    return MaterialApp(
      home: CreateReimbursementScreen(
        initialCashAdvanceId: cashAdvanceId,
        repository: repository,
      ),
    );
  }

  group('CreateReimbursementScreen Widget Tests', () {
    testWidgets('renders general info, add item button, and submit button', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ajukan Reimbursement'), findsOneWidget);
      expect(find.text('Informasi Dasar Pengajuan'), findsOneWidget);
      expect(find.text('Daftar Nota & Struk Biaya'), findsOneWidget);
      expect(find.text('Tambah Nota Biaya Lain'), findsOneWidget);
      expect(find.text('Kirim Pengajuan Reimbursement'), findsOneWidget);
    });

    testWidgets('shows settlement banner when cashAdvanceId is passed', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(cashAdvanceId: 'adv-123'));
      await tester.pumpAndSettle();

      expect(find.text('Pelaporan Kasbon (Settlement)'), findsOneWidget);
      expect(find.text('Kasbon yang Diselesaikan'), findsOneWidget);
    });
  });
}
