import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/pages/payroll_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'mock_payroll_repository.dart';

void main() {
  const samplePeriod = PayrollPeriodModel(
    id: 'prd-01',
    month: 9,
    year: 2026,
    label: 'September 2026',
    startDate: '2026-08-26',
    endDate: '2026-09-25',
    payDate: '2026-09-25',
    status: 'closed',
  );

  const sampleSlip = PayrollSlipModel(
    id: 'pay-001',
    employeeId: 'emp-001',
    employee: PayrollEmployeeSummaryModel(
      id: 'emp-001',
      firstName: 'Budi',
      lastName: 'Santoso',
      employeeNumber: 'EMP-001',
      department: 'Engineering',
      position: 'Senior Developer',
    ),
    period: samplePeriod,
    grossSalary: 10000000.0,
    deductions: 1000000.0,
    netSalary: 9000000.0,
    status: 'paid',
    createdAt: '2026-09-25T10:00:00.000Z',
  );

  Widget buildTestableWidget({required PayrollRepository repository}) {
    return MaterialApp(
      home: PayrollScreen(repository: repository),
    );
  }

  group('PayrollScreen Widget Tests', () {
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

    testWidgets('renders title, filter button, eye toggle, and payroll slips', (tester) async {
      final repo = MockPayrollRepository();
      repo.mockMySlips = const PayrollListResponseModel(
        data: [sampleSlip],
        meta: PayrollPaginationMeta(
          page: 1,
          size: 10,
          total: 1,
          totalPages: 1,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Slip Gaji'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
      expect(find.byIcon(LucideIcons.eyeOff), findsWidgets);
      expect(find.text('September 2026'), findsWidgets);
    });

    testWidgets('renders empty state when user has no payroll slips', (tester) async {
      final repo = MockPayrollRepository();
      repo.mockMySlips = const PayrollListResponseModel(
        data: [],
        meta: PayrollPaginationMeta(
          page: 1,
          size: 10,
          total: 0,
          totalPages: 1,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Slip Gaji'), findsOneWidget);
    });

    testWidgets('renders error view with retry button when API fails', (tester) async {
      final repo = MockPayrollRepository();
      repo.errorToThrow = const ApiException(
        message: 'Koneksi ke server payroll gagal',
        statusCode: 500,
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Slip Gaji'), findsOneWidget);
      expect(find.text('Koneksi ke server payroll gagal'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('tombol Coba Lagi memuat ulang dan pulih dari error', (tester) async {
      final repo = MockPayrollRepository();
      repo.errorToThrow = const ApiException(
        message: 'Koneksi ke server payroll gagal',
        statusCode: 500,
      );

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();
      expect(find.text('Gagal Memuat Slip Gaji'), findsOneWidget);

      // Server pulih, lalu user menekan "Coba Lagi".
      repo.errorToThrow = null;
      repo.mockMySlips = const PayrollListResponseModel(
        data: [sampleSlip],
        meta: PayrollPaginationMeta(page: 1, size: 10, total: 1, totalPages: 1),
      );
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Slip Gaji'), findsNothing);
      expect(find.text('Coba Lagi'), findsNothing);
      expect(find.text('September 2026'), findsWidgets);
    });
  });
}
