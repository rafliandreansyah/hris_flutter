import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/schedule/data/repositories/work_schedule_repository_impl.dart';
import 'package:hris_flutter/features/schedule/domain/repositories/work_schedule_repository.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_event.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_state.dart';

class WorkScheduleBloc extends Bloc<WorkScheduleEvent, WorkScheduleState> {
  final WorkScheduleRepository _repository;

  WorkScheduleBloc({WorkScheduleRepository? repository})
      : _repository = repository ?? WorkScheduleRepositoryImpl(),
        super(WorkScheduleState()) {
    on<WorkScheduleFetchRequested>(_onFetchRequested);
    on<WorkScheduleDateSelected>(_onDateSelected);
    on<WorkScheduleRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onFetchRequested(
    WorkScheduleFetchRequested event,
    Emitter<WorkScheduleState> emit,
  ) async {
    final empId = event.employeeId ?? state.employeeId;
    emit(state.copyWith(
      status: WorkScheduleStatus.loading,
      employeeId: empId,
      errorMessage: null,
    ));

    try {
      final response = await _repository.getWorkSchedule(employeeId: empId);
      emit(state.copyWith(
        status: WorkScheduleStatus.success,
        data: response.data,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: WorkScheduleStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkScheduleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onDateSelected(
    WorkScheduleDateSelected event,
    Emitter<WorkScheduleState> emit,
  ) {
    emit(state.copyWith(selectedDate: event.selectedDate));
  }

  Future<void> _onRefreshRequested(
    WorkScheduleRefreshRequested event,
    Emitter<WorkScheduleState> emit,
  ) async {
    try {
      final response = await _repository.getWorkSchedule(
        employeeId: state.employeeId,
      );
      emit(state.copyWith(
        status: WorkScheduleStatus.success,
        data: response.data,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: WorkScheduleStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkScheduleStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
