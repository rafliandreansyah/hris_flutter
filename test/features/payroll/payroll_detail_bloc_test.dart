import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_bloc.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_detail/payroll_detail_state.dart';

import 'mock_payroll_repository.dart';

void main() {
  late MockPayrollRepository repository;
  late PayrollDetailBloc bloc;

  const sampleDetail = PayrollDetailModel(
    id: 'pay-001',
    status: 'paid',
    grossSalary: 10000000.0,
    deductions: 1000000.0,
    netSalary: 9000000.0,
    terbilang: 'Sembilan Juta Rupiah',
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

  setUp(() {
    repository = MockPayrollRepository();
    bloc = PayrollDetailBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('PayrollDetailBloc Unit Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.status, PayrollDetailStatus.initial);
      expect(bloc.state.detail, isNull);
      expect(bloc.state.isDownloading, isFalse);
      expect(bloc.state.isPrivacyMasked, isTrue);
      expect(bloc.state.errorMessage, isNull);
    });

    test('PayrollDetailFetched emits loading then success with detail', () async {
      repository.mockPayrollDetail = sampleDetail;

      final states = <PayrollDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollDetailFetched('pay-001'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollDetailStatus.loading);
      expect(states[1].status, PayrollDetailStatus.success);
      expect(states[1].detail?.id, 'pay-001');
      expect(states[1].detail?.netSalary, 9000000.0);
      expect(states[1].detail?.terbilang, 'Sembilan Juta Rupiah');
    });

    test('PayrollDetailDownloadRequested prepares PDF download successfully', () async {
      repository.mockPayrollDetail = sampleDetail;
      repository.mockDownloadResult = const PayrollDownloadResponseModel(
        payrollId: 'pay-001',
        payslipUrl: 'https://storage.googleapis.com/test/slip.pdf',
        isNewlyGenerated: true,
      );

      final states = <PayrollDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollDetailFetched('pay-001'));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const PayrollDetailDownloadRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 4);
      expect(states[2].isDownloading, isTrue);
      expect(states[3].isDownloading, isFalse);
      expect(states[3].downloadedPdfUrl, 'https://storage.googleapis.com/test/slip.pdf');
    });

    test('PayrollDetailPrivacyToggled toggles isPrivacyMasked state', () async {
      final states = <PayrollDetailState>[];
      bloc.stream.listen(states.add);

      expect(bloc.state.isPrivacyMasked, isTrue);
      bloc.add(const PayrollDetailPrivacyToggled());
      await Future.delayed(const Duration(milliseconds: 30));

      expect(states.length, 1);
      expect(states[0].isPrivacyMasked, isFalse);

      bloc.add(const PayrollDetailPrivacyToggled());
      await Future.delayed(const Duration(milliseconds: 30));

      expect(states.length, 2);
      expect(states[1].isPrivacyMasked, isTrue);
    });

    test('PayrollDetailFetched emits failure on ApiException', () async {
      repository.errorToThrow = const ApiException(message: 'Slip tidak ditemukan');

      final states = <PayrollDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollDetailFetched('pay-999'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollDetailStatus.loading);
      expect(states[1].status, PayrollDetailStatus.failure);
      expect(states[1].errorMessage, 'Slip tidak ditemukan');
    });
  });
}
