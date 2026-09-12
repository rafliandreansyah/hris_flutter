import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_list/overtime_list_bloc.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_list/overtime_list_event.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_list/overtime_list_state.dart';
import 'package:hris_flutter/features/overtime/presentation/models/overtime_request_item.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:image_picker/image_picker.dart';

/// Mock repository mengikuti pola test proyek (manual mock, tanpa mocktail).
class _MockOvertimeRepository implements OvertimeRepository {
  final Future<OvertimeRequestListResponse> Function({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver,
  })? onGetOvertimeRequests;

  int lastPage = 0;
  int lastSize = 0;
  bool lastApprover = false;
  String? lastSearch;
  String? lastStartDate;
  String? lastStatus;
  int callCount = 0;
  final List<bool> approverCalls = [];

  _MockOvertimeRepository({this.onGetOvertimeRequests});

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
    String? statusApprove,
  }) async {
    lastPage = page;
    lastSize = size;
    lastApprover = approver;
    lastSearch = search;
    lastStartDate = startDate;
    lastStatus = status ?? statusApprove;
    callCount++;
    approverCalls.add(approver);
    if (onGetOvertimeRequests != null) {
      return onGetOvertimeRequests!(
        page: page,
        size: size,
        companyId: companyId,
        departmentId: departmentId,
        positionId: positionId,
        search: search,
        startDate: startDate,
        endDate: endDate,
        approver: approver,
      );
    }
    return OvertimeRequestListResponse(
      success: true,
      message: 'OK',
      data: const [],
      meta: const OvertimePaginationMeta(
        page: 1,
        limit: 30,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  }) async {
    return const OvertimeScheduleData();
  }

  @override
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  }) async {
    return const CreateOvertimeResultModel(success: true, message: 'OK');
  }

  @override
  Future<OvertimeDetailData> getOvertimeDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOvertime(String id) async {
    throw UnimplementedError();
  }
}

OvertimeRequestItem _sampleItem(String id, {OvertimeStatus? status}) {
  return OvertimeRequestItem(
    id: id,
    name: 'Sarah Jenkins',
    role: 'Frontend Engineer',
    department: 'Engineering',
    initials: 'SJ',
    note: 'Cutover assistance',
    status: status ?? OvertimeStatus.pending,
  );
}

OvertimeRequestListResponse _okResponse({
  List<OvertimeRequestItem>? items,
  int page = 1,
  int totalPages = 1,
}) {
  final data = items ?? [_sampleItem('ot-1')];
  return OvertimeRequestListResponse(
    success: true,
    message: 'OK',
    data: data,
    meta: OvertimePaginationMeta(
      page: page,
      limit: 30,
      total: data.length,
      totalPages: totalPages,
    ),
  );
}

void main() {
  group('OvertimeListBloc Unit Tests', () {
    test('initial state sesuai default', () {
      final bloc = OvertimeListBloc(repository: _MockOvertimeRepository());

      expect(bloc.state, const OvertimeListState());
      expect(bloc.state.status, OvertimeListStatus.initial);
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.searchQuery, isEmpty);
      expect(bloc.state.myRequests, isEmpty);
      expect(bloc.state.teamRequests, isEmpty);
      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.hasLoadedTeam, isFalse);
      expect(bloc.state.errorMessage, isNull);

      bloc.close();
    });

    test('OvertimeListStarted memuat My Overtime dan Team Overtime secara bersamaan',
        () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('ot-1'), _sampleItem('ot-2')]),
      );

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.approverCalls, [false, true]);
      expect(mockRepo.callCount, 2);
      expect(mockRepo.lastSize, 30);
      expect(bloc.state.status, OvertimeListStatus.success);
      expect(bloc.state.hasLoadedTeam, isTrue);
      expect(bloc.state.myRequests.length, 2);
      expect(bloc.state.isMyLoading, isFalse);

      bloc.close();
    });

    test('fetch Team Overtime mengirim approver=true dan sukses', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('ot-team-1')]),
      );

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.lastApprover, isTrue);
      expect(bloc.state.teamRequests.length, 1);
      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.status, OvertimeListStatus.success);

      bloc.close();
    });

    test('HTTP 403 pada Team Overtime men-set isTeamForbidden '
        'tanpa merusak My Overtime', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          if (approver) {
            throw ApiException(
              message: 'Forbidden access to approver overtime requests',
              statusCode: 403,
            );
          }
          return _okResponse(items: [_sampleItem('ot-mine-1')]);
        },
      );

      final bloc = OvertimeListBloc(repository: mockRepo);

      // 1. Muat My Overtime dulu.
      bloc.add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.myRequests.length, 1);

      // 2. Fetch Team Overtime -> 403.
      bloc.add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isTeamForbidden, isTrue);
      expect(bloc.state.teamRequests, isEmpty);
      // Data tab My Overtime TIDAK boleh rusak.
      expect(bloc.state.myRequests.length, 1);
      expect(bloc.state.myRequests.first.id, 'ot-mine-1');

      bloc.close();
    });

    test('error non-403 tidak men-set isTeamForbidden', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
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

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListFetchRequested(isRefresh: true, isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isTeamForbidden, isFalse);
      expect(bloc.state.status, OvertimeListStatus.failure);
      expect(bloc.state.errorMessage, isNotNull);

      bloc.close();
    });

    test('pindah tab tidak memicu network call ulang karena kedua tab sudah dimuat saat start',
        () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('ot-team-1')]),
      );

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListStarted());
      await Future.delayed(const Duration(milliseconds: 50));
      final callsAfterStart = mockRepo.callCount;
      expect(callsAfterStart, 2);

      bloc.add(const OvertimeListTabChanged(1));
      await Future.delayed(const Duration(milliseconds: 50));
      bloc.add(const OvertimeListTabChanged(1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.currentTabIndex, 1);
      expect(bloc.state.hasLoadedTeam, isTrue);
      // Pindah tab tidak menambah network call karena sudah dimuat bersamaan saat start.
      expect(mockRepo.callCount, callsAfterStart);

      bloc.close();
    });

    test('load more append data dan naikkan halaman (pagination)', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async {
          if (page == 2) {
            return _okResponse(
              items: [_sampleItem('ot-3')],
              page: 2,
              totalPages: 2,
            );
          }
          return _okResponse(
            items: [_sampleItem('ot-1'), _sampleItem('ot-2')],
            page: 1,
            totalPages: 2,
          );
        },
      );

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.myRequests.length, 2);

      bloc.add(const OvertimeListLoadMoreRequested(isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.lastPage, 2);
      expect(bloc.state.myRequests.length, 3);
      expect(bloc.state.myRequests.last.id, 'ot-3');
      expect(bloc.state.myCurrentPage, 2);
      expect(bloc.state.isMyLoadingMore, isFalse);

      bloc.close();
    });

    test('load more tidak jalan saat sudah halaman terakhir', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(page: 2, totalPages: 2),
      );

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.myCurrentPage >= bloc.state.myTotalPages, isTrue);

      final callsBefore = mockRepo.callCount;
      bloc.add(const OvertimeListLoadMoreRequested(isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.callCount, callsBefore); // tidak ada request baru

      bloc.close();
    });

    test('search mengubah query dan refetch dengan kata kunci', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(items: [_sampleItem('ot-found')]),
      );

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListSearchChanged('sarah'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.searchQuery, 'sarah');
      expect(mockRepo.lastSearch, 'sarah');

      bloc.close();
    });

    test('filter applied menyimpan kriteria dan diteruskan ke API', () async {
      final mockRepo = _MockOvertimeRepository(
        onGetOvertimeRequests: ({
          required int page,
          required int size,
          String? companyId,
          String? departmentId,
          String? positionId,
          String? search,
          String? startDate,
          String? endDate,
          bool approver = false,
        }) async =>
            _okResponse(),
      );

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(
        OvertimeListFilterApplied(
          OvertimeFilterCriteria(
            companyId: 'comp-1',
            dateRange: DateTimeRange(
              start: DateTime(2026, 8, 28),
              end: DateTime(2026, 8, 30),
            ),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.companyId, 'comp-1');
      expect(mockRepo.lastStartDate, '2026-08-28');
      expect(bloc.state.status, OvertimeListStatus.success);

      bloc.close();
    });

    test('filter status pengajuan diteruskan sebagai query param status',
        () async {
      final mockRepo = _MockOvertimeRepository();

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(
        const OvertimeListFilterApplied(
          OvertimeFilterCriteria(statusApprove: 'requested'),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockRepo.lastStatus, 'requested');
      expect(bloc.state.filterCriteria.statusApprove, 'requested');

      // Reset menghapus status filter.
      bloc.add(const OvertimeListFilterReset());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.filterCriteria.statusApprove, isNull);
      expect(mockRepo.lastStatus, 'all');

      bloc.close();
    });

    test('filter reset mengembalikan kriteria default', () async {
      final mockRepo = _MockOvertimeRepository();

      final bloc = OvertimeListBloc(repository: mockRepo);
      bloc.add(const OvertimeListFilterApplied(
        OvertimeFilterCriteria(companyId: 'comp-1'),
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.filterCriteria.hasActiveFilter, isTrue);

      bloc.add(const OvertimeListFilterReset());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.companyId, isNull);
      expect(bloc.state.filterCriteria.hasActiveFilter, isFalse);

      bloc.close();
    });

    test('defaultPageSize sesuai spesifikasi backend = 30', () {
      expect(OvertimeListBloc.defaultPageSize, 30);
    });
  });

  group('OvertimeStatusExtension', () {
    test('badge status selaras dengan desain aktivitas (palette sama)', () {
      // Pending -> Amber 100 / 700 / 500
      expect(OvertimeStatus.pending.backgroundColor, const Color(0xFFFEF3C7));
      expect(OvertimeStatus.pending.textColor, const Color(0xFFB45309));
      expect(OvertimeStatus.pending.dotColor, const Color(0xFFF59E0B));

      // Approved -> Green 100 / 800 / 600
      expect(OvertimeStatus.approved.backgroundColor, const Color(0xFFDCFCE7));
      expect(OvertimeStatus.approved.textColor, const Color(0xFF166534));
      expect(OvertimeStatus.approved.dotColor, const Color(0xFF16A34A));

      // Rejected -> Red 100 / 800 / 500
      expect(OvertimeStatus.rejected.backgroundColor, const Color(0xFFFEE2E2));
      expect(OvertimeStatus.rejected.textColor, const Color(0xFF991B1B));
      expect(OvertimeStatus.rejected.dotColor, const Color(0xFFEF4444));

      // Requested = alias visual pending
      expect(OvertimeStatus.requested.label, 'Pending');
      expect(
        OvertimeStatus.requested.backgroundColor,
        OvertimeStatus.pending.backgroundColor,
      );
    });
  });

  group('OvertimeRequestListResponse.fromJson', () {
    test('mem-parse respons API lengkap dengan benar', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'ot-1',
            'startOvertime': '2026-08-28T10:00:00.000Z',
            'endOvertime': '2026-08-28T14:00:00.000Z',
            'notes': 'Database replication verification',
            'approverNotes': null,
            'timezone': 'WIB',
            'status': 'requested',
            'employee': {
              'id': 'emp-1',
              'firstName': 'Sarah',
              'lastName': 'Jenkins',
              'employeeNumber': 'EMP-2024-019',
              'company': {'id': 'c1', 'name': 'Oasish Tech'},
              'department': {'id': 'd1', 'name': 'Engineering'},
              'position': {'id': 'p1', 'name': 'Frontend Engineer'},
              'photoUrl': null,
            },
          },
        ],
        'meta': {'page': 1, 'limit': 30, 'total': 1, 'totalPages': 1},
      };

      final response = OvertimeRequestListResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.data.length, 1);

      final item = response.data.first;
      expect(item.id, 'ot-1');
      expect(item.name, 'Sarah Jenkins');
      expect(item.role, 'Frontend Engineer');
      expect(item.department, 'Engineering');
      expect(item.company, 'Oasish Tech');
      expect(item.employeeNumber, 'EMP-2024-019');
      expect(item.note, 'Database replication verification');
      expect(item.initials, 'SJ');
      expect(item.status, OvertimeStatus.requested);
      expect(item.isSelf, isTrue); // isApprover default false -> My Overtime
      expect(response.meta.totalPages, 1);
    });

    test('status requested/approved/rejected ter-mapping benar', () {
      final requested = overtimeRequestItemFromApiJson({
        'id': 'ot-2',
        'status': 'requested',
      });
      expect(requested.status, OvertimeStatus.requested);

      final approved = overtimeRequestItemFromApiJson({
        'id': 'ot-3',
        'status': 'approved',
      });
      expect(approved.status, OvertimeStatus.approved);

      final rejected = overtimeRequestItemFromApiJson({
        'id': 'ot-4',
        'status': 'rejected',
      });
      expect(rejected.status, OvertimeStatus.rejected);
    });

    test('Team Overtime (isApprover=true) menandai isSelf=false', () {
      final item = overtimeRequestItemFromApiJson(
        {
          'id': 'ot-5',
          'status': 'requested',
          'employee': {'id': 'emp-2', 'firstName': 'Marcus'},
        },
        isApprover: true,
      );
      expect(item.isSelf, isFalse);
      expect(item.name, 'Marcus');
    });

    test('durasi dan label jadwal dihitung dari start/end overtime', () {
      final item = overtimeRequestItemFromApiJson({
        'id': 'ot-6',
        'startOvertime': '2026-08-28T17:00:00.000Z',
        'endOvertime': '2026-08-28T21:00:00.000Z',
        'status': 'requested',
      });
      expect(item.durationHours, 4);
      expect(item.durationLabel, '4 Jam Kerja');
      expect(item.timeRangeLabel, isNot('-'));
      expect(item.dateLabel, contains('2026'));
    });
  });

  group('OvertimeFilterCriteria', () {
    test('hasActiveFilter false untuk kriteria default', () {
      const criteria = OvertimeFilterCriteria();
      expect(criteria.hasActiveFilter, isFalse);
      expect(criteria.activeFilterCount, 0);
    });

    test('hasActiveFilter true saat ada filter terisi', () {
      final criteria = OvertimeFilterCriteria(
        companyId: 'c1',
        company: 'Oasish Tech',
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 31),
        ),
      );
      expect(criteria.hasActiveFilter, isTrue);
      expect(criteria.activeFilterCount, 2);
      expect(criteria.startDateParam, '2026-08-01');
      expect(criteria.endDateParam, '2026-08-31');
    });

    test('statusApprove dihitung sebagai filter aktif kecuali all', () {
      expect(
        const OvertimeFilterCriteria(statusApprove: 'requested')
            .hasActiveFilter,
        isTrue,
      );
      expect(
        const OvertimeFilterCriteria(statusApprove: 'rejected')
            .activeFilterCount,
        1,
      );
      expect(const OvertimeFilterCriteria(statusApprove: 'all').hasActiveFilter,
          isFalse);
      expect(
        const OvertimeFilterCriteria(statusApprove: null).activeFilterCount,
        0,
      );
    });
  });
}
