import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_logs/attendance_logs_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_logs/attendance_logs_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_filter_bottom_sheet.dart';

export 'attendance_logs_event.dart';
export 'attendance_logs_state.dart';

class AttendanceLogsBloc
    extends Bloc<AttendanceLogsEvent, AttendanceLogsState> {
  final AttendanceRepository _repository;
  final SecureStorageService _storageService;

  AttendanceLogsBloc({
    AttendanceRepository? repository,
    SecureStorageService? storageService,
    String? employeeId,
    bool lastMonth = false,
  })  : _repository = repository ?? AttendanceRepositoryImpl(),
        _storageService = storageService ?? SecureStorageService.instance,
        super(AttendanceLogsState(
          employeeId: employeeId,
          lastMonth: lastMonth,
        )) {
    on<AttendanceLogsStarted>(_onStarted);
    on<AttendanceLogsRefreshed>(_onRefreshed);
    on<AttendanceLogsMonthToggled>(_onMonthToggled);
    on<AttendanceLogsLoadMore>(_onLoadMore);
    on<AttendanceLogsFilterApplied>(_onFilterApplied);
  }

  Future<void> _onStarted(
    AttendanceLogsStarted event,
    Emitter<AttendanceLogsState> emit,
  ) async {
    String? empId = event.employeeId ?? state.employeeId;
    if (empId == null || empId.isEmpty) {
      try {
        empId = await _storageService.getEmployeeId();
      } catch (_) {}
    }
    await _fetchPage(
      emit: emit,
      employeeId: empId,
      lastMonth: event.lastMonth,
    );
  }

  Future<void> _onRefreshed(
    AttendanceLogsRefreshed event,
    Emitter<AttendanceLogsState> emit,
  ) async {
    await _fetchPage(
      emit: emit,
      employeeId: event.employeeId ?? state.employeeId,
      lastMonth: event.lastMonth ?? state.lastMonth,
    );
  }

  Future<void> _onMonthToggled(
    AttendanceLogsMonthToggled event,
    Emitter<AttendanceLogsState> emit,
  ) async {
    if (state.lastMonth == event.lastMonth) return;
    await _fetchPage(emit: emit, lastMonth: event.lastMonth);
  }

  Future<void> _onLoadMore(
    AttendanceLogsLoadMore event,
    Emitter<AttendanceLogsState> emit,
  ) async {
    if (state.isLoadingMore) return;
    if (state.status == AttendanceLogsStatus.loading) return;
    if (!state.hasMorePages) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final response = await _repository.getAttendanceLogs(
        employeeId: state.employeeId,
        lastMonth: state.lastMonth,
        page: state.currentPage + 1,
        size: state.pageSize,
        startDate: state.filterCriteria.startDateQuery,
        endDate: state.filterCriteria.endDateQuery,
        type: state.filterCriteria.typeQuery,
        status: state.filterCriteria.statusQuery,
      );

      emit(state.copyWith(
        logs: [...state.logs, ...response.data],
        currentPage: response.meta.page,
        totalPages: response.meta.totalPages,
        isLoadingMore: false,
        status: AttendanceLogsStatus.success,
      ));
    } on ApiException catch (e) {
      final msg = e.statusCode == 403 ? 'Tidak ada hak akses' : e.message;
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: msg,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFilterApplied(
    AttendanceLogsFilterApplied event,
    Emitter<AttendanceLogsState> emit,
  ) async {
    await _fetchPage(emit: emit, filterCriteria: event.criteria);
  }

  Future<void> _fetchPage({
    required Emitter<AttendanceLogsState> emit,
    String? employeeId,
    bool? lastMonth,
    AttendanceLogFilterCriteria? filterCriteria,
  }) async {
    final activeEmployeeId = employeeId ?? state.employeeId;
    final activeLastMonth = lastMonth ?? state.lastMonth;
    final activeCriteria = filterCriteria ?? state.filterCriteria;

    final isMonthChanged = activeLastMonth != state.lastMonth;

    emit(state.copyWith(
      isLoadingMore: false,
      status: AttendanceLogsStatus.loading,
      employeeId: activeEmployeeId,
      lastMonth: activeLastMonth,
      filterCriteria: activeCriteria,
      logs: isMonthChanged ? const [] : null,
      clearSummary: isMonthChanged,
      clearError: true,
    ));

    try {
      final response = await _repository.getAttendanceLogs(
        employeeId: activeEmployeeId,
        lastMonth: activeLastMonth,
        page: 1,
        size: state.pageSize,
        startDate: activeCriteria.startDateQuery,
        endDate: activeCriteria.endDateQuery,
        type: activeCriteria.typeQuery,
        status: activeCriteria.statusQuery,
      );

      AttendanceLogSummary? summary;
      try {
        summary = await _repository.getAttendanceSummary(
          employeeId: activeEmployeeId,
        );
      } catch (_) {
        summary = null;
      }

      emit(state.copyWith(
        employeeId: activeEmployeeId,
        logs: response.data,
        summary: summary,
        clearSummary: summary == null,
        currentPage: response.meta.page,
        totalPages: response.meta.totalPages,
        status: AttendanceLogsStatus.success,
      ));
    } on ApiException catch (e) {
      final msg = e.statusCode == 403 ? 'Tidak ada hak akses' : e.message;
      emit(state.copyWith(
        status: AttendanceLogsStatus.failure,
        errorMessage: msg,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceLogsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
