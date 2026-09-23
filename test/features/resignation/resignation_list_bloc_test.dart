import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_bloc.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_event.dart';

class _MockResignationRepository implements ResignationRepository {
  MyResignationStatusModel? mockMyStatus;
  SubordinateResignationResponseModel? mockSubordinates;
  bool shouldThrowError = false;
  String errorMessage = 'Internal Server Error';
  bool cancelCalled = false;

  @override
  Future<MyResignationStatusModel> getMyResignationStatus() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockMyStatus ??
        const MyResignationStatusModel(
          hasActiveResignation: false,
          daysRemaining: 0,
        );
  }

  @override
  Future<SubordinateResignationResponseModel> getSubordinateResignations({
    String status = 'pending',
    int page = 1,
    int size = 10,
    String? search,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? startDate,
    String? endDate,
  }) async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return mockSubordinates ??
        const SubordinateResignationResponseModel(
          success: true,
          message: 'OK',
          data: [],
          meta: ResignationPaginationMeta(
            page: 1,
            size: 10,
            total: 0,
            totalPages: 1,
          ),
        );
  }

  @override
  Future<void> cancelMyResignation() async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    cancelCalled = true;
  }

  @override
  Future<ResignationDetailModel> getResignationDetail(String id) async {
    if (shouldThrowError) {
      throw ApiException(message: errorMessage);
    }
    return const ResignationDetailModel(
      id: 'test-id',
      companyId: 'comp-1',
      employeeId: 'emp-1',
    );
  }
}

void main() {
  late _MockResignationRepository repository;
  late ResignationListBloc bloc;

  setUp(() {
    repository = _MockResignationRepository();
    bloc = ResignationListBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ResignationListBloc Tests', () {
    test('Initial state contains default properties', () {
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.isMyStatusLoading, false);
      expect(bloc.state.myStatus, isNull);
      expect(bloc.state.hasActiveResignation, false);
      expect(bloc.state.subordinates, isEmpty);
      expect(bloc.state.subordinatesStatusFilter, 'pending');
    });

    test('TabChanged event updates currentTabIndex', () async {
      bloc.add(const ResignationListTabChanged(1));
      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>(
          (state) => state.currentTabIndex == 1,
        )),
      );
    });

    test('MyStatusRequested emits loading then success', () async {
      const sampleStatus = MyResignationStatusModel(
        hasActiveResignation: true,
        daysRemaining: 24,
        resignation: ResignationDetailModel(
          id: 'res-1',
          companyId: 'comp-1',
          employeeId: 'emp-1',
          status: 'manager_approved',
          reason: 'Mendapat karir baru',
        ),
      );
      repository.mockMyStatus = sampleStatus;

      bloc.add(const ResignationListMyStatusRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isMyStatusLoading == true),
          predicate<dynamic>((s) =>
              s.isMyStatusLoading == false &&
              s.hasActiveResignation == true &&
              s.myStatus?.daysRemaining == 24),
        ]),
      );
    });

    test('MyStatusRequested handles ApiException failure', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Network connection lost';

      bloc.add(const ResignationListMyStatusRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isMyStatusLoading == true),
          predicate<dynamic>((s) =>
              s.isMyStatusLoading == false &&
              s.errorMessage == 'Network connection lost'),
        ]),
      );
    });

    test('SubordinatesRequested fetches subordinate resignation list', () async {
      const sampleResponse = SubordinateResignationResponseModel(
        success: true,
        message: 'Success',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-1',
            companyId: 'comp-1',
            employeeId: 'emp-2',
            employeeName: 'Dimas Prasetyo',
            status: 'submitted',
          ),
        ],
        meta: ResignationPaginationMeta(
          page: 1,
          size: 10,
          total: 1,
          totalPages: 1,
        ),
      );
      repository.mockSubordinates = sampleResponse;

      bloc.add(const ResignationListSubordinatesRequested(statusFilter: 'pending'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isSubordinatesLoading == true),
          predicate<dynamic>((s) =>
              s.isSubordinatesLoading == false &&
              s.subordinates.length == 1 &&
              s.subordinates.first.employeeName == 'Dimas Prasetyo'),
        ]),
      );
    });

    test('SubordinatesLoadMore appends next page items', () async {
      const page1 = SubordinateResignationResponseModel(
        success: true,
        message: 'Success',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-1',
            companyId: 'comp-1',
            employeeId: 'emp-1',
            employeeName: 'User 1',
          ),
        ],
        meta: ResignationPaginationMeta(
          page: 1,
          size: 10,
          total: 2,
          totalPages: 2,
        ),
      );
      repository.mockSubordinates = page1;
      bloc.add(const ResignationListSubordinatesRequested());
      await bloc.stream.firstWhere((s) => !s.isSubordinatesLoading);

      const page2 = SubordinateResignationResponseModel(
        success: true,
        message: 'Success',
        data: [
          SubordinateResignationItemModel(
            id: 'sub-2',
            companyId: 'comp-1',
            employeeId: 'emp-2',
            employeeName: 'User 2',
          ),
        ],
        meta: ResignationPaginationMeta(
          page: 2,
          size: 10,
          total: 2,
          totalPages: 2,
        ),
      );
      repository.mockSubordinates = page2;

      bloc.add(const ResignationListSubordinatesLoadMore());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isSubordinatesLoadingMore == true),
          predicate<dynamic>((s) =>
              s.isSubordinatesLoadingMore == false &&
              s.subordinates.length == 2 &&
              s.subordinatesPage == 2),
        ]),
      );
    });

    test('FilterApplied updates filterData and triggers fetch', () async {
      const filter = AppRequestFilterData(company: 'PT Muratech Mandiri');
      bloc.add(const ResignationListFilterApplied(filter));

      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>(
          (s) => s.filterData.company == 'PT Muratech Mandiri',
        )),
      );
    });

    test('CancelRequested invokes cancel repository and emits success', () async {
      bloc.add(const ResignationListCancelRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isCancelling == true),
          predicate<dynamic>((s) => s.isCancelling == false && s.cancelSuccess == true),
          predicate<dynamic>((s) => s.isMyStatusLoading == true),
          predicate<dynamic>((s) => s.isMyStatusLoading == false),
        ]),
      );
      expect(repository.cancelCalled, true);
    });
  });
}
