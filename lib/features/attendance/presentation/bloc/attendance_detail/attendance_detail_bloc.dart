import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_detail/attendance_detail_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_detail/attendance_detail_state.dart';

export 'attendance_detail_event.dart';
export 'attendance_detail_state.dart';

class AttendanceDetailBloc
    extends Bloc<AttendanceDetailEvent, AttendanceDetailState> {
  final AttendanceRepository _repository;

  AttendanceDetailBloc({AttendanceRepository? repository})
      : _repository = repository ?? AttendanceRepositoryImpl(),
        super(const AttendanceDetailState()) {
    on<AttendanceDetailStarted>(_onStarted);
    on<AttendanceDetailRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    AttendanceDetailStarted event,
    Emitter<AttendanceDetailState> emit,
  ) async {
    await _fetchDetail(event.id, emit);
  }

  Future<void> _onRefreshed(
    AttendanceDetailRefreshed event,
    Emitter<AttendanceDetailState> emit,
  ) async {
    await _fetchDetail(event.id, emit);
  }

  Future<void> _fetchDetail(
    String id,
    Emitter<AttendanceDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: AttendanceDetailStatus.loading,
      clearError: true,
    ));

    try {
      final detail = await _repository.getAttendanceDetail(id);
      emit(state.copyWith(
        status: AttendanceDetailStatus.success,
        detail: detail,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AttendanceDetailStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
