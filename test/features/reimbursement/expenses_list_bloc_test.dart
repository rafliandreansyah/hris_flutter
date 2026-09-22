import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/expenses_list/expenses_list_state.dart';

import 'mock_reimbursement_repository.dart';

void main() {
  late MockReimbursementRepository repository;
  late ExpensesListBloc bloc;

  const sampleItem = ExpenseFeedItemModel(
    id: 'item-1',
    referenceNumber: 'CLM-001',
    expenseType: 'reimbursement',
    title: 'Beli ATK',
    requestedAmount: 150000.0,
    status: 'requested',
    createdAt: '2026-09-22T08:00:00.000Z',
    employee: ExpenseEmployeeModel(
      id: 'emp-1',
      firstName: 'Budi',
      email: 'budi@example.com',
    ),
  );

  setUp(() {
    repository = MockReimbursementRepository();
    bloc = ExpensesListBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ExpensesListBloc Tests', () {
    test('initial state has correct default values', () {
      expect(bloc.state.isMyLoading, isFalse);
      expect(bloc.state.myExpenses, isEmpty);
      expect(bloc.state.isTeamLoading, isFalse);
      expect(bloc.state.teamExpenses, isEmpty);
      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.searchQuery, isEmpty);
      expect(bloc.state.filterCriteria, const AppRequestFilterData(status: 'requested'));
    });

    test('ExpensesListFetchRequested fetches My Expenses successfully', () async {
      repository.mockMyFeed = const ExpensesFeedResponseModel(
        items: [sampleItem],
        meta: ExpensesPaginationMeta(
          page: 1,
          limit: 10,
          total: 1,
          totalPages: 1,
        ),
      );

      final states = <ExpensesListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ExpensesListFetchRequested(isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastFeedApprover, isFalse);
      expect(states.any((s) => s.isMyLoading), isTrue);
      expect(states.last.myExpenses.length, 1);
      expect(states.last.myExpenses.first.title, 'Beli ATK');
      expect(states.last.myHasReachedMax, isTrue);
    });

    test('ExpensesListFetchRequested fetches Team Expenses successfully', () async {
      repository.mockTeamFeed = const ExpensesFeedResponseModel(
        items: [sampleItem],
        meta: ExpensesPaginationMeta(
          page: 1,
          limit: 10,
          total: 1,
          totalPages: 1,
        ),
      );

      final states = <ExpensesListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ExpensesListFetchRequested(isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repository.lastFeedApprover, isTrue);
      expect(states.any((s) => s.isTeamLoading), isTrue);
      expect(states.last.teamExpenses.length, 1);
      expect(states.last.isTeamForbidden, isFalse);
    });

    test('ExpensesListFetchRequested handles 403 Forbidden for Team tab', () async {
      repository.teamForbidden = true;

      final states = <ExpensesListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ExpensesListFetchRequested(isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.isTeamForbidden, isTrue);
      expect(states.last.isTeamLoading, isFalse);
    });

    test('ExpensesListFetchRequested handles general error', () async {
      repository.errorToThrow = const ApiException(
        message: 'Koneksi internet bermasalah',
      );

      final states = <ExpensesListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ExpensesListFetchRequested(isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last.errorMessage, 'Koneksi internet bermasalah');
      expect(states.last.isMyLoading, isFalse);
    });

    test('ExpensesListSearchChanged updates search query and triggers fetch with debounce', () async {
      final states = <ExpensesListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const ExpensesListSearchChanged('bensin'));

      // Debounce timer is 300ms
      await Future.delayed(const Duration(milliseconds: 350));
      expect(bloc.state.searchQuery, 'bensin');
      expect(repository.lastFeedSearch, 'bensin');
    });

    test('ExpensesListFilterApplied applies criteria and re-fetches', () async {
      const criteria = AppRequestFilterData(
        status: 'approved',
      );

      bloc.add(const ExpensesListFilterApplied(criteria));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.status, 'approved');
      expect(repository.lastFeedStatus, 'approved');
    });

    test('ExpensesListTypeFilterChanged updates currentTypeFilter and re-fetches', () async {
      bloc.add(const ExpensesListTypeFilterChanged('reimbursement'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.currentTypeFilter, 'reimbursement');
      expect(repository.lastFeedType, 'reimbursement');
    });

    test('ExpensesListFilterReset clears filter and re-fetches', () async {
      bloc.add(const ExpensesListFilterReset());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.status, 'requested');
    });
  });
}
