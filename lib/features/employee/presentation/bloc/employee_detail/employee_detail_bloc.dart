import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_detail/employee_detail_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_detail/employee_detail_state.dart';

export 'employee_detail_event.dart';
export 'employee_detail_state.dart';

class EmployeeDetailBloc
    extends Bloc<EmployeeDetailEvent, EmployeeDetailState> {
  final EmployeeRepository _repository;

  EmployeeDetailBloc({
    EmployeeRepository? repository,
  })  : _repository = repository ?? EmployeeRepositoryImpl(),
        super(const EmployeeDetailState()) {
    on<EmployeeDetailStarted>(_onStarted);
    on<EmployeeDetailRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    EmployeeDetailStarted event,
    Emitter<EmployeeDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: EmployeeDetailStatus.loading,
      employeeId: event.employeeId,
      employee: event.employee,
      clearError: true,
    ));

    await _fetchDetail(
      employeeId: event.employeeId,
      employeeRawId: event.employee?.rawId ?? event.employee?.id,
      emit: emit,
    );
  }

  Future<void> _onRefreshed(
    EmployeeDetailRefreshed event,
    Emitter<EmployeeDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: EmployeeDetailStatus.loading,
      clearError: true,
    ));

    await _fetchDetail(
      employeeId: state.employeeId,
      employeeRawId: state.employee?.rawId ?? state.employee?.id,
      emit: emit,
    );
  }

  Future<void> _fetchDetail({
    String? employeeId,
    String? employeeRawId,
    required Emitter<EmployeeDetailState> emit,
  }) async {
    String? targetId = employeeId;

    if (targetId == null || targetId.isEmpty) {
      targetId = employeeRawId;
    }

    if (targetId == null || targetId.isEmpty) {
      targetId = await SecureStorageService.instance.getEmployeeId();
    }

    if (targetId != null && targetId.isNotEmpty) {
      try {
        final data = await _repository.getEmployeeDetail(targetId);
        emit(state.copyWith(
          detail: data,
          status: EmployeeDetailStatus.success,
        ));
        return;
      } catch (e) {
        emit(state.copyWith(
          status: EmployeeDetailStatus.failure,
          errorMessage: e.toString(),
        ));
        return;
      }
    }

    emit(state.copyWith(
      status: EmployeeDetailStatus.failure,
      errorMessage: 'Employee ID tidak ditemukan',
    ));
  }
}
