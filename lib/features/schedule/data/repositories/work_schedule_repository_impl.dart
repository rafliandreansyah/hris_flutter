import 'package:hris_flutter/features/schedule/data/datasources/work_schedule_remote_datasource.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:hris_flutter/features/schedule/domain/repositories/work_schedule_repository.dart';

class WorkScheduleRepositoryImpl implements WorkScheduleRepository {
  final WorkScheduleRemoteDataSource _remoteDataSource;

  WorkScheduleRepositoryImpl({WorkScheduleRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? WorkScheduleRemoteDataSourceImpl();

  @override
  Future<WorkScheduleResponse> getWorkSchedule({String? employeeId}) {
    return _remoteDataSource.getWorkSchedule(employeeId: employeeId);
  }
}
