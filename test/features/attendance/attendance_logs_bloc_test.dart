import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_logs/attendance_logs_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

class MockAttendanceLogsRepository implements AttendanceRepository {
  List<AttendanceLogItem> logs = const [];
  List<EmployeeDirectoryItem> teamEmployees = const [];
  int totalPages = 1;
  bool shouldThrow = false;
  bool throwSummaryOnly = false;
  int? throwStatusCode;
  int lastRequestedPage = 0;
  String? lastEmployeeId;
  bool? lastMonthParam;
  String? lastStartDate;
  String? lastEndDate;
  String? lastType;
  String? lastStatus;

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
  }) async {
    if (shouldThrow) {
      throw ApiException(
        message: 'Server error',
        statusCode: throwStatusCode ?? 500,
      );
    }
    lastRequestedPage = page;
    lastEmployeeId = employeeId;
    lastMonthParam = lastMonth;
    lastStartDate = startDate;
    lastEndDate = endDate;
    lastType = type;
    lastStatus = status;

    final pageLogs = page == 1 ? logs : logs;
    return AttendanceLogListResponse(
      success: true,
      message: 'Success',
      data: pageLogs,
      meta: AttendanceLogPaginationMeta(
        page: page,
        limit: size,
        total: pageLogs.length * totalPages,
        totalPages: totalPages,
      ),
    );
  }

  @override
  Future<List<EmployeeDirectoryItem>> getAttendanceEmployees() async {
    if (shouldThrow) {
      throw ApiException(
        message: throwStatusCode == 403 ? 'Tidak ada hak akses' : 'Server error',
        statusCode: throwStatusCode ?? 500,
      );
    }
    return teamEmployees;
  }

  @override
  Future<AttendanceLogSummary> getAttendanceSummary({String? employeeId}) async {
    if (throwSummaryOnly) throw Exception('Summary unavailable');
    return const AttendanceLogSummary(
      totalInDays: 22,
      presentPercentage: 100,
      lateMinutes: 15,
      lateCount: 0,
    );
  }

  @override
  Future<AttendanceTodayData> getTodayAttendance() async =>
      throw UnimplementedError();

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
  Future<AttendanceTodayData> toggleBreak() async =>
      throw UnimplementedError();

  @override
  Future<void> reportLocationIssue({
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final logIn = AttendanceLogItem(
    id: 'LOG-1',
    dateTime: DateTime(2026, 8, 27, 8, 45),
    type: AttendanceLogType.clockIn,
    locationName: 'Jakarta HQ Office',
    method: 'GPS Mobile',
  );
  final logOut = AttendanceLogItem(
    id: 'LOG-2',
    dateTime: DateTime(2026, 8, 27, 17, 30),
    type: AttendanceLogType.clockOut,
    locationName: 'Jakarta HQ Office',
    method: 'GPS Mobile',
  );

  group('AttendanceLogsBloc Tests', () {
    late MockAttendanceLogsRepository repo;

    setUp(() {
      repo = MockAttendanceLogsRepository()
        ..logs = [logIn, logOut];
    });

    test('initial state is empty with initial status', () {
      final bloc = AttendanceLogsBloc(repository: repo);
      expect(bloc.state.status, AttendanceLogsStatus.initial);
      expect(bloc.state.logs, isEmpty);
      expect(bloc.state.summary, isNull);
      bloc.close();
    });

    test('Started emits loading then success with logs and summary', () async {
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceLogsState>(
            (s) => s.status == AttendanceLogsStatus.loading,
          ),
          predicate<AttendanceLogsState>(
            (s) =>
                s.status == AttendanceLogsStatus.success &&
                s.logs.length == 2 &&
                s.summary?.totalInDays == 22,
          ),
        ]),
      );
      expect(repo.lastRequestedPage, 1);
      await bloc.close();
    });

    test('failure propagates ApiException message and statusCode', () async {
      repo
        ..shouldThrow = true
        ..throwStatusCode = 500;
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceLogsState>(
            (s) => s.status == AttendanceLogsStatus.loading,
          ),
          predicate<AttendanceLogsState>(
            (s) =>
                s.status == AttendanceLogsStatus.failure &&
                s.errorMessage == 'Server error' &&
                s.statusCode == 500 &&
                !s.isNotFound,
          ),
        ]),
      );
      await bloc.close();
    });

    test('404 failure is flagged as isNotFound', () async {
      repo
        ..shouldThrow = true
        ..throwStatusCode = 404;
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceLogsState>(
            (s) => s.status == AttendanceLogsStatus.loading,
          ),
          predicate<AttendanceLogsState>(
            (s) => s.status == AttendanceLogsStatus.failure && s.isNotFound,
          ),
        ]),
      );
      await bloc.close();
    });

    test('summary failure still yields success state with null summary',
        () async {
      repo.throwSummaryOnly = true;
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceLogsState>(
            (s) => s.status == AttendanceLogsStatus.loading,
          ),
          predicate<AttendanceLogsState>(
            (s) =>
                s.status == AttendanceLogsStatus.success &&
                s.summary == null &&
                s.logs.length == 2,
          ),
        ]),
      );
      await bloc.close();
    });

    test('LoadMore appends next page logs', () async {
      repo.totalPages = 2;
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());
      await untilLogLoaded(bloc);

      bloc.add(const AttendanceLogsLoadMore());
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AttendanceLogsState>(
            (s) => s.logs.length == 4 && s.currentPage == 2,
          ),
        ),
      );
      expect(repo.lastRequestedPage, 2);
      await bloc.close();
    });

    test('LoadMore is ignored when no more pages', () async {
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());
      await untilLogLoaded(bloc);

      bloc.add(const AttendanceLogsLoadMore());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.logs.length, 2);
      expect(repo.lastRequestedPage, 1);
      await bloc.close();
    });

    test('FilterApplied refetches with mapped query params', () async {
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());
      await untilLogLoaded(bloc);

      bloc.add(
        AttendanceLogsFilterApplied(
          AttendanceLogFilterCriteria(
            startDate: DateTime(2026, 8, 1),
            type: AttendanceLogType.clockIn,
            punctuality: AttendanceLogPunctuality.late,
          ),
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AttendanceLogsState>(
            (s) =>
                s.status == AttendanceLogsStatus.success &&
                s.filterCriteria.hasActiveFilter,
          ),
        ),
      );
      expect(repo.lastStartDate, '2026-08-01');
      expect(repo.lastType, 'IN');
      expect(repo.lastStatus, 'late');
      await bloc.close();
    });

    test('AttendanceLogsStarted passes custom employeeId to repository', () async {
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted(employeeId: 'emp-custom-123'));
      await untilLogLoaded(bloc);

      expect(bloc.state.employeeId, 'emp-custom-123');
      expect(repo.lastEmployeeId, 'emp-custom-123');
      await bloc.close();
    });

    test('AttendanceLogsMonthToggled toggles lastMonth and refetches logs', () async {
      final bloc = AttendanceLogsBloc(repository: repo);
      bloc.add(const AttendanceLogsStarted());
      await untilLogLoaded(bloc);
      expect(bloc.state.lastMonth, isFalse);
      expect(repo.lastMonthParam, isFalse);

      bloc.add(const AttendanceLogsMonthToggled(true));
      await untilLogLoaded(bloc);

      expect(bloc.state.lastMonth, isTrue);
      expect(repo.lastMonthParam, isTrue);

      bloc.add(const AttendanceLogsMonthToggled(false));
      await untilLogLoaded(bloc);

      expect(bloc.state.lastMonth, isFalse);
      expect(repo.lastMonthParam, isFalse);
      await bloc.close();
    });
  });
}

Future<void> untilLogLoaded(AttendanceLogsBloc bloc) async {
  while (bloc.state.status != AttendanceLogsStatus.success) {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}
