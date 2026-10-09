import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_bloc.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_employee_slips/payroll_employee_slips_state.dart';

import 'mock_payroll_repository.dart';

void main() {
  late MockPayrollRepository repository;
  late PayrollEmployeeSlipsBloc bloc;

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

  setUp(() {
    repository = MockPayrollRepository();
    bloc = PayrollEmployeeSlipsBloc(
      repository: repository,
      employeeId: 'emp-001',
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('PayrollEmployeeSlipsBloc Unit Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.status, PayrollEmployeeSlipsStatus.initial);
      expect(bloc.state.slips, isEmpty);
      expect(bloc.state.employeeId, 'emp-001');
      expect(bloc.state.isPrivacyMasked, isTrue);
      expect(bloc.state.errorMessage, isNull);
    });

    test('PayrollEmployeeSlipsStarted fetches employee slips successfully', () async {
      repository.mockPayrolls = const PayrollListResponseModel(
        data: [sampleSlip],
        meta: PayrollPaginationMeta(page: 1, size: 10, total: 1, totalPages: 1),
      );

      final states = <PayrollEmployeeSlipsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollEmployeeSlipsStarted('emp-001'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollEmployeeSlipsStatus.loading);
      expect(states[1].status, PayrollEmployeeSlipsStatus.success);
      expect(states[1].slips.length, 1);
      expect(states[1].slips.first, sampleSlip);
    });

    test('PayrollEmployeeSlipsPrivacyToggled toggles privacy masking', () async {
      final states = <PayrollEmployeeSlipsState>[];
      bloc.stream.listen(states.add);

      expect(bloc.state.isPrivacyMasked, isTrue);
      bloc.add(const PayrollEmployeeSlipsPrivacyToggled());
      await Future.delayed(const Duration(milliseconds: 30));

      expect(states.length, 1);
      expect(states[0].isPrivacyMasked, isFalse);
    });

    test('PayrollEmployeeSlipsFilterApplied reloads slips with filters', () async {
      repository.mockPayrolls = const PayrollListResponseModel(
        data: [sampleSlip],
        meta: PayrollPaginationMeta(page: 1, size: 10, total: 1, totalPages: 1),
      );

      final states = <PayrollEmployeeSlipsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollEmployeeSlipsFilterApplied(year: 2025, month: 6, status: 'paid'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollEmployeeSlipsStatus.loading);
      expect(states[0].selectedYear, 2025);
      expect(states[0].selectedMonth, 6);
      expect(states[0].selectedStatus, 'paid');
      expect(states[1].status, PayrollEmployeeSlipsStatus.success);
    });

    test('PayrollEmployeeSlipsStarted emits failure on ApiException', () async {
      repository.errorToThrow = const ApiException(message: 'Akses ditolak');

      final states = <PayrollEmployeeSlipsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollEmployeeSlipsStarted('emp-001'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollEmployeeSlipsStatus.loading);
      expect(states[1].status, PayrollEmployeeSlipsStatus.failure);
      expect(states[1].errorMessage, 'Akses ditolak');
    });
  });
}
