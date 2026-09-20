import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_filter_criteria.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_bloc.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_event.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_list_state.dart';

class _MockWarningLetterRepository implements WarningLetterRepository {
  final Future<WarningLetterListResponse> Function({
    required int page,
    required int size,
    String? letterTypeId,
    String? status,
    String? search,
    required bool approver,
    String? startDate,
    String? endDate,
  })? onGetWarningLetters;

  final Future<List<WarningLetterTypeModel>> Function()?
      onGetWarningLetterTypes;

  int lastPage = 0;
  int lastSize = 0;
  bool lastApprover = false;
  String? lastSearch;
  String? lastStatus;
  int callCount = 0;
  final List<bool> approverCalls = [];

  _MockWarningLetterRepository({
    this.onGetWarningLetters,
    this.onGetWarningLetterTypes,
  });

  @override
  Future<WarningLetterListResponse> getWarningLetters({
    required int page,
    required int size,
    String? letterTypeId,
    String? status,
    String? search,
    required bool approver,
    String? startDate,
    String? endDate,
  }) async {
    lastPage = page;
    lastSize = size;
    lastApprover = approver;
    lastSearch = search;
    lastStatus = status;
    callCount++;
    approverCalls.add(approver);

    if (onGetWarningLetters != null) {
      return onGetWarningLetters!(
        page: page,
        size: size,
        letterTypeId: letterTypeId,
        status: status,
        search: search,
        approver: approver,
        startDate: startDate,
        endDate: endDate,
      );
    }

    return const WarningLetterListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: WarningLetterPaginationMeta(
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() async {
    if (onGetWarningLetterTypes != null) {
      return onGetWarningLetterTypes!();
    }
    return const [
      WarningLetterTypeModel(
        id: 'type-1',
        name: 'SP 1',
        level: 1,
        validityPeriodMonths: 6,
      ),
    ];
  }

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) async {
    return null;
  }

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    return const CreateWarningLetterResponse(
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) async {
    return const WarningLetterDetail(
      id: 'wl-1',
      warningLetterType: WarningLetterTypeSummary(level: 1, name: 'SP 1'),
      timezone: 'WIB',
      isActive: true,
      createdAt: null,
      issuedDate: null,
      expiredDate: null,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleItem = WarningLetterItem(
    id: 'wl-1',
    warningLetterType: const WarningLetterTypeSummary(level: 1, name: 'SP 1'),
    employee: const WarningLetterEmployee(
      id: 'emp-1',
      firstName: 'Budi',
      lastName: 'Santoso',
    ),
    isActive: true,
    createdAt: DateTime(2026, 9, 19),
    timezone: 'WIB',
  );

  group('WarningLetterListBloc Unit Tests', () {
    test('initial state has correct default values', () {
      final bloc = WarningLetterListBloc(
        repository: _MockWarningLetterRepository(),
      );
      expect(bloc.state.myLetters, isEmpty);
      expect(bloc.state.teamLetters, isEmpty);
      expect(bloc.state.isMyLoading, false);
      expect(bloc.state.isTeamLoading, false);
      expect(bloc.state.isTeamForbidden, false);
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.searchQuery, '');
    });

    test('WarningLetterListStarted loads both tab 0 and tab 1 and letter types',
        () async {
      final repo = _MockWarningLetterRepository(
        onGetWarningLetters: ({
          required int page,
          required int size,
          String? letterTypeId,
          String? status,
          String? search,
          required bool approver,
          String? startDate,
          String? endDate,
        }) async {
          return WarningLetterListResponse(
            success: true,
            message: 'OK',
            data: [sampleItem],
            meta: const WarningLetterPaginationMeta(
              page: 1,
              limit: 10,
              total: 1,
              totalPages: 1,
            ),
          );
        },
        onGetWarningLetterTypes: () async => [
          const WarningLetterTypeModel(
            id: 'type-custom',
            name: 'SP 1 Khusus',
            level: 1,
            validityPeriodMonths: 6,
          ),
        ],
      );

      final bloc = WarningLetterListBloc(repository: repo);
      bloc.add(const WarningLetterListStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<WarningLetterListState>((state) {
            return !state.isMyLoading &&
                !state.isTeamLoading &&
                state.myLetters.length == 1 &&
                state.teamLetters.length == 1 &&
                !state.isTeamForbidden &&
                state.letterTypes.isNotEmpty;
          }),
        ),
      );

      expect(repo.approverCalls.contains(false), true);
      expect(repo.approverCalls.contains(true), true);
    });

    test(
        'WarningLetterListStarted with 403 Forbidden sets isTeamForbidden to true and keeps myLetters intact',
        () async {
      final repo = _MockWarningLetterRepository(
        onGetWarningLetters: ({
          required int page,
          required int size,
          String? letterTypeId,
          String? status,
          String? search,
          required bool approver,
          String? startDate,
          String? endDate,
        }) async {
          if (approver) {
            throw const ApiException(
              message: 'Anda tidak memiliki hak akses',
              statusCode: 403,
            );
          }
          return WarningLetterListResponse(
            success: true,
            message: 'OK',
            data: [sampleItem],
            meta: const WarningLetterPaginationMeta(
              page: 1,
              limit: 10,
              total: 1,
              totalPages: 1,
            ),
          );
        },
      );

      final bloc = WarningLetterListBloc(repository: repo);
      bloc.add(const WarningLetterListStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<WarningLetterListState>((state) {
            return !state.isTeamLoading &&
                state.isTeamForbidden == true &&
                state.teamLetters.isEmpty &&
                state.myLetters.length == 1;
          }),
        ),
      );
    });

    test('WarningLetterListStarted with non-403 error sets teamError',
        () async {
      final repo = _MockWarningLetterRepository(
        onGetWarningLetters: ({
          required int page,
          required int size,
          String? letterTypeId,
          String? status,
          String? search,
          required bool approver,
          String? startDate,
          String? endDate,
        }) async {
          if (approver) {
            throw const ApiException(
              message: 'Server error 500',
              statusCode: 500,
            );
          }
          return WarningLetterListResponse(
            success: true,
            message: 'OK',
            data: [sampleItem],
            meta: const WarningLetterPaginationMeta(
              page: 1,
              limit: 10,
              total: 1,
              totalPages: 1,
            ),
          );
        },
      );

      final bloc = WarningLetterListBloc(repository: repo);
      bloc.add(const WarningLetterListStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<WarningLetterListState>((state) {
            return !state.isTeamLoading &&
                state.isTeamForbidden == false &&
                state.teamError == 'Server error 500';
          }),
        ),
      );
    });

    test('WarningLetterListTabChanged updates currentTabIndex', () async {
      final bloc = WarningLetterListBloc(
        repository: _MockWarningLetterRepository(),
      );

      bloc.add(const WarningLetterListTabChanged(1));

      await expectLater(
        bloc.stream,
        emits(predicate<WarningLetterListState>(
          (state) => state.currentTabIndex == 1,
        )),
      );
    });

    test(
        'WarningLetterListSearchChanged updates searchQuery and refetches team tab',
        () async {
      final repo = _MockWarningLetterRepository();
      final bloc = WarningLetterListBloc(repository: repo);

      bloc.add(const WarningLetterListSearchChanged('Budi'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<WarningLetterListState>((state) {
            return state.searchQuery == 'Budi' && !state.isTeamLoading;
          }),
        ),
      );

      expect(repo.lastSearch, 'Budi');
      expect(repo.lastApprover, true);
    });

    test('WarningLetterListFilterApplied updates filterCriteria and refetches',
        () async {
      final repo = _MockWarningLetterRepository();
      final bloc = WarningLetterListBloc(repository: repo);

      const criteria = WarningLetterFilterCriteria(status: 'active');
      bloc.add(const WarningLetterListFilterApplied(criteria));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<WarningLetterListState>((state) {
            return state.filterCriteria.status == 'active' &&
                !state.isMyLoading &&
                !state.isTeamLoading;
          }),
        ),
      );

      expect(repo.lastStatus, 'active');
    });

    test('WarningLetterListLoadMoreRequested loads next page and appends data',
        () async {
      final itemPage1 = WarningLetterItem(
        id: 'item-p1',
        warningLetterType: const WarningLetterTypeSummary(level: 1, name: 'SP 1'),
        isActive: true,
        createdAt: DateTime(2026, 9, 1),
        timezone: 'WIB',
      );
      final itemPage2 = WarningLetterItem(
        id: 'item-p2',
        warningLetterType: const WarningLetterTypeSummary(level: 2, name: 'SP 2'),
        isActive: true,
        createdAt: DateTime(2026, 9, 2),
        timezone: 'WIB',
      );

      final repo = _MockWarningLetterRepository(
        onGetWarningLetters: ({
          required int page,
          required int size,
          String? letterTypeId,
          String? status,
          String? search,
          required bool approver,
          String? startDate,
          String? endDate,
        }) async {
          if (page == 1) {
            return WarningLetterListResponse(
              success: true,
              message: 'OK',
              data: [itemPage1],
              meta: const WarningLetterPaginationMeta(
                page: 1,
                limit: 10,
                total: 2,
                totalPages: 2,
              ),
            );
          } else {
            return WarningLetterListResponse(
              success: true,
              message: 'OK',
              data: [itemPage2],
              meta: const WarningLetterPaginationMeta(
                page: 2,
                limit: 10,
                total: 2,
                totalPages: 2,
              ),
            );
          }
        },
      );

      final bloc = WarningLetterListBloc(repository: repo);
      bloc.add(const WarningLetterListStarted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<WarningLetterListState>((state) {
            return !state.isTeamLoading && state.teamLetters.length == 1;
          }),
        ),
      );

      // Trigger load more untuk team
      bloc.add(const WarningLetterListLoadMoreRequested(isTeam: true));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<WarningLetterListState>((state) {
            return !state.isTeamLoadingMore &&
                state.teamLetters.length == 2 &&
                state.teamCurrentPage == 2;
          }),
        ),
      );
    });
  });
}
