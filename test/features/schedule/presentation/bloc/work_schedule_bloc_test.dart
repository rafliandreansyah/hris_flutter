import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:hris_flutter/features/schedule/domain/repositories/work_schedule_repository.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_bloc.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_event.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_state.dart';

class MockWorkScheduleRepository implements WorkScheduleRepository {
  bool shouldThrow = false;
  String? lastEmployeeId;
  int callCount = 0;

  WorkScheduleResponse mockResponse;

  MockWorkScheduleRepository({
    WorkScheduleResponse? response,
  }) : mockResponse = response ??
            const WorkScheduleResponse(
              success: true,
              message: 'Success',
              data: WorkScheduleData(
                id: 'sched-1',
                employee: WorkScheduleEmployee(
                  id: 'emp-1',
                  firstName: 'John',
                  lastName: 'Doe',
                  email: 'john.doe@example.com',
                  companyName: 'Muratech',
                  departmentName: 'Engineering',
                  positionName: 'Developer',
                ),
                workSchedules: [
                  WorkScheduleItem(
                    id: 'ws-1',
                    workDate: '2026-09-20',
                    isDayOff: false,
                    shift: WorkScheduleShift(
                      id: 'shift-1',
                      name: 'Regular Shift',
                      startTime: '08:00',
                      endTime: '17:00',
                    ),
                  ),
                  WorkScheduleItem(
                    id: 'ws-2',
                    workDate: '2026-09-21',
                    isDayOff: false,
                    shift: WorkScheduleShift(
                      id: 'shift-1',
                      name: 'Regular Shift',
                      startTime: '08:00',
                      endTime: '17:00',
                    ),
                  ),
                  WorkScheduleItem(
                    id: 'ws-3',
                    workDate: '2026-09-22',
                    isDayOff: true,
                    shift: null,
                  ),
                ],
              ),
            );

  @override
  Future<WorkScheduleResponse> getWorkSchedule({String? employeeId}) async {
    callCount++;
    lastEmployeeId = employeeId;
    if (shouldThrow) {
      throw const ApiException(message: 'Jadwal tidak ditemukan', statusCode: 404);
    }
    return mockResponse;
  }
}

void main() {
  group('WorkScheduleBloc', () {
    late MockWorkScheduleRepository mockRepository;

    setUp(() {
      mockRepository = MockWorkScheduleRepository();
    });

    test('initial state has correct default values', () {
      final bloc = WorkScheduleBloc(repository: mockRepository);
      expect(bloc.state.status, WorkScheduleStatus.initial);
      expect(bloc.state.data, isNull);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.isViewingOtherEmployee, isFalse);
      bloc.close();
    });

    test('emits [loading, success] on WorkScheduleFetchRequested for personal schedule', () async {
      final bloc = WorkScheduleBloc(repository: mockRepository);
      final states = <WorkScheduleState>[];
      bloc.stream.listen(states.add);

      bloc.add(const WorkScheduleFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, WorkScheduleStatus.loading);
      expect(states[0].employeeId, isNull);

      expect(states[1].status, WorkScheduleStatus.success);
      expect(states[1].data, isNotNull);
      expect(states[1].isViewingOtherEmployee, isFalse);
      expect(mockRepository.callCount, 1);
      expect(mockRepository.lastEmployeeId, isNull);

      await bloc.close();
    });

    test('emits [loading, success] on WorkScheduleFetchRequested with employeeId', () async {
      final bloc = WorkScheduleBloc(repository: mockRepository);
      final states = <WorkScheduleState>[];
      bloc.stream.listen(states.add);

      bloc.add(const WorkScheduleFetchRequested(employeeId: 'emp-999'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, WorkScheduleStatus.loading);
      expect(states[0].employeeId, 'emp-999');

      expect(states[1].status, WorkScheduleStatus.success);
      expect(states[1].data, isNotNull);
      expect(states[1].isViewingOtherEmployee, isTrue);
      expect(mockRepository.callCount, 1);
      expect(mockRepository.lastEmployeeId, 'emp-999');

      await bloc.close();
    });

    test('emits [loading, failure] on WorkScheduleFetchRequested when repository throws ApiException', () async {
      mockRepository.shouldThrow = true;
      final bloc = WorkScheduleBloc(repository: mockRepository);
      final states = <WorkScheduleState>[];
      bloc.stream.listen(states.add);

      bloc.add(const WorkScheduleFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, WorkScheduleStatus.loading);
      expect(states[1].status, WorkScheduleStatus.failure);
      expect(states[1].errorMessage, 'Jadwal tidak ditemukan');

      await bloc.close();
    });

    test('emits new selectedDate on WorkScheduleDateSelected and resolves schedules correctly', () async {
      final bloc = WorkScheduleBloc(repository: mockRepository);
      final states = <WorkScheduleState>[];

      // First fetch data
      bloc.add(const WorkScheduleFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.stream.listen(states.add);
      // Select date 2026-09-21
      bloc.add(WorkScheduleDateSelected(DateTime(2026, 9, 21)));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 1);
      final updatedState = states[0];
      expect(updatedState.selectedDate, DateTime(2026, 9, 21));
      expect(updatedState.selectedSchedule?.id, 'ws-2');
      expect(updatedState.upcomingSchedules.length, 1);
      expect(updatedState.upcomingSchedules.first.id, 'ws-3');

      await bloc.close();
    });

    test('emits [success] on WorkScheduleRefreshRequested', () async {
      final bloc = WorkScheduleBloc(repository: mockRepository);

      bloc.add(const WorkScheduleFetchRequested(employeeId: 'emp-123'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Provide updated schedule on refresh
      mockRepository.mockResponse = const WorkScheduleResponse(
        success: true,
        message: 'Refreshed',
        data: WorkScheduleData(
          id: 'sched-refreshed',
          workSchedules: [],
        ),
      );

      final states = <WorkScheduleState>[];
      bloc.stream.listen(states.add);

      bloc.add(const WorkScheduleRefreshRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 1);
      expect(states[0].status, WorkScheduleStatus.success);
      expect(states[0].data?.id, 'sched-refreshed');
      expect(mockRepository.lastEmployeeId, 'emp-123');

      await bloc.close();
    });

    test('emits [failure] on WorkScheduleRefreshRequested when repository throws ApiException', () async {
      final bloc = WorkScheduleBloc(repository: mockRepository);

      bloc.add(const WorkScheduleFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      mockRepository.shouldThrow = true;
      final states = <WorkScheduleState>[];
      bloc.stream.listen(states.add);

      bloc.add(const WorkScheduleRefreshRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 1);
      expect(states[0].status, WorkScheduleStatus.failure);
      expect(states[0].errorMessage, 'Jadwal tidak ditemukan');

      await bloc.close();
    });
  });
}
