import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:hris_flutter/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_event.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_state.dart';

class LiveTrackingBloc extends Bloc<LiveTrackingEvent, LiveTrackingState> {
  final TrackingRepository repository;
  Timer? _pollingTimer;

  LiveTrackingBloc({
    TrackingRepository? repository,
    bool enableAutoPolling = true,
  })  : repository = repository ?? TrackingRepositoryImpl(),
        super(LiveTrackingState(lastRefreshed: DateTime.now())) {
    on<LiveTrackingStarted>(_onStarted);
    on<LiveTrackingRefreshed>(_onRefreshed);
    on<LiveTrackingFilterChanged>(_onFilterChanged);
    on<LiveTrackingSearchQueryChanged>(_onSearchQueryChanged);
    on<LiveTrackingEmployeeSelected>(_onEmployeeSelected);
    on<LiveTrackingRouteRequested>(_onRouteRequested);

    if (enableAutoPolling) {
      _startPollingTimer();
    }
  }

  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      add(const LiveTrackingRefreshed(isSilent: true));
    });
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    LiveTrackingStarted event,
    Emitter<LiveTrackingState> emit,
  ) async {
    emit(state.copyWith(
      status: LiveTrackingStatus.loading,
      activeOnly: event.activeOnly,
      errorMessage: () => null,
    ));

    await _fetchData(emit, isSilent: false);
  }

  Future<void> _onRefreshed(
    LiveTrackingRefreshed event,
    Emitter<LiveTrackingState> emit,
  ) async {
    if (!event.isSilent) {
      emit(state.copyWith(status: LiveTrackingStatus.loading));
    }
    await _fetchData(emit, isSilent: event.isSilent);
  }

  Future<void> _onFilterChanged(
    LiveTrackingFilterChanged event,
    Emitter<LiveTrackingState> emit,
  ) async {
    emit(state.copyWith(
      status: LiveTrackingStatus.loading,
      selectedCompanyId: () => event.companyId ?? state.selectedCompanyId,
      selectedDepartmentId: () => event.departmentId ?? state.selectedDepartmentId,
      selectedStatus: event.status ?? state.selectedStatus,
      activeOnly: event.activeOnly ?? state.activeOnly,
      errorMessage: () => null,
    ));

    await _fetchData(emit, isSilent: false);
  }

  void _onSearchQueryChanged(
    LiveTrackingSearchQueryChanged event,
    Emitter<LiveTrackingState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onEmployeeSelected(
    LiveTrackingEmployeeSelected event,
    Emitter<LiveTrackingState> emit,
  ) {
    emit(state.copyWith(
      selectedEmployee: () => event.employee,
      selectedRouteLogs: const [],
      routeErrorMessage: () => null,
    ));
  }

  Future<void> _onRouteRequested(
    LiveTrackingRouteRequested event,
    Emitter<LiveTrackingState> emit,
  ) async {
    emit(state.copyWith(
      isLoadingRoute: true,
      routeErrorMessage: () => null,
      selectedRouteLogs: const [],
    ));

    try {
      final logs = await repository.getTrackingLogs(
        sourceType: event.sourceType,
        referenceId: event.referenceId,
        employeeId: event.employeeId,
        limit: 1000,
      );

      emit(state.copyWith(
        isLoadingRoute: false,
        selectedRouteLogs: logs,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoadingRoute: false,
        routeErrorMessage: () => e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingRoute: false,
        routeErrorMessage: () => 'Gagal memuat rute: $e',
      ));
    }
  }

  Future<void> _fetchData(
    Emitter<LiveTrackingState> emit, {
    required bool isSilent,
  }) async {
    try {
      final response = await repository.getLiveTracking(
        companyId: state.selectedCompanyId,
        departmentId: state.selectedDepartmentId,
        status: state.selectedStatus,
        activeOnly: state.activeOnly,
      );

      // Pertahankan selectedEmployee jika masih ada di daftar terbaru
      LiveEmployeeLocation? updatedSelected = state.selectedEmployee;
      if (updatedSelected != null) {
        final match = response.employees.where(
          (e) => e.employeeId == updatedSelected?.employeeId,
        );
        if (match.isNotEmpty) {
          updatedSelected = match.first;
        }
      }

      emit(state.copyWith(
        status: LiveTrackingStatus.loaded,
        data: () => response,
        selectedEmployee: () => updatedSelected,
        lastRefreshed: DateTime.now(),
        errorMessage: () => null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: LiveTrackingStatus.failure,
        errorMessage: () => e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LiveTrackingStatus.failure,
        errorMessage: () => 'Gagal memuat data live tracking: $e',
      ));
    }
  }
}
