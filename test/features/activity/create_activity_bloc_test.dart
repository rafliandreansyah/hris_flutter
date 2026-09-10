import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_activity/create_activity_bloc.dart';
import 'package:image_picker/image_picker.dart';

class _MockCreateActivityRepository implements ActivityRepository {
  bool getTypesShouldFail;
  bool createShouldFail;

  _MockCreateActivityRepository({
    this.getTypesShouldFail = false,
    this.createShouldFail = false,
  });

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
    return const ActivityActionResponse(success: true, message: 'OK');
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'OK');
  }

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    if (getTypesShouldFail) {
      throw ApiException(message: 'Failed to fetch activity types', statusCode: 500);
    }
    return const ActivityTypesResponse(
      success: true,
      message: 'OK',
      data: [
        ActivityTypeModel(id: 'type-1', name: 'Client Meeting', code: 'CM'),
        ActivityTypeModel(id: 'type-2', name: 'Site Inspection', code: 'SI'),
      ],
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
    if (createShouldFail) {
      throw ApiException(message: 'Failed to create activity', statusCode: 400);
    }
    return CreateActivityResponse(
      success: true,
      message: 'Activity created successfully',
      data: {
        'id': 'act-new-123',
        'activityTypeId': activityTypeId,
        'locationName': locationName,
        'locationAddress': locationAddress,
        'description': description,
        'status': status,
        'startTime': '2026-09-07T08:00:00.000Z',
        'activityType': {
          'id': activityTypeId,
          'name': 'Client Meeting',
          'code': 'CM',
        },
      },
    );
  }
}

void main() {
  group('CreateActivityBloc Unit Tests', () {
    test('Initial state is correctly configured', () {
      final bloc = CreateActivityBloc(repository: _MockCreateActivityRepository());
      expect(bloc.state.status, CreateActivityStatus.initial);
      expect(bloc.state.activityTypes, isEmpty);
      expect(bloc.state.createdActivity, isNull);
      expect(bloc.state.errorMessage, isEmpty);
      bloc.close();
    });

    test('CreateActivityStarted loads activity types successfully', () async {
      final repo = _MockCreateActivityRepository();
      final bloc = CreateActivityBloc(repository: repo);

      bloc.add(const CreateActivityStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreateActivityStatus.typesLoaded);
      expect(bloc.state.activityTypes.length, 2);
      expect(bloc.state.activityTypes.first.name, 'Client Meeting');
      bloc.close();
    });

    test('CreateActivityStarted handles error gracefully', () async {
      final repo = _MockCreateActivityRepository(getTypesShouldFail: true);
      final bloc = CreateActivityBloc(repository: repo);

      bloc.add(const CreateActivityStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreateActivityStatus.typesLoaded);
      expect(bloc.state.activityTypes, isEmpty);
      expect(bloc.state.errorMessage, contains('Failed to fetch activity types'));
      bloc.close();
    });

    test('CreateActivitySubmitted creates activity successfully', () async {
      final repo = _MockCreateActivityRepository();
      final bloc = CreateActivityBloc(repository: repo);

      bloc.add(const CreateActivitySubmitted(
        activityTypeId: 'type-1',
        latitude: -6.2,
        longitude: 106.8,
        locationName: 'Office Tower',
        locationAddress: 'Sudirman No. 1',
        description: 'Meeting with partner',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreateActivityStatus.success);
      expect(bloc.state.createdActivity, isNotNull);
      expect(bloc.state.createdActivity?.id, 'act-new-123');
      expect(bloc.state.createdActivity?.description, 'Meeting with partner');
      bloc.close();
    });

    test('CreateActivitySubmitted handles submission error', () async {
      final repo = _MockCreateActivityRepository(createShouldFail: true);
      final bloc = CreateActivityBloc(repository: repo);

      bloc.add(const CreateActivitySubmitted(
        activityTypeId: 'type-1',
        latitude: -6.2,
        longitude: 106.8,
        locationName: 'Office Tower',
        locationAddress: 'Sudirman No. 1',
        description: 'Meeting with partner',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreateActivityStatus.failure);
      expect(bloc.state.errorMessage, contains('Failed to create activity'));
      bloc.close();
    });
  });
}
