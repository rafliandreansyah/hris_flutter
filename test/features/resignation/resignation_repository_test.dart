import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';
import 'package:hris_flutter/features/resignation/data/datasources/resignation_remote_datasource.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:hris_flutter/features/resignation/data/repositories/resignation_repository_impl.dart';

class _MockResignationRemoteDataSource implements ResignationRemoteDataSource {
  int getMyResignationStatusCallCount = 0;
  int getSubordinateResignationsCallCount = 0;
  int cancelMyResignationCallCount = 0;
  int getInitialFormDataCallCount = 0;
  int submitResignationCallCount = 0;

  dynamic mockMyStatusResult;
  dynamic mockSubordinatesResult;
  dynamic mockDetailResult;
  dynamic mockInitialFormResult;

  @override
  Future<MyResignationStatusModel> getMyResignationStatus() async {
    getMyResignationStatusCallCount++;
    return mockMyStatusResult as MyResignationStatusModel;
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
    getSubordinateResignationsCallCount++;
    return mockSubordinatesResult as SubordinateResignationResponseModel;
  }

  @override
  Future<void> cancelMyResignation() async {
    cancelMyResignationCallCount++;
  }


  @override
  Future<ResignationInitialFormModel> getInitialFormData() async {
    getInitialFormDataCallCount++;
    return mockInitialFormResult as ResignationInitialFormModel;
  }

  @override
  Future<void> submitResignation(SubmitResignationRequestModel request) async {
    submitResignationCallCount++;
  }

  final List<String> calls = [];
  Map<String, Object?> lastArgs = {};

  @override
  Future<void> approveSubordinateResignation(
    String id, {
    required String managerNotes,
    bool approveEarlyNotice = true,
  }) async {
    calls.add('approve');
    lastArgs = {'id': id, 'notes': managerNotes, 'early': approveEarlyNotice};
  }

  @override
  Future<void> rejectSubordinateResignation(
    String id, {
    required String rejectionReason,
  }) async {
    calls.add('reject');
    lastArgs = {'id': id, 'notes': rejectionReason};
  }

  @override
  Future<void> submitExitInterview(ExitInterviewRequestModel request) async {
    calls.add('exit');
    lastArgs = {'request': request};
  }
}

void main() {
  group('ResignationRepositoryImpl Tests', () {
    late _MockResignationRemoteDataSource mockRemoteDataSource;
    late ResignationRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockResignationRemoteDataSource();
      repository = ResignationRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('getMyResignationStatus delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockMyStatusResult = MyResignationStatusModel.fromJson(const {
        'hasActiveResignation': true,
        'daysRemaining': 15,
        'canCancel': true,
        'resignation': {
          'id': 'res-01',
          'companyId': 'comp-1',
          'employeeId': 'emp-1',
          'status': 'submitted',
        },
      });

      final result = await repository.getMyResignationStatus();

      expect(mockRemoteDataSource.getMyResignationStatusCallCount, equals(1));
      expect(result.hasActiveResignation, isTrue);
      expect(result.daysRemaining, equals(15));
      expect(result.resignation?.id, equals('res-01'));
    });

    test('getSubordinateResignations delegates to remote data source', () async {
      mockRemoteDataSource.mockSubordinatesResult = SubordinateResignationResponseModel.fromJson(const {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'res-sub-1',
            'companyId': 'comp-1',
            'employeeId': 'emp-2',
            'status': 'submitted',
          }
        ],
        'meta': {'page': 1, 'size': 10, 'total': 1, 'totalPages': 1},
      });

      final result = await repository.getSubordinateResignations(
        status: 'submitted',
        page: 1,
        size: 10,
        search: 'Budi',
      );

      expect(mockRemoteDataSource.getSubordinateResignationsCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('res-sub-1'));
    });

    test('cancelMyResignation delegates to remote data source', () async {
      await repository.cancelMyResignation();

      expect(mockRemoteDataSource.cancelMyResignationCallCount, equals(1));
    });


    test('getInitialFormData delegates to remote data source', () async {
      mockRemoteDataSource.mockInitialFormResult = ResignationInitialFormModel.fromJson(const {
        'companyPolicy': {
          'defaultNoticePeriodDays': 30,
        },
        'employee': {
          'id': 'emp-1',
          'name': 'Budi',
        },
        'minSuggestedDate': '2026-11-15',
        'colleagues': [],
      });

      final result = await repository.getInitialFormData();

      expect(mockRemoteDataSource.getInitialFormDataCallCount, equals(1));
      expect(result.minSuggestedDate, equals('2026-11-15'));
      expect(result.companyPolicy.defaultNoticePeriodDays, equals(30));
    });

    test('submitResignation delegates to remote data source', () async {
      const request = SubmitResignationRequestModel(
        effectiveDate: '2026-11-30',
        reasonCategory: 'PERSONAL',
        reasonNotes: 'Urusan keluarga',
      );

      await repository.submitResignation(request);

      expect(mockRemoteDataSource.submitResignationCallCount, equals(1));
    });
  });
}
