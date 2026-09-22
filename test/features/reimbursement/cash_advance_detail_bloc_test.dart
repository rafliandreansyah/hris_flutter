import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_state.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;
  late CashAdvanceDetailBloc bloc;

  const sampleDetail = CashAdvanceDetailModel(
    id: 'adv-001',
    advanceNumber: 'ADV-2026-0001',
    title: 'Kasbon Dinas Luar Kota',
    purpose: 'Tiket dan hotel',
    requestedAmount: 3000000.0,
    approvedAmount: 3000000.0,
    status: 'disbursed',
    createdAt: '2026-09-22T08:00:00.000Z',
    employee: ExpenseEmployeeModel(
      id: 'emp-1',
      firstName: 'Sarah',
      email: 'sarah@example.com',
    ),
  );

  setUp(() {
    repository = MockReimbursementRepository();
    bloc = CashAdvanceDetailBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('CashAdvanceDetailBloc Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.status, CashAdvanceDetailStatus.initial);
      expect(bloc.state.detail, isNull);
      expect(bloc.state.isActionLoading, isFalse);
      expect(bloc.state.isActionSuccess, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });

    test('CashAdvanceDetailFetched emits loading then success with detail', () async {
      repository.mockCashAdvanceDetail = sampleDetail;

      final states = <CashAdvanceDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CashAdvanceDetailFetched('adv-001'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, CashAdvanceDetailStatus.loading);
      expect(states[1].status, CashAdvanceDetailStatus.success);
      expect(states[1].detail?.advanceNumber, 'ADV-2026-0001');
    });

    test('CashAdvanceDetailFetched emits failure on error', () async {
      repository.errorToThrow = const ApiException(
        message: 'Kasbon tidak ditemukan',
        statusCode: 404,
      );

      final states = <CashAdvanceDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CashAdvanceDetailFetched('adv-999'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.status, CashAdvanceDetailStatus.failure);
      expect(states.last.errorMessage, 'Kasbon tidak ditemukan');
    });

    test('CashAdvanceDetailApproved approves kasbon successfully', () async {
      repository.mockCashAdvanceDetail = sampleDetail;
      bloc.add(const CashAdvanceDetailFetched('adv-001'));
      await Future.delayed(const Duration(milliseconds: 30));

      final states = <CashAdvanceDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CashAdvanceDetailApproved(
        isApproved: true,
        approvedAmount: 3000000.0,
        approverNotes: 'Disetujui untuk perjalanan dinas',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastApproveAction, isTrue);
      expect(repository.lastApproverNotes, 'Disetujui untuk perjalanan dinas');
      expect(states.any((s) => s.isActionSuccess), isTrue);
    });

    test('CashAdvanceDetailRefundSubmitted submits refund and re-fetches', () async {
      repository.mockCashAdvanceDetail = sampleDetail;
      bloc.add(const CashAdvanceDetailFetched('adv-001'));
      await Future.delayed(const Duration(milliseconds: 30));

      final states = <CashAdvanceDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CashAdvanceRefundSubmitted(
        amount: 500000.0,
        method: 'cash_refund',
        notes: 'Sisa uang bensin',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastRefundAmount, 500000.0);
      expect(states.any((s) => s.isActionSuccess), isTrue);
      expect(states.last.actionSuccessMessage, contains('Pengembalian'));
    });
  });
}
