import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/create_cash_advance_screen.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    repository = MockReimbursementRepository();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: CreateCashAdvanceScreen(
        repository: repository,
      ),
    );
  }

  group('CreateCashAdvanceScreen Widget Tests', () {
    testWidgets('renders all form fields and submit button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ajukan Kasbon'), findsOneWidget);
      expect(find.text('Ketentuan Pengajuan Kasbon'), findsOneWidget);
      expect(find.text('Judul Permohonan / Nama Kegiatan *'), findsOneWidget);
      expect(find.text('Batas Waktu Pelaporan SPJ *'), findsOneWidget);
      expect(find.text('Rincian Estimasi Biaya / Keperluan *'), findsOneWidget);
      expect(find.text('Kirim Permohonan Kasbon'), findsOneWidget);
    });

    testWidgets('unfocuses keyboard when tapping outside nominal and purpose inputs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scope = FocusScope.of(tester.element(find.byType(CreateCashAdvanceScreen)));

      // 1. Focus nominal field
      final amountFinder = find.byKey(const Key('cash_advance_amount_field'));
      expect(amountFinder, findsOneWidget);
      await tester.tap(amountFinder);
      await tester.pumpAndSettle();

      // EditableText focus should be active inside the scope
      expect(scope.focusedChild, isNotNull);

      // Tap outside (on policy banner text)
      await tester.tap(find.text('Ketentuan Pengajuan Kasbon'));
      await tester.pumpAndSettle();

      // EditableText focus should be dismissed (focusedChild is null)
      expect(scope.focusedChild, isNull);

      // 2. Focus purpose field
      final purposeFinder = find.byKey(const Key('cash_advance_purpose_field'));
      expect(purposeFinder, findsOneWidget);
      await tester.tap(purposeFinder);
      await tester.pumpAndSettle();

      expect(scope.focusedChild, isNotNull);

      // Tap outside (on title label)
      await tester.tap(find.text('Judul Permohonan / Nama Kegiatan *'));
      await tester.pumpAndSettle();

      // EditableText focus should be dismissed
      expect(scope.focusedChild, isNull);
    });

    testWidgets('unfocuses keyboard when submit button is tapped', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scope = FocusScope.of(tester.element(find.byType(CreateCashAdvanceScreen)));

      // Focus nominal field
      final amountFinder = find.byKey(const Key('cash_advance_amount_field'));
      await tester.tap(amountFinder);
      await tester.pumpAndSettle();
      expect(scope.focusedChild, isNotNull);

      // Tap submit button
      await tester.tap(find.text('Kirim Permohonan Kasbon'));
      await tester.pumpAndSettle();

      // Focus should be dismissed on submit
      expect(scope.focusedChild, isNull);
    });
  });
}
