import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_list/attendance_request_list_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_filter_bottom_sheet.dart';

class _MockAttendanceRequestRepository implements AttendanceRequestRepository {
  final Future<AttendanceRequestListResponse> Function({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    bool approver,
  })? onGetAttendanceRequests;

  int lastPage = 0;
  int lastSize = 0;
  bool lastApprover = false;
  String? lastSearch;
  String? lastStatus;
  int callCount = 0;
  final List<bool> approverCalls = [];

  _MockAttendanceRequestRepository({this.onGetAttendanceRequests});

  @override
  Future<AttendanceRequestListResponse> getAttendanceRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    lastPage = page;
    lastSize = size;
    lastApprover = approver;
    lastSearch = search;
    lastStatus = status;
    callCount++;
    approverCalls.add(approver);

    if (onGetAttendanceRequests != null) {
      return onGetAttendanceRequests!(
        page: page,
        size: size,
        companyId: companyId,
        departmentId: departmentId,
        positionId: positionId,
        search: search,
        status: status,
        startDate: startDate,
        endDate: endDate,
        approver: approver,
      );
    }

    return const AttendanceRequestListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: AttendanceRequestPaginationMeta(
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceRequestDetailData> getAttendanceRequestDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> approveAttendanceRequest({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAttendanceRequest(String id) async {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyItem = AttendanceRequestItem(
    id: 'req-1',
    employeeId: 'emp-1',
    name: 'Budi Santoso',
    role: 'Senior Backend Engineer',
    department: 'Engineering',
    company: 'Muratech',
    date: DateTime(2026, 8, 29),
    startTime: '08:30',
    endTime: '17:00',
    notes: 'Presentasi implementasi integrasi payment gateway ke klien.',
    status: AttendanceRequestStatus.requested,
    createdAt: DateTime(2026, 8, 29, 13, 35),
    isSelf: true,
  );

  group('AttendanceRequestListBloc Unit Tests', () {
    test('initial state sesuai default', () {
      final bloc = AttendanceRequestListBloc(
        repository: _MockAttendanceRequestRepository(),
      );
      expect(bloc.state.status, AttendanceRequestListStatus.initial);
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.myRequests, isEmpty);
      expect(bloc.state.teamRequests, isEmpty);
      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.filterCriteria.status, 'requested');
    });

    test('AttendanceRequestListStarted memuat My Requests dan Team Requests',
        () async {
      final repo = _MockAttendanceRequestRepository(
        onGetAttendanceRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? status,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          return AttendanceRequestListResponse(
            success: true,
            message: 'OK',
            data: [dummyItem],
            meta: const AttendanceRequestPaginationMeta(
              page: 1,
              limit: 20,
              total: 1,
              totalPages: 1,
            ),
          );
        },
      );

      final bloc = AttendanceRequestListBloc(repository: repo);
      bloc.add(const AttendanceRequestListStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceRequestListState>((s) =>
              s.status == AttendanceRequestListStatus.loading &&
              s.isMyLoading &&
              s.isTeamLoading),
          predicate<AttendanceRequestListState>((s) =>
              s.status == AttendanceRequestListStatus.success &&
              !s.isMyLoading &&
              s.myRequests.length == 1),
          predicate<AttendanceRequestListState>((s) =>
              !s.isTeamLoading &&
              s.teamRequests.length == 1 &&
              s.hasLoadedTeam),
        ]),
      );

      expect(repo.approverCalls, containsAllInOrder([false, true]));
    });

    test('HTTP 403 pada Team Requests men-set isTeamForbidden tanpa merusak My Requests',
        () async {
      final repo = _MockAttendanceRequestRepository(
        onGetAttendanceRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? status,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          if (approver) {
            throw ApiException(
              message: 'Tidak memiliki hak akses approver',
              statusCode: 403,
            );
          }
          return AttendanceRequestListResponse(
            success: true,
            message: 'OK',
            data: [dummyItem],
            meta: const AttendanceRequestPaginationMeta(
              page: 1,
              limit: 20,
              total: 1,
              totalPages: 1,
            ),
          );
        },
      );

      final bloc = AttendanceRequestListBloc(repository: repo);
      bloc.add(const AttendanceRequestListStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceRequestListState>((s) => s.isMyLoading),
          predicate<AttendanceRequestListState>((s) =>
              !s.isMyLoading && s.myRequests.length == 1),
          predicate<AttendanceRequestListState>((s) =>
              !s.isTeamLoading &&
              s.isTeamForbidden &&
              s.teamRequests.isEmpty),
        ]),
      );

      expect(bloc.state.myRequests.length, 1);
      expect(bloc.state.isTeamForbidden, isTrue);
    });

    test('error non-403 tidak men-set isTeamForbidden', () async {
      final repo = _MockAttendanceRequestRepository(
        onGetAttendanceRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? status,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          if (approver) {
            throw ApiException(
              message: 'Internal Server Error',
              statusCode: 500,
            );
          }
          return const AttendanceRequestListResponse(
            success: true,
            message: 'OK',
            data: [],
            meta: AttendanceRequestPaginationMeta(
              page: 1,
              limit: 20,
              total: 0,
              totalPages: 1,
            ),
          );
        },
      );

      final bloc = AttendanceRequestListBloc(repository: repo);
      bloc.add(const AttendanceRequestListStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceRequestListState>((s) => s.isMyLoading),
          predicate<AttendanceRequestListState>((s) => !s.isMyLoading),
          predicate<AttendanceRequestListState>((s) =>
              !s.isTeamLoading &&
              !s.isTeamForbidden &&
              s.errorMessage == 'Internal Server Error'),
        ]),
      );
    });

    test('pencarian SearchChanged memicu refetch dengan search query', () async {
      final repo = _MockAttendanceRequestRepository();
      final bloc = AttendanceRequestListBloc(repository: repo);

      bloc.add(const AttendanceRequestListSearchChanged('Budi'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceRequestListState>((s) => s.searchQuery == 'Budi'),
          predicate<AttendanceRequestListState>((s) =>
              s.searchQuery == 'Budi' && s.isTeamLoading),
          predicate<AttendanceRequestListState>((s) => !s.isTeamLoading),
        ]),
      );

      expect(repo.lastSearch, 'Budi');
      expect(repo.lastApprover, isTrue);
    });

    test('filter applied & reset memicu refetch kedua tab', () async {
      final repo = _MockAttendanceRequestRepository();
      final bloc = AttendanceRequestListBloc(repository: repo);

      final newCriteria = AttendanceRequestFilterCriteria(
        status: 'approved',
        companyId: 'comp-1',
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 31),
        ),
      );

      bloc.add(AttendanceRequestListFilterApplied(newCriteria));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceRequestListState>((s) =>
              s.filterCriteria.status == 'approved' &&
              s.filterCriteria.companyId == 'comp-1'),
          predicate<AttendanceRequestListState>((s) => s.isMyLoading),
          predicate<AttendanceRequestListState>((s) => !s.isMyLoading),
          predicate<AttendanceRequestListState>((s) => s.isTeamLoading),
          predicate<AttendanceRequestListState>((s) => !s.isTeamLoading),
        ]),
      );

      expect(repo.lastStatus, 'approved');
      expect(repo.lastApprover, isTrue);

      bloc.add(const AttendanceRequestListFilterReset());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceRequestListState>((s) =>
              s.filterCriteria.status == 'requested' &&
              s.filterCriteria.companyId == null),
          predicate<AttendanceRequestListState>((s) => s.isMyLoading),
          predicate<AttendanceRequestListState>((s) => !s.isMyLoading),
          predicate<AttendanceRequestListState>((s) => s.isTeamLoading),
          predicate<AttendanceRequestListState>((s) => !s.isTeamLoading),
        ]),
      );
    });

    test('LoadMoreRequested menambahkan data dan menaikkan nomor halaman', () async {
      final repo = _MockAttendanceRequestRepository(
        onGetAttendanceRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? status,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          return AttendanceRequestListResponse(
            success: true,
            message: 'OK',
            data: [dummyItem],
            meta: AttendanceRequestPaginationMeta(
              page: page,
              limit: 20,
              total: 2,
              totalPages: 2,
            ),
          );
        },
      );

      final bloc = AttendanceRequestListBloc(repository: repo);
      bloc.add(const AttendanceRequestListStarted());

      // Tunggu hingga tab my selesai dimuat
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AttendanceRequestListState>((s) =>
              !s.isMyLoading && s.myRequests.length == 1),
        ),
      );

      bloc.add(const AttendanceRequestListLoadMoreRequested(isTeam: false));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AttendanceRequestListState>((s) => s.isMyLoadingMore),
          predicate<AttendanceRequestListState>((s) =>
              !s.isMyLoadingMore &&
              s.myRequests.length == 2 &&
              s.myCurrentPage == 2),
        ]),
      );
    });
  });

  group('AttendanceRequest Models & Parsing Tests', () {
    test('AttendanceRequestListResponse.fromJson mem-parse payload lengkap dengan benar', () {
      final json = {
        'success': true,
        'message': 'Success',
        'data': [
          {
            'id': 'req-10',
            'employee': {
              'id': 'emp-10',
              'firstName': 'Dimas',
              'lastName': 'Anggara',
              'position': {'id': 'pos-1', 'name': 'Field Operations Supervisor'},
              'department': {'id': 'dep-1', 'name': 'Operations'},
              'company': {'id': 'com-1', 'name': 'Muratech'},
            },
            'date': '2026-08-28T00:00:00.000Z',
            'startTime': '09:00',
            'endTime': '18:00',
            'notes': 'Site visit dan inspeksi gudang logistik cabang Cikarang.',
            'status': 'approved',
            'createdAt': '2026-08-27T09:15:00.000Z',
          }
        ],
        'meta': {
          'page': 1,
          'limit': 20,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = AttendanceRequestListResponse.fromJson(json, isApprover: true);
      expect(response.success, isTrue);
      expect(response.data.length, 1);

      final item = response.data.first;
      expect(item.id, 'req-10');
      expect(item.name, 'Dimas Anggara');
      expect(item.role, 'Field Operations Supervisor');
      expect(item.status, AttendanceRequestStatus.approved);
      expect(item.status.label, 'Disetujui');
      expect(item.formattedDate, contains('2026'));
      expect(item.formattedWorkHours, contains('09:00'));
      expect(item.formattedWorkHours, contains('18:00'));
      expect(item.notes, contains('Site visit'));
      expect(item.isSelf, isFalse);
    });

    test('AttendanceRequestStatusExtension badge colors and dot colors', () {
      expect(AttendanceRequestStatus.requested.label, 'Menunggu');
      expect(AttendanceRequestStatus.approved.label, 'Disetujui');
      expect(AttendanceRequestStatus.rejected.label, 'Ditolak');

      expect(AttendanceRequestStatus.requested.textColor, const Color(0xFFB45309));
      expect(AttendanceRequestStatus.approved.textColor, const Color(0xFF047857));
      expect(AttendanceRequestStatus.rejected.textColor, const Color(0xFFB91C1C));
    });

    test('AttendanceRequestFilterCriteria hasActiveFilter and date params', () {
      const defaultCriteria = AttendanceRequestFilterCriteria();
      expect(defaultCriteria.hasActiveFilter, isFalse);
      expect(defaultCriteria.activeFilterCount, 0);

      final activeCriteria = defaultCriteria.copyWith(
        status: 'approved',
        companyId: 'comp-1',
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 15),
        ),
      );

      expect(activeCriteria.hasActiveFilter, isTrue);
      expect(activeCriteria.activeFilterCount, 3);
      expect(activeCriteria.startDateParam, '2026-08-01');
      expect(activeCriteria.endDateParam, '2026-08-15');
    });
  });
}
