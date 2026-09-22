import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_state.dart';
import 'package:image_picker/image_picker.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;
  late CreateReimbursementBloc bloc;

  final sampleCategories = [
    const ReimbursementCategoryModel(
      id: 'cat-1',
      companyId: 'comp-1',
      code: 'TRN',
      name: 'Transportasi',
      limitType: 'unlimited',
      isActive: true,
    ),
    const ReimbursementCategoryModel(
      id: 'cat-2',
      companyId: 'comp-1',
      code: 'FNB',
      name: 'Makan & Minum',
      limitType: 'unlimited',
      isActive: true,
    ),
  ];

  setUp(() {
    repository = MockReimbursementRepository();
    bloc = CreateReimbursementBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('CreateReimbursementBloc Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.isSuccess, isFalse);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.totalRequestedAmount, 0.0);
      expect(bloc.state.type, 'out_of_pocket');
    });

    test('CreateReimbursementStarted loads categories', () async {
      repository.mockCategories = sampleCategories;

      final states = <CreateReimbursementState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateReimbursementStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s.isCategoriesLoading), isTrue);
      expect(states.last.categories.length, 2);
    });

    test('Add and remove line items calculates totalRequestedAmount correctly', () async {
      bloc.add(const CreateReimbursementItemAdded({
        'categoryId': 'cat-1',
        'requestedAmount': 150000.0,
      }));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.items.length, 1);
      expect(bloc.state.totalRequestedAmount, 150000.0);

      bloc.add(const CreateReimbursementItemAdded({
        'categoryId': 'cat-2',
        'requestedAmount': 250000.0,
      }));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.items.length, 2);
      expect(bloc.state.totalRequestedAmount, 400000.0);

      bloc.add(const CreateReimbursementItemRemoved(0));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.items.length, 1);
      expect(bloc.state.totalRequestedAmount, 250000.0);
    });

    test('Type and file changes update state', () async {
      bloc.add(const CreateReimbursementTypeChanged('cash_advance_settlement'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.type, 'cash_advance_settlement');

      bloc.add(const CreateReimbursementCashAdvanceSelected('adv-123'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.cashAdvanceId, 'adv-123');

      final file = XFile('receipt.jpg');
      bloc.add(CreateReimbursementFileChanged(file));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.file?.path, 'receipt.jpg');
    });

    test('CreateReimbursementSubmitted validates empty items', () async {
      final states = <CreateReimbursementState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateReimbursementSubmitted(
        title: 'Bensin & Tol',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.errorMessage, 'Minimal sertakan 1 nota/struk pengeluaran');
      expect(states.last.isSubmitting, isFalse);
    });

    test('CreateReimbursementSubmitted submits successfully', () async {
      repository.mockCreatedClaimNumber = 'CLM-2026-999';

      bloc.add(const CreateReimbursementItemAdded({
        'categoryId': 'cat-1',
        'requestedAmount': 150000.0,
      }));
      await Future.delayed(const Duration(milliseconds: 20));

      final states = <CreateReimbursementState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateReimbursementSubmitted(
        title: 'Bensin & Tol',
        description: 'Operasional luar kota',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s.isSubmitting), isTrue);
      expect(states.last.isSuccess, isTrue);
      expect(states.last.createdClaimNumber, 'CLM-2026-999');
    });

    test('CreateReimbursementSubmitted handles ApiException error', () async {
      repository.errorToThrow = const ApiException(
        message: 'Gagal membuat klaim',
      );

      bloc.add(const CreateReimbursementItemAdded({
        'categoryId': 'cat-1',
        'requestedAmount': 150000.0,
      }));
      await Future.delayed(const Duration(milliseconds: 20));

      final states = <CreateReimbursementState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateReimbursementSubmitted(
        title: 'Bensin & Tol',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.isSubmitting, isFalse);
      expect(states.last.isSuccess, isFalse);
      expect(states.last.errorMessage, 'Gagal membuat klaim');
    });
  });
}
