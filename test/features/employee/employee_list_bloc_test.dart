import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';

class MockEmployeeRepository implements EmployeeRepository {
  List<EmployeeDirectoryItem> mockEmployees = [];
  int lastRequestedPage = 1;
  String? lastSearch;
  String? lastCompanyId;
  String? lastDepartmentId;
  String? lastPositionId;
  bool shouldThrow = false;

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    lastRequestedPage = page;
    lastSearch = search;
    lastCompanyId = companyId;
    lastDepartmentId = departmentId;
    lastPositionId = positionId;

    return EmployeeListResponse(
      success: true,
      message: 'Success',
      data: mockEmployees,
      meta: EmployeePaginationMeta(
        page: page,
        limit: size,
        total: mockEmployees.length,
        totalPages: 3,
      ),
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async {
    throw UnimplementedError();
  }
}

void main() {
  group('EmployeeListBloc Unit Tests', () {
    late MockEmployeeRepository mockRepo;
    final sampleItem1 = const EmployeeDirectoryItem(
      id: 'emp-1',
      name: 'Alice Johnson',
      role: 'Engineering Lead',
      department: 'Engineering',
      email: 'alice@oasis.corp',
      initials: 'AJ',
      company: 'PT Oasish Group',
    );
    final sampleItem2 = const EmployeeDirectoryItem(
      id: 'emp-2',
      name: 'Bob Smith',
      role: 'Product Manager',
      department: 'Product',
      email: 'bob@oasis.corp',
      initials: 'BS',
      company: 'PT Oasish Nusantara',
    );

    setUp(() {
      mockRepo = MockEmployeeRepository();
      mockRepo.mockEmployees = [sampleItem1, sampleItem2];
    });

    test('Initial state is correct when initialized without custom employees', () {
      final bloc = EmployeeListBloc(repository: mockRepo);
      expect(bloc.state.status, EmployeeListStatus.initial);
      expect(bloc.state.employees, isEmpty);
      expect(bloc.state.isLoading, isFalse);
      bloc.close();
    });

    test('Initial state uses customEmployees when provided in constructor', () {
      final bloc = EmployeeListBloc(
        repository: mockRepo,
        initialCustomEmployees: [sampleItem1],
      );
      expect(bloc.state.status, EmployeeListStatus.success);
      expect(bloc.state.employees.length, 1);
      expect(bloc.state.employees.first.name, 'Alice Johnson');
      bloc.close();
    });

    test('EmployeeListStarted fetches page 1 and emits success', () async {
      final bloc = EmployeeListBloc(repository: mockRepo);

      bloc.add(const EmployeeListStarted());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeListState>((s) => s.isLoading == true),
          predicate<EmployeeListState>((s) =>
              s.isLoading == false &&
              s.status == EmployeeListStatus.success &&
              s.employees.length == 2),
        ]),
      );

      expect(mockRepo.lastRequestedPage, 1);
      bloc.close();
    });

    test('EmployeeListLoadMore appends items from next page', () async {
      final bloc = EmployeeListBloc(repository: mockRepo);

      bloc.add(const EmployeeListStarted());
      await bloc.stream.firstWhere((s) => s.status == EmployeeListStatus.success);

      // Now load more
      final sampleItem3 = const EmployeeDirectoryItem(
        id: 'emp-3',
        name: 'Charlie Brown',
        role: 'Designer',
        department: 'Product',
        email: 'charlie@oasis.corp',
        initials: 'CB',
      );
      mockRepo.mockEmployees = [sampleItem3];

      bloc.add(const EmployeeListLoadMore());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeListState>((s) => s.isLoadingMore == true),
          predicate<EmployeeListState>((s) =>
              s.isLoadingMore == false &&
              s.employees.length == 3 &&
              s.currentPage == 2),
        ]),
      );

      expect(mockRepo.lastRequestedPage, 2);
      bloc.close();
    });

    test('EmployeeListSearchChanged triggers new search request', () async {
      final bloc = EmployeeListBloc(repository: mockRepo);

      bloc.add(const EmployeeListSearchChanged('Alice'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeListState>((s) => s.searchQuery == 'Alice'),
          predicate<EmployeeListState>((s) => s.isLoading == true),
          predicate<EmployeeListState>((s) => s.isLoading == false),
        ]),
      );

      expect(mockRepo.lastSearch, 'Alice');
      bloc.close();
    });

    test('EmployeeListFilterApplied updates criteria and reloads', () async {
      final bloc = EmployeeListBloc(repository: mockRepo);
      const criteria = EmployeeFilterCriteria(
        companyId: 'comp-1',
        departmentId: 'dept-1',
      );

      bloc.add(const EmployeeListFilterApplied(criteria));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeListState>((s) => s.filterCriteria == criteria),
          predicate<EmployeeListState>((s) => s.isLoading == true),
          predicate<EmployeeListState>((s) => s.isLoading == false),
        ]),
      );

      expect(mockRepo.lastCompanyId, 'comp-1');
      expect(mockRepo.lastDepartmentId, 'dept-1');
      bloc.close();
    });

    test('Error during fetch falls back gracefully to sample data', () async {
      mockRepo.shouldThrow = true;
      final bloc = EmployeeListBloc(repository: mockRepo);

      bloc.add(const EmployeeListStarted());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeListState>((s) => s.isLoading == true),
          predicate<EmployeeListState>((s) =>
              s.isLoading == false &&
              s.status == EmployeeListStatus.failure &&
              s.employees.isNotEmpty),
        ]),
      );
      bloc.close();
    });

    test('Team attendance fetches from AttendanceRepository successfully', () async {
      final teamRepo = MockTeamAttendanceRepository();
      teamRepo.teamEmployees = [sampleItem1, sampleItem2];
      final bloc = EmployeeListBloc(
        repository: mockRepo,
        attendanceRepository: teamRepo,
      );

      bloc.add(const EmployeeListStarted(isTeamAttendance: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeListState>((s) => s.isLoading == true && s.isTeamAttendance == true),
          predicate<EmployeeListState>((s) =>
              s.isLoading == false &&
              s.status == EmployeeListStatus.success &&
              s.employees.length == 2 &&
              s.isTeamAttendance == true),
        ]),
      );
      bloc.close();
    });

    test('Team attendance 403 error sets Tidak ada hak akses and isForbidden true', () async {
      final teamRepo = MockTeamAttendanceRepository();
      teamRepo.throw403 = true;
      final bloc = EmployeeListBloc(
        repository: mockRepo,
        attendanceRepository: teamRepo,
      );

      bloc.add(const EmployeeListStarted(isTeamAttendance: true));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EmployeeListState>((s) => s.isLoading == true && s.isTeamAttendance == true),
          predicate<EmployeeListState>((s) =>
              s.isLoading == false &&
              s.status == EmployeeListStatus.failure &&
              s.errorMessage == 'Tidak ada hak akses' &&
              s.statusCode == 403 &&
              s.isForbidden == true &&
              s.employees.isEmpty),
        ]),
      );
      bloc.close();
    });
  });
}

class MockTeamAttendanceRepository implements AttendanceRepository {
  List<EmployeeDirectoryItem> teamEmployees = [];
  bool throw403 = false;
  bool shouldThrow = false;

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async {
    if (throw403) {
      throw const ApiException(
        message: 'Tidak ada hak akses',
        statusCode: 403,
      );
    }
    if (shouldThrow) {
      throw const ApiException(
        message: 'Server error',
        statusCode: 500,
      );
    }
    return teamEmployees;
  }

  @override
  Future<AttendanceLogListResponse> getAttendanceLogs({
    int page = 1,
    int size = 20,
    String? employeeId,
    bool lastMonth = false,
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  }) async => throw UnimplementedError();

  @override
  Future<AttendanceTodayData> getTodayAttendance() async => throw UnimplementedError();

  @override
  Future<AttendanceTodayData> clockIn({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async => throw UnimplementedError();

  @override
  Future<AttendanceTodayData> clockOut({
    required double latitude,
    required double longitude,
    String? address,
    String? note,
  }) async => throw UnimplementedError();

  @override
  Future<AttendanceTodayData> toggleBreak() async => throw UnimplementedError();

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async => throw UnimplementedError();

  @override
  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId}) async => throw UnimplementedError();
}
