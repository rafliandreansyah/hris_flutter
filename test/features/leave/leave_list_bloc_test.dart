import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_bloc.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_event.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_state.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_filter_bottom_sheet.dart';

/// Mock repository mengikuti pola test proyek (manual mock, tanpa mocktail).
class _MockLeaveRepository implements LeaveRepository {
  final Future<LeaveRequestListResponse> Function({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver,
  })? onGetLeaveRequests;

  /// Rekam panggilan untuk assertion parameter.
  int lastPage = 0;
  int lastSize = 0;
  bool lastApprover = false;
  String? lastSearch;
  String? lastStatusApprove;
  int callCount = 0;

  _MockLeaveRepository({this.onGetLeaveRequests});

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    lastPage = page;
    lastSize = size;
    lastApprover = approver;
    lastSearch = search;
    lastStatusApprove = statusApprove;
    callCount++;
    if (onGetLeaveRequests != null) {
      return onGetLeaveRequests!(
        page: page,
        size: size,
        companyId: companyId,
        departmentId: departmentId,
        positionId: positionId,
        search: search,
        statusApprove: statusApprove,
        startDate: startDate,
        endDate: endDate,
        approver: approver,
      );
    }
    return LeaveRequestListResponse(
      success: true,
      message: 'OK',
      data: const [],
      meta: const LeavePaginationMeta(
        page: 1,
        limit: 30,
        total: 0,
        totalPages: 1,
      ),
    );
  }
}

LeaveRequestItem _sampleItem(String id, {LeaveStatus? status}) {
  return LeaveRequestItem(
    id: id,
    name: 'Sarah Jenkins',
    role: 'Frontend Engineer',
    department: 'Engineering',
    initials: 'SJ',
    leaveType: 'Annual Leave',
    days: 3,
    note: 'Conference',
    status: status ?? LeaveStatus.pending,
  );
}

LeaveRequestListResponse _okResponse({
  List<LeaveRequestItem>? items,
  int page = 1,
  int totalPages = 1,
}) {
  final data = items ?? [_sampleItem('lv-1')];
  return LeaveRequestListResponse(
    success: true,
    message: 'OK',
    data: data,
    meta: LeavePaginationMeta(
      page: page,
      limit: 30,
      total: data.length,
      totalPages: totalPages,
    ),
  );
}

void main() {
  group('LeaveListBloc Unit Tests', () {
    test('initial state sesuai default', () {
      final bloc = LeaveListBloc(repository: _MockLeaveRepository());

      expect(bloc.state, const LeaveListState());
      expect(bloc.state.status, LeaveListStatus.initial);
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.searchQuery, isEmpty);
      expect(bloc.state.myRequests, isEmpty);
      expect(bloc.state.teamRequests, isEmpty);
      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.hasLoadedTeam, isFalse);
      expect(bloc.state.errorMessage, isNull);

      bloc.close();
    });

    test('LeaveListStarted memuat My Requests dengan approver=false', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('lv-1'), _sampleItem('lv-2')]),
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.lastApprover, isFalse);
      expect(mockRepo.lastSize, 30);
      expect(bloc.state.status, LeaveListStatus.success);
      expect(bloc.state.myRequests.length, 2);
      expect(bloc.state.isMyLoading, isFalse);

      bloc.close();
    });

    test('fetch Team Requests mengirim approver=true dan sukses', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('lv-team-1')]),
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListFetchRequested(isRefresh: true, isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.lastApprover, isTrue);
      expect(bloc.state.teamRequests.length, 1);
      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.status, LeaveListStatus.success);

      bloc.close();
    });

    test('HTTP 403 pada Team Requests men-set isTeamForbidden '
        'tanpa merusak My Requests', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          if (approver) {
            throw ApiException(
              message: 'Forbidden access to approver leave requests',
              statusCode: 403,
            );
          }
          return _okResponse(items: [_sampleItem('lv-mine-1')]);
        },
      );

      final bloc = LeaveListBloc(repository: mockRepo);

      // 1. Muat My Requests dulu.
      bloc.add(const LeaveListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.myRequests.length, 1);

      // 2. Fetch Team Requests -> 403.
      bloc.add(const LeaveListFetchRequested(isRefresh: true, isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isTeamForbidden, isTrue);
      expect(bloc.state.teamRequests, isEmpty);
      // Data tab My Requests TIDAK boleh rusak.
      expect(bloc.state.myRequests.length, 1);
      expect(bloc.state.myRequests.first.id, 'lv-mine-1');

      bloc.close();
    });

    test('error non-403 tidak men-set isTeamForbidden', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          if (approver) {
            throw ApiException(message: 'Server error', statusCode: 500);
          }
          return _okResponse();
        },
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListFetchRequested(isRefresh: true, isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.status, LeaveListStatus.failure);
      expect(bloc.state.errorMessage, isNotNull);

      bloc.close();
    });

    test('pindah tab ke index 1 lazy-load Team Requests sekali saja', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('lv-team-1')]),
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListTabChanged(1));
      await Future.delayed(const Duration(milliseconds: 50));
      bloc.add(const LeaveListTabChanged(1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.currentTabIndex, 1);
      expect(bloc.state.hasLoadedTeam, isTrue);
      // Lazy load hanya sekali untuk dua event tab-1 beruntun.
      expect(mockRepo.callCount, 1);

      bloc.close();
    });

    test('load more append data dan naikkan halaman (pagination)', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          if (page == 2) {
            return _okResponse(items: [_sampleItem('lv-3')], page: 2, totalPages: 2);
          }
          return _okResponse(
            items: [_sampleItem('lv-1'), _sampleItem('lv-2')],
            page: 1,
            totalPages: 2,
          );
        },
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.myRequests.length, 2);

      bloc.add(const LeaveListLoadMoreRequested(isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.lastPage, 2);
      expect(bloc.state.myRequests.length, 3);
      expect(bloc.state.myRequests.last.id, 'lv-3');
      expect(bloc.state.myCurrentPage, 2);
      expect(bloc.state.isMyLoadingMore, isFalse);

      bloc.close();
    });

    test('load more tidak jalan saat sudah halaman terakhir', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(page: 2, totalPages: 2),
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.myCurrentPage >= bloc.state.myTotalPages, isTrue);

      final callsBefore = mockRepo.callCount;
      bloc.add(const LeaveListLoadMoreRequested(isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.callCount, callsBefore); // tidak ada request baru

      bloc.close();
    });

    test('search mengubah query dan refetch dengan kata kunci', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('lv-found')]),
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListSearchChanged('sarah'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.searchQuery, 'sarah');
      expect(mockRepo.lastSearch, 'sarah');

      bloc.close();
    });

    test('filter applied menyimpan kriteria dan diteruskan ke API', () async {
      final mockRepo = _MockLeaveRepository(
        onGetLeaveRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? statusApprove,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(),
      );

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListFilterApplied(
        LeaveFilterCriteria(
          companyId: 'comp-1',
          statusApprove: 'approved',
        ),
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.companyId, 'comp-1');
      expect(bloc.state.filterCriteria.statusApprove, 'approved');
      expect(mockRepo.lastStatusApprove, 'approved');
      expect(bloc.state.status, LeaveListStatus.success);

      bloc.close();
    });

    test('filter reset mengembalikan kriteria default', () async {
      final mockRepo = _MockLeaveRepository();

      final bloc = LeaveListBloc(repository: mockRepo);
      bloc.add(const LeaveListFilterApplied(
        LeaveFilterCriteria(
          companyId: 'comp-1',
          statusApprove: 'approved',
        ),
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.filterCriteria.hasActiveFilter, isTrue);

      bloc.add(const LeaveListFilterReset());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.companyId, isNull);
      expect(bloc.state.filterCriteria.statusApprove, isNull);
      expect(bloc.state.filterCriteria.hasActiveFilter, isFalse);

      bloc.close();
    });

    test('defaultPageSize sesuai spesifikasi backend = 30', () {
      expect(LeaveListBloc.defaultPageSize, 30);
    });
  });

  group('LeaveStatusExtension', () {
    test('badge status selaras dengan desain aktivitas (palette sama)', () {
      // Pending -> Amber 100 / 700 / 500
      expect(LeaveStatus.pending.backgroundColor, const Color(0xFFFEF3C7));
      expect(LeaveStatus.pending.textColor, const Color(0xFFB45309));
      expect(LeaveStatus.pending.dotColor, const Color(0xFFF59E0B));

      // Approved -> Green 100 / 800 / 600
      expect(LeaveStatus.approved.backgroundColor, const Color(0xFFDCFCE7));
      expect(LeaveStatus.approved.textColor, const Color(0xFF166534));
      expect(LeaveStatus.approved.dotColor, const Color(0xFF16A34A));

      // Rejected -> Red 100 / 800 / 500
      expect(LeaveStatus.rejected.backgroundColor, const Color(0xFFFEE2E2));
      expect(LeaveStatus.rejected.textColor, const Color(0xFF991B1B));
      expect(LeaveStatus.rejected.dotColor, const Color(0xFFEF4444));

      // Requested = alias visual pending
      expect(LeaveStatus.requested.label, 'Pending');
      expect(
        LeaveStatus.requested.backgroundColor,
        LeaveStatus.pending.backgroundColor,
      );
    });
  });

  group('LeaveRequestListResponse.fromJson', () {
    test('mem-parse respons API lengkap dengan benar', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'lr-1',
            'employee': {
              'id': 'emp-1',
              'firstName': 'Sarah',
              'lastName': 'Jenkins',
              'employeeNumber': 'EMP-001',
              'company': {'id': 'c1', 'name': 'PT Oasish'},
              'department': {'id': 'd1', 'name': 'Engineering'},
              'position': {'id': 'p1', 'name': 'Frontend Engineer'},
              'photoUrl': 'https://example.com/p.jpg',
            },
            'leaveType': {'id': 'lt-1', 'name': 'Annual Leave'},
            'startDate': '2026-08-28T00:00:00.000Z',
            'endDate': '2026-08-30T00:00:00.000Z',
            'days': 3,
            'note': 'Conference',
            'statusApprove': 'pending',
          },
        ],
        'meta': {'page': 1, 'limit': 30, 'total': 1, 'totalPages': 1},
      };

      final response =
          LeaveRequestListResponse.fromJson(json, isApprover: true);

      expect(response.success, isTrue);
      expect(response.data.length, 1);

      final item = response.data.first;
      expect(item.id, 'lr-1');
      expect(item.name, 'Sarah Jenkins');
      expect(item.role, 'Frontend Engineer');
      expect(item.department, 'Engineering');
      expect(item.company, 'PT Oasish');
      expect(item.employeeNumber, 'EMP-001');
      expect(item.leaveType, 'Annual Leave');
      expect(item.days, 3);
      expect(item.durationLabel, '3 Days');
      expect(item.initials, 'SJ');
      expect(item.status, LeaveStatus.pending);
      expect(item.isSelf, isFalse); // isApprover=true -> Team Requests
      expect(response.meta.totalPages, 1);
    });

    test('statusApprove approved/rejected/requested ter-mapping benar', () {
      final approved = leaveRequestItemFromApiJson({
        'id': 'lr-2',
        'days': 1,
        'statusApprove': 'approved',
      });
      expect(approved.status, LeaveStatus.approved);

      final rejected = leaveRequestItemFromApiJson({
        'id': 'lr-3',
        'days': 1,
        'statusApprove': 'rejected',
      });
      expect(rejected.status, LeaveStatus.rejected);

      final requested = leaveRequestItemFromApiJson({
        'id': 'lr-4',
        'days': 1,
        'statusApprove': 'requested',
      });
      expect(requested.status, LeaveStatus.requested);
    });

    test('My Requests (isApprover=false) menandai isSelf=true', () {
      final item = leaveRequestItemFromApiJson(
        {'id': 'lr-5', 'days': 1, 'statusApprove': 'pending'},
        isApprover: false,
      );
      expect(item.isSelf, isTrue);
      expect(item.name, 'Saya'); // fallback tanpa data employee
    });

    test('durationLabel singular untuk 1 hari', () {
      final item = leaveRequestItemFromApiJson({
        'id': 'lr-6',
        'days': 1,
        'statusApprove': 'pending',
      });
      expect(item.durationLabel, '1 Day');
    });

    test('dateRangeLabel satu hari dan rentang', () {
      final single = leaveRequestItemFromApiJson({
        'id': 'lr-7',
        'days': 1,
        'startDate': '2026-08-27T00:00:00.000Z',
        'endDate': '2026-08-27T00:00:00.000Z',
        'statusApprove': 'pending',
      });
      expect(single.dateRangeLabel, '27 Agu 2026');

      final range = leaveRequestItemFromApiJson({
        'id': 'lr-8',
        'days': 3,
        'startDate': '2026-08-28T00:00:00.000Z',
        'endDate': '2026-08-30T00:00:00.000Z',
        'statusApprove': 'pending',
      });
      expect(range.dateRangeLabel, '28 Agu 2026 - 30 Agu 2026');
    });
  });

  group('LeaveFilterCriteria', () {
    test('hasActiveFilter false untuk kriteria default', () {
      const criteria = LeaveFilterCriteria();
      expect(criteria.hasActiveFilter, isFalse);
      expect(criteria.activeFilterCount, 0);
    });

    test('hasActiveFilter true saat ada filter terisi', () {
      final criteria = LeaveFilterCriteria(
        companyId: 'c1',
        company: 'PT Oasish',
        statusApprove: 'approved',
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 31),
        ),
      );
      expect(criteria.hasActiveFilter, isTrue);
      expect(criteria.activeFilterCount, 3);
      expect(criteria.startDateParam, '2026-08-01');
      expect(criteria.endDateParam, '2026-08-31');
    });
  });
}
