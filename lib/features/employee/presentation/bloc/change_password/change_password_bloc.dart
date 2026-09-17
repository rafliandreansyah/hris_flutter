import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final EmployeeRepository _repository;

  ChangePasswordBloc({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepositoryImpl(),
        super(const ChangePasswordState()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
    on<ChangePasswordReset>(_onReset);
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (event.oldPassword.trim().isEmpty) {
      emit(state.copyWith(
        status: ChangePasswordStatus.failure,
        errorMessage: 'Password saat ini wajib diisi.',
      ));
      return;
    }

    if (event.newPassword.trim().isEmpty) {
      emit(state.copyWith(
        status: ChangePasswordStatus.failure,
        errorMessage: 'Password baru wajib diisi.',
      ));
      return;
    }

    if (event.newPassword != event.confirmPassword) {
      emit(state.copyWith(
        status: ChangePasswordStatus.failure,
        errorMessage: 'Konfirmasi password tidak cocok dengan password baru.',
      ));
      return;
    }

    emit(state.copyWith(status: ChangePasswordStatus.loading));

    try {
      final message = await _repository.updatePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );

      emit(state.copyWith(
        status: ChangePasswordStatus.success,
        successMessage: message,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: ChangePasswordStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChangePasswordStatus.failure,
        errorMessage: 'Terjadi kesalahan: ${e.toString()}',
      ));
    }
  }

  void _onReset(
    ChangePasswordReset event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(const ChangePasswordState());
  }
}
