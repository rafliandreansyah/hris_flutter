import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/schedule/data/datasources/work_schedule_remote_datasource.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:hris_flutter/features/schedule/data/repositories/work_schedule_repository_impl.dart';

class _MockWorkScheduleRemoteDataSource implements WorkScheduleRemoteDataSource {
  int getWorkScheduleCallCount = 0;
  String? lastEmployeeId;
  dynamic mockResult;

  @override
  Future<WorkScheduleResponse> getWorkSchedule({String? employeeId}) async {
    getWorkScheduleCallCount++;
    lastEmployeeId = employeeId;
    return mockResult as WorkScheduleResponse;
  }
}

void main() {
  group('WorkScheduleRepositoryImpl Tests', () {
    late _MockWorkScheduleRemoteDataSource mockRemoteDataSource;
    late WorkScheduleRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockWorkScheduleRemoteDataSource();
      repository = WorkScheduleRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('getWorkSchedule delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockResult = WorkScheduleResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': {
          'id': 'sch-1',
          'workSchedules': [
            {
              'id': 'item-1',
              'date': '2026-10-15',
              'shiftName': 'Morning',
            }
          ],
        },
      });

      final result = await repository.getWorkSchedule(employeeId: 'emp-101');

      expect(mockRemoteDataSource.getWorkScheduleCallCount, equals(1));
      expect(mockRemoteDataSource.lastEmployeeId, equals('emp-101'));
      expect(result.success, isTrue);
      expect(result.data?.id, equals('sch-1'));
    });
  });
}
