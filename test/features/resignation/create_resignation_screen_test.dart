import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/pages/create_resignation_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'mock_resignation_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });
  // Tanggal relatif agar test tidak kedaluwarsa terhadap DateTime.now().
  final suggestedDate = DateTime.now().add(const Duration(days: 60));
  final sampleInitialForm = ResignationInitialFormModel(
    companyPolicy: const ResignationCompanyPolicyModel(
      defaultNoticePeriodDays: 30,
      allowEarlyNoticeWaiver: true,
    ),
    employee: const ResignationFormEmployeeModel(
      id: 'emp-101',
      name: 'Budi Santoso',
      departmentName: 'Engineering',
      positionName: 'Senior Developer',
    ),
    minSuggestedDate:
        '${suggestedDate.year.toString().padLeft(4, '0')}-${suggestedDate.month.toString().padLeft(2, '0')}-${suggestedDate.day.toString().padLeft(2, '0')}',
    colleagues: const [],
  );

  Widget buildTestableWidget({required ResignationRepository repository}) {
    return MaterialApp(
      home: CreateResignationScreen(repository: repository),
    );
  }

  group('CreateResignationScreen Widget Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('renders title, form sections, and submit button when loaded', (tester) async {
      final repo = MockResignationRepository();
      repo.mockInitialForm = sampleInitialForm;

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Formulir Pengunduran Diri'), findsOneWidget);
      expect(find.text('1. TANGGAL EFEKTIF RESIGN'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Kirim Pengajuan'), findsOneWidget);
      expect(find.byIcon(LucideIcons.helpCircle), findsOneWidget);
    });

    testWidgets('tapping help icon opens policy help dialog', (tester) async {
      final repo = MockResignationRepository();
      repo.mockInitialForm = sampleInitialForm;

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.helpCircle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Panduan Kebijakan Resign'), findsOneWidget);
      expect(find.text('Saya Mengerti'), findsOneWidget);
    });

    testWidgets('tapping submit without resignation notes shows warning dialog', (tester) async {
      final repo = MockResignationRepository();
      repo.mockInitialForm = sampleInitialForm;

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Pengajuan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alasan Resign Wajib Diisi'), findsOneWidget);
    });

    testWidgets('handles error when loading initial form data fails', (tester) async {
      final repo = MockResignationRepository();
      repo.shouldThrowError = true;
      repo.errorMessage = 'Gagal memuat formulir kebijakan resign';

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Gagal memuat formulir kebijakan resign'), findsOneWidget);
    });
  });
}
