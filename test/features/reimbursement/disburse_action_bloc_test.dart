import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_state.dart';
import 'package:image_picker/image_picker.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;
  late DisburseActionBloc bloc;

  setUp(() {
    repository = MockReimbursementRepository();
    bloc = DisburseActionBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('DisburseActionBloc Tests', () {
    test('initial state defaults to manual_transfer and not submitting', () {
      expect(bloc.state.method, 'manual_transfer');
      expect(bloc.state.proofFile, isNull);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.isSuccess, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });

    test('DisburseMethodChanged switches between methods correctly', () async {
      bloc.add(const DisburseMethodChanged('cash'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.method, 'cash');

      bloc.add(const DisburseMethodChanged('payroll'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.method, 'payroll');
    });

    test('DisburseProofFileChanged adds and removes proof file', () async {
      final file = XFile('transfer_receipt.jpg');
      bloc.add(DisburseProofFileChanged(file));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.proofFile?.path, 'transfer_receipt.jpg');

      bloc.add(const DisburseProofFileChanged(null));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.proofFile, isNull);
    });

    test('DisburseSubmitted succeeds for manual_transfer', () async {
      bloc.add(DisburseProofFileChanged(XFile('proof.jpg')));

      final states = <DisburseActionState>[];
      bloc.stream.listen(states.add);

      bloc.add(const DisburseSubmitted(
        claimId: 'clm-1',
        paymentReference: 'TRF-BCA-999',
        bankName: 'BCA',
        bankAccountNumber: '123456789',
        bankAccountHolder: 'Budi Santoso',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastDisbursementMethod, 'manual_transfer');
      expect(states.any((s) => s.isSubmitting), isTrue);
      expect(states.last.isSuccess, isTrue);
      expect(states.last.isSubmitting, isFalse);
      expect(states.last.errorMessage, isNull);
    });

    test('DisburseSubmitted succeeds for cash disbursement', () async {
      bloc.add(const DisburseMethodChanged('cash'));

      final states = <DisburseActionState>[];
      bloc.stream.listen(states.add);

      bloc.add(const DisburseSubmitted(
        claimId: 'adv-1',
        notes: 'Diserahkan langsung tunai',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastDisbursementMethod, 'cash');
      expect(states.last.isSuccess, isTrue);
      expect(states.last.isSubmitting, isFalse);
    });

    test('DisburseSubmitted succeeds for payroll disbursement', () async {
      bloc.add(const DisburseMethodChanged('payroll'));

      final states = <DisburseActionState>[];
      bloc.stream.listen(states.add);

      bloc.add(const DisburseSubmitted(
        claimId: 'clm-1',
        payrollPeriodId: 'period-2026-10',
        notes: 'Akan cair pada gaji bulan Oktober',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastDisbursementMethod, 'payroll');
      expect(states.last.isSuccess, isTrue);
      expect(states.last.isSubmitting, isFalse);
    });

    test('DisburseSubmitted handles server error', () async {
      repository.errorToThrow = const ApiException(
        message: 'Gagal memproses pencairan',
      );

      bloc.add(const DisburseMethodChanged('payroll'));

      final states = <DisburseActionState>[];
      bloc.stream.listen(states.add);

      bloc.add(const DisburseSubmitted(claimId: 'clm-1'));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.isSubmitting, isFalse);
      expect(states.last.isSuccess, isFalse);
      expect(states.last.errorMessage, 'Gagal memproses pencairan');
    });
  });
}
