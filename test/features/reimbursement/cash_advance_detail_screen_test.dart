import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
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
      employeeNumber: 'EMP-ADV-001',
      firstName: 'Sarah',
      lastName: 'Connor',
      email: 'sarah@example.com',
      jobPosition: 'Procurement Specialist',
      department: 'Operations',
      company: 'PT Muratech Mandiri',
    ),
  );

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

    SecureStorageService.instance.setPermissionsInMemory([
      AppPermissions.approvalReimbursementManager,
    ]);

    repository = MockReimbursementRepository();
    repository.mockCashAdvanceDetail = sampleDetail;
  });

  tearDown(() {
    SecureStorageService.instance.setPermissionsInMemory([]);
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
    testWidgets('renders detail info, employee card with employeeNumber and company, and settlement action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Kasbon Pembelian Alat'), findsWidgets);
      expect(find.text('ADV-2026-0001'), findsOneWidget);
      expect(find.text('INFORMASI PENGAJU'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsWidgets);
      expect(find.text('EMP-ADV-001'), findsOneWidget);
      expect(find.text('PT Muratech Mandiri'), findsWidgets);
      expect(find.text('emp-1'), findsNothing);
      expect(find.text('Status Penyelesaian Kasbon'), findsOneWidget);
      expect(find.text('Selesaikan Nota'), findsOneWidget);
      expect(find.text('Kembalikan Sisa'), findsOneWidget);
      expect(find.text('PEJABAT PENYETUJU'), findsNothing);
    });

    testWidgets('renders PEJABAT PENYETUJU card with employeeNumber and company when approver or notes are present', (tester) async {
      repository.mockCashAdvanceDetail = const CashAdvanceDetailModel(
        id: 'adv-004',
        advanceNumber: 'ADV-2026-0004',
        title: 'Kasbon Disetujui',
        purpose: 'Kebutuhan urgent',
        requestedAmount: 1500000.0,
        approvedAmount: 1500000.0,
        status: 'approved',
        createdAt: '2026-09-22T08:00:00.000Z',
        disbursementNotes: 'Disetujui untuk operasional mendesak',
        employee: ExpenseEmployeeModel(
          id: 'emp-1',
          employeeNumber: 'EMP-ADV-001',
          firstName: 'Sarah',
          lastName: 'Connor',
          email: 'sarah@example.com',
          jobPosition: 'Procurement Specialist',
          company: 'PT Muratech Mandiri',
        ),
        approver: ExpenseEmployeeModel(
          id: 'emp-lead',
          employeeNumber: 'LEAD-2024-009',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          jobPosition: 'Division Head',
          department: 'Operations',
          company: 'PT Muratech Mandiri',
        ),
      );

      await tester.pumpWidget(buildTestWidget(id: 'adv-004'));
      await tester.pumpAndSettle();

      expect(find.text('INFORMASI PENGAJU'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsWidgets);
      expect(find.text('PEJABAT PENYETUJU'), findsOneWidget);
      expect(find.text('John Doe'), findsWidgets);
      // Kartu approver ringkas: nomor pegawai approver tidak ditampilkan.
      expect(find.text('LEAD-2024-009'), findsNothing);
      expect(find.text('emp-lead'), findsNothing);
      expect(find.text('Disetujui untuk operasional mendesak'), findsOneWidget);
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

    testWidgets('hides Setujui and Tolak buttons when user lacks approval permission', (tester) async {
      SecureStorageService.instance.setPermissionsInMemory([]);

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

      expect(find.text('Setujui'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
    });
  });
}
