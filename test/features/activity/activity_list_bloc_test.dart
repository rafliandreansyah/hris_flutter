import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_list/activity_list_state.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';
import 'package:image_picker/image_picker.dart';

class _MockActivityRepository implements ActivityRepository {
  final Future<ActivityListResponse> Function({
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
  })? onGetActivities;

  _MockActivityRepository({this.onGetActivities});

  @override
  Future<ActivityListResponse> getActivities({
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
    if (onGetActivities != null) {
      return onGetActivities!(
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
    return const ActivityListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: ActivityPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
    );
  }

  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) async {
    return ActivityDetailResponse(
      success: true,
      message: 'OK',
      data: {'id': id},
    );
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'Finished');
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'Canceled');
  }

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    return const ActivityTypesResponse(
      success: true,
      message: 'OK',
      data: [],
    );
  }

  @override
  Future<CreateActivityResponse> createActivity({
    required String activityTypeId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String locationAddress,
    required String description,
    String status = 'ongoing',
    XFile? file,
  }) async {
    return const CreateActivityResponse(
      success: true,
      message: 'OK',
      data: {},
    );
  }
}

void main() {
  group('ActivityListBloc Unit Tests', () {
    test('Initial state is correctly configured', () {
      final bloc = ActivityListBloc(repository: _MockActivityRepository());
      expect(bloc.state.status, ActivityListStatus.initial);
      expect(bloc.state.currentTabIndex, 0);
      expect(bloc.state.myActivities, isEmpty);
      expect(bloc.state.teamActivities, isEmpty);
      expect(bloc.state.filterCriteria.status, 'ongoing');
      bloc.close();
    });

    test('ActivityListStarted with customActivities loads and filters immediately', () async {
      final sample = [
        ActivityItem(
          id: '1',
          title: 'My Task',
          description: 'Desc',
          userName: 'Sarah',
          userRole: 'Developer',
          department: 'Engineering',
          company: 'Oasish',
          initials: 'S',
          status: ActivityStatus.ongoing,
          location: 'Office',
          time: '09:00',
          date: DateTime.now(),
          isMyActivity: true,
        ),
        ActivityItem(
          id: '2',
          title: 'Team Task',
          description: 'Desc',
          userName: 'Budi',
          userRole: 'Designer',
          department: 'Product',
          company: 'Oasish',
          initials: 'B',
          status: ActivityStatus.ongoing,
          location: 'Office',
          time: '10:00',
          date: DateTime.now(),
          isMyActivity: false,
        ),
      ];

      final bloc = ActivityListBloc(repository: _MockActivityRepository());
      bloc.add(ActivityListStarted(customActivities: sample));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, ActivityListStatus.success);
      expect(bloc.state.myActivities.length, 1);
      expect(bloc.state.myActivities.first.id, '1');
      expect(bloc.state.teamActivities.length, 2);
      bloc.close();
    });

    test('ActivityListFetchRequested loads data for Tab 0 (approver: false)', () async {
      final mockRepo = _MockActivityRepository(
        onGetActivities: ({
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
          expect(approver, isFalse);
          return ActivityListResponse(
            success: true,
            message: 'OK',
            data: [
              ActivityItem(
                id: 'A-1',
                title: 'Code Review',
                description: 'Desc',
                userName: 'Sarah',
                userRole: 'Engineer',
                department: 'Tech',
                company: 'Oasish',
                initials: 'SJ',
                status: ActivityStatus.ongoing,
                location: 'HQ',
                time: '08:00',
                date: DateTime.now(),
                isMyActivity: true,
              ),
            ],
            meta: const ActivityPaginationMeta(page: 1, limit: 20, total: 1, totalPages: 1),
          );
        },
      );

      final bloc = ActivityListBloc(repository: mockRepo);
      bloc.add(const ActivityListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, ActivityListStatus.success);
      expect(bloc.state.myActivities.length, 1);
      expect(bloc.state.myActivities.first.id, 'A-1');
      bloc.close();
    });

    test('ActivityListFetchRequested handles 403 Forbidden on Tab 1', () async {
      final mockRepo = _MockActivityRepository(
        onGetActivities: ({
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
              message: 'Forbidden access to approver activities',
              statusCode: 403,
            );
          }
          return const ActivityListResponse(
            success: true,
            message: 'OK',
            data: [],
            meta: ActivityPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
          );
        },
      );

      final bloc = ActivityListBloc(repository: mockRepo);
      bloc.add(const ActivityListFetchRequested(isRefresh: true, isTeam: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isTeamForbidden, isTrue);
      expect(bloc.state.teamActivities, isEmpty);
      bloc.close();
    });

    test('ActivityListLoadMoreRequested increments page and appends data', () async {
      int pageCount = 1;
      final mockRepo = _MockActivityRepository(
        onGetActivities: ({
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
          pageCount = page;
          return ActivityListResponse(
            success: true,
            message: 'OK',
            data: [
              ActivityItem(
                id: 'PAGE-$page',
                title: 'Task $page',
                description: 'Desc',
                userName: 'Sarah',
                userRole: 'Dev',
                department: 'Eng',
                company: 'Oasish',
                initials: 'S',
                status: ActivityStatus.ongoing,
                location: 'HQ',
                time: '10:00',
                date: DateTime.now(),
                isMyActivity: true,
              ),
            ],
            meta: ActivityPaginationMeta(page: page, limit: 20, total: 2, totalPages: 2),
          );
        },
      );

      final bloc = ActivityListBloc(repository: mockRepo);
      bloc.add(const ActivityListFetchRequested(isRefresh: true, isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.myActivities.length, 1);
      expect(bloc.state.myCurrentPage, 1);

      bloc.add(const ActivityListLoadMoreRequested(isTeam: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(pageCount, 2);
      expect(bloc.state.myActivities.length, 2);
      expect(bloc.state.myActivities.last.id, 'PAGE-2');
      bloc.close();
    });

    test('ActivityListFilterApplied updates criteria and resets pagination', () async {
      final bloc = ActivityListBloc(repository: _MockActivityRepository());
      const newCriteria = ActivityFilterCriteria(status: 'completed');

      bloc.add(const ActivityListFilterApplied(newCriteria));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.status, 'completed');
      bloc.close();
    });

    test('ActivityListFilterApplied with all or null status loads all statuses with status=all', () async {
      String? capturedStatus = 'initial';
      final mockRepo = _MockActivityRepository(
        onGetActivities: ({
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
          capturedStatus = status;
          return const ActivityListResponse(
            success: true,
            message: 'OK',
            data: [],
            meta: ActivityPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
          );
        },
      );

      final bloc = ActivityListBloc(repository: mockRepo);
      const allStatusCriteria = ActivityFilterCriteria(status: 'all');
      bloc.add(const ActivityListFilterApplied(allStatusCriteria));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.filterCriteria.status, 'all');
      expect(capturedStatus, 'all');
      bloc.close();
    });

    test('ActivityListFilterApplied with dateRange forwards startDate and endDate formatted as yyyy-MM-dd', () async {
      String? capturedStart;
      String? capturedEnd;

      final mockRepo = _MockActivityRepository(
        onGetActivities: ({
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
          capturedStart = startDate;
          capturedEnd = endDate;
          return const ActivityListResponse(
            success: true,
            message: 'OK',
            data: [],
            meta: ActivityPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
          );
        },
      );

      final bloc = ActivityListBloc(repository: mockRepo);
      final dateRangeCriteria = ActivityFilterCriteria(
        dateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 10),
        ),
      );

      bloc.add(ActivityListFilterApplied(dateRangeCriteria));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(capturedStart, '2026-09-01');
      expect(capturedEnd, '2026-09-10');
      bloc.close();
    });

    test('ActivityListActivityAdded prepends activity to both lists', () async {
      final bloc = ActivityListBloc(repository: _MockActivityRepository());
      final newAct = ActivityItem(
        id: 'NEW-1',
        title: 'New Activity',
        description: 'Desc',
        userName: 'Sarah',
        userRole: 'Dev',
        department: 'Eng',
        company: 'Oasish',
        initials: 'S',
        status: ActivityStatus.ongoing,
        location: 'HQ',
        time: '10:00',
        date: DateTime.now(),
        isMyActivity: true,
      );

      bloc.add(ActivityListActivityAdded(newAct));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.myActivities.first.id, 'NEW-1');
      expect(bloc.state.teamActivities.first.id, 'NEW-1');
      bloc.close();
    });
  });
}
