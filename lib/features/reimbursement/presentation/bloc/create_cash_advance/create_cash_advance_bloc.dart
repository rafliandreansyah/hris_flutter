import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/reimbursement/data/repositories/reimbursement_repository_impl.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_state.dart';

class CreateCashAdvanceBloc
    extends Bloc<CreateCashAdvanceEvent, CreateCashAdvanceState> {
  final ReimbursementRepository _repository;
  final EmployeeRepository _employeeRepository;
  final AuthLocalDataSource _authLocalDataSource;

  CreateCashAdvanceBloc({
    ReimbursementRepository? repository,
    EmployeeRepository? employeeRepository,
    AuthLocalDataSource? authLocalDataSource,
  })  : _repository = repository ?? ReimbursementRepositoryImpl(),
        _employeeRepository = employeeRepository ?? EmployeeRepositoryImpl(),
        _authLocalDataSource = authLocalDataSource ?? AuthLocalDataSourceImpl(),
        super(const CreateCashAdvanceState()) {
    on<CreateCashAdvanceStarted>(_onStarted);
    on<CreateCashAdvanceSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateCashAdvanceStarted event,
    Emitter<CreateCashAdvanceState> emit,
  ) async {
    emit(state.copyWith(isEmployeeLoading: true));
    try {
      final employeeId = await _authLocalDataSource.getEmployeeId();
      if (employeeId != null && employeeId.isNotEmpty) {
        final emp = await _employeeRepository.getEmployeeDetail(employeeId);
        emit(state.copyWith(
          employeeDetail: emp,
          isEmployeeLoading: false,
        ));
      } else {
        emit(state.copyWith(isEmployeeLoading: false));
      }
    } catch (_) {
      emit(state.copyWith(isEmployeeLoading: false));
    }
  }

  Future<void> _onSubmitted(
    CreateCashAdvanceSubmitted event,
    Emitter<CreateCashAdvanceState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      clearErrorMessage: true,
    ));

    try {
      final advanceNumber = await _repository.createCashAdvance(
        title: event.title,
        purpose: event.purpose,
        requestedAmount: event.requestedAmount,
        settlementDeadline: event.settlementDeadline,
      );

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        createdAdvanceNumber: advanceNumber,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      ));
    }
  }
}
