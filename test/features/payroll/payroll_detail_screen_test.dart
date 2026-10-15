import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:hris_flutter/features/payroll/presentation/pages/payroll_detail_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'mock_payroll_repository.dart';

void main() {
  const sampleDetail = PayrollDetailModel(
    id: 'pay-001',
    status: 'paid',
    grossSalary: 10000000.0,
    deductions: 1000000.0,
    netSalary: 9000000.0,
    terbilang: 'Sembilan Juta Rupiah',
    payslipUrl: 'https://storage.googleapis.com/test/slip_001.pdf',
    company: PayrollCompanyModel(
      id: 'comp-1',
      name: 'PT Muratech Perkasa',
    ),
    employee: PayrollEmployeeDetailModel(
      id: 'emp-001',
      nik: 'EMP-001',
      name: 'Budi Santoso',
      email: 'budi@example.com',
      department: 'Engineering',
      position: 'Senior Developer',
      bankName: 'BCA',
      accountNumber: '1234567890',
      taxStatus: 'TK/0',
      taxNumber: '12345',
      bpjsEmployment: 'BPJS-TK-01',
      bpjsHealth: 'BPJS-KES-01',
    ),
    period: PayrollPeriodModel(
      id: 'prd-01',
      month: 9,
      year: 2026,
      label: 'September 2026',
      startDate: '2026-08-26',
      endDate: '2026-09-25',
      payDate: '2026-09-25',
      status: 'closed',
    ),
    attendanceRecap: PayrollAttendanceRecapModel(
      workingDays: 22,
      presentDays: 21,
      absentDays: 1,
      lateMinutes: 10,
      overtimeHours: 4.5,
    ),
    earnings: [
      PayrollEarningItemModel(
        id: 'earn-1',
        name: 'Gaji Pokok',
        category: 'Fixed',
        quantity: '1 Bulan',
        amount: 9000000.0,
      ),
      PayrollEarningItemModel(
        id: 'earn-2',
        name: 'Uang Lembur',
        category: 'Overtime',
        quantity: '4.5 Jam',
        amount: 1000000.0,
      ),
    ],
    deductionsList: [
      PayrollDeductionItemModel(
        id: 'ded-1',
        name: 'BPJS Ketenagakerjaan',
        category: 'BPJS',
        description: '3% dari Gaji Pokok',
        amount: 270000.0,
      ),
    ],
  );

  Widget buildTestableWidget({
    required String id,
    required PayrollRepository repository,
  }) {
    return MaterialApp(
      home: PayrollDetailScreen(
        id: id,
        repository: repository,
      ),
    );
  }

  group('PayrollDetailScreen Widget Tests', () {
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

    testWidgets('renders detail cards, breakdown, and action buttons when loaded', (tester) async {
      final repo = MockPayrollRepository();
      repo.mockPayrollDetail = sampleDetail;

      await tester.pumpWidget(buildTestableWidget(id: 'pay-001', repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Slip Gaji - September 2026'), findsOneWidget);
      expect(find.text('PT Muratech Perkasa'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.textContaining('Engineering'), findsWidgets);
      expect(find.text('Gaji Pokok'), findsOneWidget);
      expect(find.text('BPJS Ketenagakerjaan'), findsOneWidget);
      expect(find.text('Take Home Pay (Gaji Bersih)'), findsOneWidget);
      expect(find.text('Lihat PDF'), findsOneWidget);
      expect(find.text('Unduh PDF'), findsOneWidget);
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(find.byIcon(LucideIcons.share2), findsOneWidget);
    });

    testWidgets('renders empty text when detail data is not found', (tester) async {
      final repo = MockPayrollRepository();
      repo.mockPayrollDetail = null;

      await tester.pumpWidget(buildTestableWidget(id: 'pay-999', repository: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Data rincian slip gaji tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows error dialog when API call throws exception', (tester) async {
      final repo = MockPayrollRepository();
      repo.errorToThrow = const ApiException(
        message: 'Gagal memuat rincian gaji dari server',
        statusCode: 500,
      );

      await tester.pumpWidget(buildTestableWidget(id: 'pay-error', repository: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Gagal memuat rincian gaji dari server'), findsOneWidget);
    });
  });
}
