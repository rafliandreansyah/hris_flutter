import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';

abstract class WorkScheduleRepository {
  Future<WorkScheduleResponse> getWorkSchedule({String? employeeId});
}
