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
  });
}
