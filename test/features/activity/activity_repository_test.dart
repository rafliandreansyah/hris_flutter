import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:image_picker/image_picker.dart';

class _MockActivityRemoteDataSource implements ActivityRemoteDataSource {
  int getActivitiesCallCount = 0;
  int getActivityDetailCallCount = 0;
  int finishActivityCallCount = 0;
  int cancelActivityCallCount = 0;
  int getActivityTypesCallCount = 0;
  int createActivityCallCount = 0;
  int createPlanActivityCallCount = 0;
  int startActivityCallCount = 0;

  dynamic mockActivitiesResult;
  dynamic mockDetailResult;
  dynamic mockFinishResult;
  dynamic mockCancelResult;
  dynamic mockTypesResult;
  dynamic mockCreateResult;
  dynamic mockCreatePlanResult;
  dynamic mockStartResult;

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
    getActivitiesCallCount++;
    return mockActivitiesResult as ActivityListResponse;
  }

  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) async {
    getActivityDetailCallCount++;
    return mockDetailResult as ActivityDetailResponse;
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    finishActivityCallCount++;
    return mockFinishResult as ActivityActionResponse;
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    cancelActivityCallCount++;
    return mockCancelResult as ActivityActionResponse;
  }

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    getActivityTypesCallCount++;
    return mockTypesResult as ActivityTypesResponse;
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
    createActivityCallCount++;
    return mockCreateResult as CreateActivityResponse;
  }

  @override
  Future<CreateActivityResponse> createPlanActivity({
    required String employeeId,
    required String activityTypeId,
    required String startTime,
    required String locationName,
    required String locationAddress,
    required String description,
    double latitude = 0,
    double longitude = 0,
    XFile? file,
  }) async {
    createPlanActivityCallCount++;
    return mockCreatePlanResult as CreateActivityResponse;
  }

  @override
  Future<ActivityActionResponse> startActivity({
    required String id,
    required double latitude,
    required double longitude,
    required String locationAddress,
    XFile? file,
  }) async {
    startActivityCallCount++;
    return mockStartResult as ActivityActionResponse;
  }
}

void main() {
  group('ActivityRepositoryImpl Tests', () {
    late _MockActivityRemoteDataSource mockRemoteDataSource;
    late ActivityRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockActivityRemoteDataSource();
      repository = ActivityRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('getActivities delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockActivitiesResult = ActivityListResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'act-1',
            'employeeId': 'emp-1',
            'activityTypeId': 'type-1',
            'locationName': 'Site A',
            'description': 'Work',
            'status': 'ongoing',
            'createdAt': '2026-10-15T08:00:00Z',
          }
        ],
        'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getActivities(page: 1, size: 10);

      expect(mockRemoteDataSource.getActivitiesCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('act-1'));
    });

    test('getActivityDetail delegates to remote data source', () async {
      mockRemoteDataSource.mockDetailResult = ActivityDetailResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'act-1',
          'employeeId': 'emp-1',
          'activityTypeId': 'type-1',
          'locationName': 'Site A',
          'description': 'Detail',
          'status': 'ongoing',
          'createdAt': '2026-10-15T08:00:00Z',
        },
      });

      final result = await repository.getActivityDetail('act-1');

      expect(mockRemoteDataSource.getActivityDetailCallCount, equals(1));
      expect(result.data.id, equals('act-1'));
    });

    test('finishActivity delegates to remote data source', () async {
      mockRemoteDataSource.mockFinishResult = ActivityActionResponse.fromJson({
        'success': true,
        'message': 'Selesai',
      });

      final result = await repository.finishActivity(
        id: 'act-1',
        notes: 'Done',
      );

      expect(mockRemoteDataSource.finishActivityCallCount, equals(1));
      expect(result.success, isTrue);
    });

    test('cancelActivity delegates to remote data source', () async {
      mockRemoteDataSource.mockCancelResult = ActivityActionResponse.fromJson({
        'success': true,
        'message': 'Batal',
      });

      final result = await repository.cancelActivity(
        id: 'act-1',
        notes: 'Cancel reason',
      );

      expect(mockRemoteDataSource.cancelActivityCallCount, equals(1));
      expect(result.success, isTrue);
    });

    test('getActivityTypes caches response on subsequent calls', () async {
      mockRemoteDataSource.mockTypesResult = ActivityTypesResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': [
          {'id': 'type-1', 'name': 'Inspeksi'},
        ],
      });

      final firstCall = await repository.getActivityTypes();
      expect(mockRemoteDataSource.getActivityTypesCallCount, equals(1));
      expect(firstCall.data.first.name, equals('Inspeksi'));

      // Second call should return cached without calling remote data source again
      final secondCall = await repository.getActivityTypes();
      expect(mockRemoteDataSource.getActivityTypesCallCount, equals(1));
      expect(secondCall.data.first.name, equals('Inspeksi'));
    });

    test('createActivity delegates to remote data source', () async {
      mockRemoteDataSource.mockCreateResult = CreateActivityResponse.fromJson({
        'success': true,
        'message': 'Berhasil',
        'data': {'id': 'act-new'},
      });

      final result = await repository.createActivity(
        activityTypeId: 'type-1',
        latitude: -6.2,
        longitude: 106.8,
        locationName: 'Site A',
        locationAddress: 'Address A',
        description: 'New Activity',
      );

      expect(mockRemoteDataSource.createActivityCallCount, equals(1));
      expect(result.success, isTrue);
    });

    test('createPlanActivity delegates to remote data source', () async {
      mockRemoteDataSource.mockCreatePlanResult = CreateActivityResponse.fromJson({
        'success': true,
        'message': 'Berhasil rencana',
        'data': {'id': 'plan-1'},
      });

      final result = await repository.createPlanActivity(
        employeeId: 'emp-1',
        activityTypeId: 'type-1',
        startTime: '2026-10-16 09:00:00',
        locationName: 'Site B',
        locationAddress: 'Address B',
        description: 'Plan Activity',
      );

      expect(mockRemoteDataSource.createPlanActivityCallCount, equals(1));
      expect(result.success, isTrue);
    });

    test('startActivity delegates to remote data source', () async {
      mockRemoteDataSource.mockStartResult = ActivityActionResponse.fromJson({
        'success': true,
        'message': 'Started',
      });

      final result = await repository.startActivity(
        id: 'plan-1',
        latitude: -6.2,
        longitude: 106.8,
        locationAddress: 'Address B',
      );

      expect(mockRemoteDataSource.startActivityCallCount, equals(1));
      expect(result.success, isTrue);
    });
  });
}
