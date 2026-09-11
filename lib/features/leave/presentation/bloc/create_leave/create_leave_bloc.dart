import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/create_leave/create_leave_event.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/create_leave/create_leave_state.dart';

export 'create_leave_event.dart';
export 'create_leave_state.dart';

class CreateLeaveBloc extends Bloc<CreateLeaveEvent, CreateLeaveState> {
  final LeaveRepository _repository;

  CreateLeaveBloc({LeaveRepository? repository})
      : _repository = repository ?? LeaveRepositoryImpl(),
        super(const CreateLeaveState()) {
    on<CreateLeaveStarted>(_onStarted);
    on<CreateLeaveTypeChanged>(_onTypeChanged);
    on<CreateLeaveSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateLeaveStarted event,
    Emitter<CreateLeaveState> emit,
  ) async {
    emit(state.copyWith(status: CreateLeaveStatus.loadingTypes));
    try {
      final types = await _repository.getLeaveTypes();
      emit(state.copyWith(
        status: CreateLeaveStatus.typesLoaded,
        leaveTypes: types,
        errorMessage: '',
        statusCode: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CreateLeaveStatus.typesLoaded,
        leaveTypes: const [],
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateLeaveStatus.typesLoaded,
        leaveTypes: const [],
        errorMessage: e.toString(),
      ));
    }
  }

  void _onTypeChanged(
    CreateLeaveTypeChanged event,
    Emitter<CreateLeaveState> emit,
  ) {
    emit(state.copyWith(
      selectedType: event.leaveType,
      clearSelectedType: event.leaveType == null,
    ));
  }

  Future<void> _onSubmitted(
    CreateLeaveSubmitted event,
    Emitter<CreateLeaveState> emit,
  ) async {
    emit(state.copyWith(status: CreateLeaveStatus.submitting));
    try {
      final result = await _repository.createLeaveRequest(
        leaveTypeId: event.leaveTypeId,
        startDate: event.startDate,
        totalDays: event.totalDays,
        notes: event.notes,
        file: event.file,
      );
      emit(state.copyWith(
        status: CreateLeaveStatus.success,
        createdId: result.id,
        successMessage: result.message.isNotEmpty
            ? result.message
            : 'Pengajuan cuti berhasil dikirim!',
        errorMessage: '',
        statusCode: null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CreateLeaveStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateLeaveStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
