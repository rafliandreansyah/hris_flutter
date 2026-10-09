import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_bloc.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_event.dart';
import 'package:hris_flutter/features/payroll/presentation/bloc/payroll_list/payroll_list_state.dart';

import 'mock_payroll_repository.dart';

void main() {
  late MockPayrollRepository repository;
  late PayrollListBloc bloc;

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
    bloc = PayrollListBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('PayrollListBloc Unit Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.status, PayrollListStatus.initial);
      expect(bloc.state.mySlips, isEmpty);
      expect(bloc.state.employees, isEmpty);
      expect(bloc.state.activeTab, 0);
      expect(bloc.state.isPrivacyMasked, isTrue);
      expect(bloc.state.errorMessage, isNull);
    });

    test('PayrollListStarted emits loading then success with data', () async {
      repository.mockPeriods = [samplePeriod];
      repository.mockMySlips = const PayrollListResponseModel(
        data: [sampleSlip],
        meta: PayrollPaginationMeta(
          page: 1,
          size: 10,
          total: 1,
          totalPages: 1,
        ),
      );

      final states = <PayrollListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollListStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollListStatus.loading);
      expect(states[1].status, PayrollListStatus.success);
      expect(states[1].mySlips.length, 1);
      expect(states[1].latestSlip, sampleSlip);
      expect(states[1].periods.length, 1);
    });

    test('PayrollListTabChanged switches activeTab correctly', () async {
      final states = <PayrollListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollListTabChanged(1));
      await Future.delayed(const Duration(milliseconds: 30));

      expect(states.length, 1);
      expect(states[0].activeTab, 1);
    });

    test('PayrollListPrivacyToggled toggles isPrivacyMasked state', () async {
      final states = <PayrollListState>[];
      bloc.stream.listen(states.add);

      expect(bloc.state.isPrivacyMasked, isTrue);
      bloc.add(const PayrollListPrivacyToggled());
      await Future.delayed(const Duration(milliseconds: 30));

      expect(states.length, 1);
      expect(states[0].isPrivacyMasked, isFalse);

      bloc.add(const PayrollListPrivacyToggled());
      await Future.delayed(const Duration(milliseconds: 30));

      expect(states.length, 2);
      expect(states[1].isPrivacyMasked, isTrue);
    });

    test('PayrollListYearChanged updates selectedYear and fetches data', () async {
      repository.mockMySlips = const PayrollListResponseModel(
        data: [sampleSlip],
        meta: PayrollPaginationMeta(
          page: 1,
          size: 10,
          total: 1,
          totalPages: 1,
        ),
      );

      final states = <PayrollListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollListYearChanged(2025));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].selectedYear, 2025);
      expect(states[0].status, PayrollListStatus.loading);
      expect(states[1].status, PayrollListStatus.success);
      expect(states[1].selectedYear, 2025);
    });

    test('PayrollListFilterApplied updates filters and reloads', () async {
      repository.mockMySlips = const PayrollListResponseModel(
        data: [],
        meta: PayrollPaginationMeta(page: 1, size: 10, total: 0, totalPages: 1),
      );

      final states = <PayrollListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollListFilterApplied(month: 8, status: 'paid'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollListStatus.loading);
      expect(states[0].selectedMonth, 8);
      expect(states[0].selectedStatus, 'paid');
      expect(states[1].status, PayrollListStatus.success);
    });

    test('PayrollListFilterApplied with year updates selectedYear and reloads', () async {
      repository.mockMySlips = const PayrollListResponseModel(
        data: [sampleSlip],
        meta: PayrollPaginationMeta(page: 1, size: 10, total: 1, totalPages: 1),
      );

      final states = <PayrollListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollListFilterApplied(year: 2024, month: 5, status: 'paid'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollListStatus.loading);
      expect(states[0].selectedYear, 2024);
      expect(states[0].selectedMonth, 5);
      expect(states[0].selectedStatus, 'paid');
      expect(states[1].status, PayrollListStatus.success);
      expect(states[1].selectedYear, 2024);
    });

    test('PayrollListStarted emits failure on ApiException', () async {
      repository.errorToThrow = const ApiException(message: 'Gagal memuat slip');

      final states = <PayrollListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PayrollListStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, PayrollListStatus.loading);
      expect(states[1].status, PayrollListStatus.failure);
      expect(states[1].errorMessage, 'Gagal memuat slip');
    });
  });
}
