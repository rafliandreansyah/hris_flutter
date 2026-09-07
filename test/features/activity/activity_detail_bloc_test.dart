import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_state.dart';
import 'package:image_picker/image_picker.dart';

class _MockDetailRepo implements ActivityRepository {
  bool finishCalled = false;
  bool cancelCalled = false;

  @override
  Future<ActivityListResponse> getActivities({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    bool approver = false,
  }) async {
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
      data: {
        'id': id,
        'employeeId': 'emp-001',
        'status': finishCalled ? 'completed' : (cancelCalled ? 'canceled' : 'ongoing'),
        'description': 'Kegiatan pengawasan proyek',
        'startTime': '2026-09-07T08:30:00.000Z',
        'employee': {
          'id': 'emp-001',
          'firstName': 'Sarah',
          'lastName': 'Jenkins',
        },
      },
    );
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    finishCalled = true;
    return const ActivityActionResponse(
      success: true,
      message: 'Aktivitas berhasil diselesaikan',
    );
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    cancelCalled = true;
    return const ActivityActionResponse(
      success: true,
      message: 'Aktivitas berhasil dibatalkan',
    );
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

class _MockFailureDetailRepo extends _MockDetailRepo {
  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) async {
    throw ApiException(message: 'Network error 500', statusCode: 500);
  }
}

void main() {
  group('ActivityDetailBloc Unit Tests', () {
    test('Initial activity resolution works correctly', () {
      final initialItem = ActivityItem(
        id: 'ACT-TEST',
        title: 'Initial Title',
        description: 'Initial Desc',
        userName: 'Sarah',
        userRole: 'Developer',
        department: 'Engineering',
        company: 'Oasish',
        initials: 'SJ',
        status: ActivityStatus.ongoing,
        location: 'HQ',
        time: '08:00',
        date: DateTime.now(),
        isMyActivity: true,
      );

      final bloc = ActivityDetailBloc(
        repository: _MockDetailRepo(),
        initialActivity: initialItem,
      );

      expect(bloc.state.activity.id, 'ACT-TEST');
      expect(bloc.state.status, ActivityDetailStatus.initial);
      bloc.close();
    });

    test('FetchRequested updates state to loaded with fresh data', () async {
      final repo = _MockDetailRepo();
      final bloc = ActivityDetailBloc(repository: repo);

      bloc.add(const ActivityDetailFetchRequested(id: 'ACT-999'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, ActivityDetailStatus.loaded);
      expect(bloc.state.activity.id, 'ACT-999');
      expect(bloc.state.activity.status, ActivityStatus.ongoing);
      bloc.close();
    });

    test('FinishSubmitted updates status to actionSuccess and refetches', () async {
      final repo = _MockDetailRepo();
      final bloc = ActivityDetailBloc(repository: repo);

      bloc.add(const ActivityDetailFinishSubmitted(
        id: 'ACT-999',
        notes: 'Meeting selesai tepat waktu',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.finishCalled, isTrue);
      expect(bloc.state.status, ActivityDetailStatus.actionSuccess);
      expect(bloc.state.activity.status, ActivityStatus.completed);
      expect(bloc.state.hasChanged, isTrue);
      expect(bloc.state.actionMessage, 'Aktivitas berhasil diselesaikan!');
      bloc.close();
    });

    test('CancelSubmitted updates status to actionSuccess and refetches', () async {
      final repo = _MockDetailRepo();
      final bloc = ActivityDetailBloc(repository: repo);

      bloc.add(const ActivityDetailCancelSubmitted(
        id: 'ACT-999',
        notes: 'Dibatalkan oleh manajemen',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.cancelCalled, isTrue);
      expect(bloc.state.status, ActivityDetailStatus.actionSuccess);
      expect(bloc.state.activity.status, ActivityStatus.canceled);
      expect(bloc.state.hasChanged, isTrue);
      expect(bloc.state.actionMessage, 'Aktivitas berhasil dibatalkan.');
      bloc.close();
    });

    test('Fetch failure updates state to failure', () async {
      final repo = _MockFailureDetailRepo();
      final bloc = ActivityDetailBloc(repository: repo);

      bloc.add(const ActivityDetailFetchRequested(id: 'FAIL-1'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, ActivityDetailStatus.failure);
      expect(bloc.state.errorMessage, contains('500'));
      bloc.close();
    });
  });
}
