import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_state.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;
  late ReimbursementDetailBloc bloc;

  const sampleDetail = ReimbursementDetailModel(
    id: 'clm-001',
    claimNumber: 'CLM-2026-0001',
    title: 'Klaim Perjalanan Dinas',
    totalRequestedAmount: 750000.0,
    status: 'requested',
    type: 'out_of_pocket',
    createdAt: '2026-09-22T08:00:00.000Z',
    employee: ExpenseEmployeeModel(
      id: 'emp-1',
      firstName: 'Sarah',
      email: 'sarah@example.com',
    ),
  );

  setUp(() {
    repository = MockReimbursementRepository();
    bloc = ReimbursementDetailBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ReimbursementDetailBloc Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.status, ReimbursementDetailStatus.initial);
      expect(bloc.state.detail, isNull);
      expect(bloc.state.isActionLoading, isFalse);
      expect(bloc.state.isActionSuccess, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });

    test('ReimbursementDetailFetched emits loading then success with detail', () async {
      repository.mockReimbursementDetail = sampleDetail;

      final states = <ReimbursementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ReimbursementDetailFetched('clm-001'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, ReimbursementDetailStatus.loading);
      expect(states[1].status, ReimbursementDetailStatus.success);
      expect(states[1].detail?.claimNumber, 'CLM-2026-0001');
      expect(states[1].errorMessage, isNull);
    });

    test('ReimbursementDetailFetched emits failure on ApiException', () async {
      repository.errorToThrow = const ApiException(
        message: 'Klaim tidak ditemukan',
        statusCode: 404,
      );

      final states = <ReimbursementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ReimbursementDetailFetched('clm-999'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, ReimbursementDetailStatus.loading);
      expect(states[1].status, ReimbursementDetailStatus.failure);
      expect(states[1].errorMessage, 'Klaim tidak ditemukan');
    });

    test('ReimbursementDetailApproved approves claim successfully and re-fetches', () async {
      repository.mockReimbursementDetail = sampleDetail;
      bloc.add(const ReimbursementDetailFetched('clm-001'));
      await Future.delayed(const Duration(milliseconds: 30));

      final states = <ReimbursementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ReimbursementDetailApproved(
        isApproved: true,
        approverNotes: 'Disetujui penuh',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastApproveAction, isTrue);
      expect(repository.lastApproverNotes, 'Disetujui penuh');
      expect(states.any((s) => s.isActionLoading), isTrue);
      expect(states.any((s) => s.isActionSuccess), isTrue);
      expect(states.last.actionSuccessMessage, contains('disetujui'));
    });

    test('ReimbursementDetailApproved rejects claim successfully', () async {
      repository.mockReimbursementDetail = sampleDetail;
      bloc.add(const ReimbursementDetailFetched('clm-001'));
      await Future.delayed(const Duration(milliseconds: 30));

      final states = <ReimbursementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ReimbursementDetailApproved(
        isApproved: false,
        rejectionReason: 'Nota tidak valid',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastApproveAction, isFalse);
      expect(repository.lastApproverNotes, 'Nota tidak valid');
      expect(states.any((s) => s.isActionSuccess), isTrue);
      expect(states.last.actionSuccessMessage, contains('ditolak'));
    });

    test('ReimbursementDetailDeleted sukses -> isDeleted true & id terkirim ke repository', () async {
      repository.mockReimbursementDetail = sampleDetail;
      bloc.add(const ReimbursementDetailFetched('clm-001'));
      await Future.delayed(const Duration(milliseconds: 50));

      final states = <ReimbursementDetailState>[];
      bloc.stream.listen(states.add);
      bloc.add(const ReimbursementDetailDeleted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.first.isActionLoading, isTrue);
      expect(states.last.isActionLoading, isFalse);
      expect(states.last.isDeleted, isTrue);
      expect(states.last.actionSuccessMessage, contains('berhasil dihapus'));
      expect(repository.deletedIds, ['clm-001']);
    });

    test('ReimbursementDetailDeleted gagal -> pesan dari API & tidak ditandai terhapus', () async {
      repository.mockReimbursementDetail = sampleDetail;
      bloc.add(const ReimbursementDetailFetched('clm-001'));
      await Future.delayed(const Duration(milliseconds: 50));
      repository.errorToThrow = const ApiException(
        message: 'Pengajuan yang sudah diproses tidak dapat dihapus.',
        statusCode: 400,
      );

      bloc.add(const ReimbursementDetailDeleted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isDeleted, isFalse);
      expect(bloc.state.isActionLoading, isFalse);
      expect(bloc.state.errorMessage, 'Pengajuan yang sudah diproses tidak dapat dihapus.');
    });
  });
}
