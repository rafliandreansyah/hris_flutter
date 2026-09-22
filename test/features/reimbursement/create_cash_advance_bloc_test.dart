import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_state.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;
  late CreateCashAdvanceBloc bloc;

  setUp(() {
    repository = MockReimbursementRepository();
    bloc = CreateCashAdvanceBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('CreateCashAdvanceBloc Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.isSuccess, isFalse);
      expect(bloc.state.createdAdvanceNumber, isNull);
      expect(bloc.state.errorMessage, isNull);
    });

    test('CreateCashAdvanceSubmitted succeeds with valid data', () async {
      repository.mockCreatedAdvanceNumber = 'ADV-2026-999';

      final states = <CreateCashAdvanceState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateCashAdvanceSubmitted(
        title: 'Kasbon Kunjungan',
        purpose: 'Kunjungan pabrik di Cikarang',
        requestedAmount: 500000.0,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s.isSubmitting), isTrue);
      expect(states.last.isSuccess, isTrue);
      expect(states.last.createdAdvanceNumber, 'ADV-2026-999');
    });

    test('CreateCashAdvanceSubmitted handles server error', () async {
      repository.errorToThrow = const ApiException(
        message: 'Gagal mengajukan kasbon',
      );

      final states = <CreateCashAdvanceState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateCashAdvanceSubmitted(
        title: 'Kasbon Kunjungan',
        purpose: 'Kunjungan pabrik di Cikarang',
        requestedAmount: 500000.0,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.isSubmitting, isFalse);
      expect(states.last.isSuccess, isFalse);
      expect(states.last.errorMessage, 'Gagal mengajukan kasbon');
    });
  });
}
