import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_state.dart';

class ActivityDetailBloc
    extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  final ActivityRepository _repository;
  final SecureStorageService _storageService;

  ActivityDetailBloc({
    ActivityRepository? repository,
    SecureStorageService? storageService,
    ActivityItem? initialActivity,
  })  : _repository = repository ?? ActivityRepositoryImpl(),
        _storageService = storageService ?? SecureStorageService.instance,
        super(ActivityDetailState(
          activity: initialActivity ?? ActivityItem.sampleActivities[1],
          isCreator: (initialActivity ?? ActivityItem.sampleActivities[1]).isMyActivity,
        )) {
    on<ActivityDetailStarted>(_onStarted);
    on<ActivityDetailFetchRequested>(_onFetchRequested);
    on<ActivityDetailFinishSubmitted>(_onFinishSubmitted);
    on<ActivityDetailCancelSubmitted>(_onCancelSubmitted);
  }

  static ActivityItem resolveInitialActivity({
    ActivityItem? activity,
    String? activityId,
  }) {
    if (activity != null) return activity;
    if (activityId != null) {
      final found = ActivityItem.sampleActivities.firstWhere(
        (item) => item.id == activityId,
        orElse: () => ActivityItem.sampleActivities[1],
      );
      return found;
    }
    return ActivityItem.sampleActivities[1];
  }

  Future<void> _onStarted(
    ActivityDetailStarted event,
    Emitter<ActivityDetailState> emit,
  ) async {
    final resolvedActivity = resolveInitialActivity(
      activity: event.initialActivity,
      activityId: event.activityId,
    );

    String? empId;
    try {
      empId = await _storageService.getEmployeeId();
    } catch (_) {}

    final isCreator = _determineIsCreator(resolvedActivity, empId);

    emit(state.copyWith(
      activity: resolvedActivity,
      isCreator: isCreator,
      currentEmployeeId: empId,
    ));

    final idToLoad = event.initialActivity?.id ?? event.activityId;
    if (idToLoad != null && idToLoad.isNotEmpty) {
      final shouldFetch =
          !idToLoad.startsWith('ACT-') || _repository is! ActivityRepositoryImpl;
      if (shouldFetch) {
        add(ActivityDetailFetchRequested(id: idToLoad, showLoading: false));
      }
    }
  }

  Future<void> _onFetchRequested(
    ActivityDetailFetchRequested event,
    Emitter<ActivityDetailState> emit,
  ) async {
    if (event.showLoading) {
      emit(state.copyWith(status: ActivityDetailStatus.loading));
    }

    try {
      final response = await _repository.getActivityDetail(event.id);
      final updatedItem = response.toActivityItem(
        isMyActivity: state.activity.isMyActivity,
        currentEmployeeId: state.currentEmployeeId,
      );
      final isCreator = _determineIsCreator(updatedItem, state.currentEmployeeId);

      emit(state.copyWith(
        status: ActivityDetailStatus.loaded,
        activity: updatedItem,
        isCreator: isCreator,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivityDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFinishSubmitted(
    ActivityDetailFinishSubmitted event,
    Emitter<ActivityDetailState> emit,
  ) async {
    emit(state.copyWith(status: ActivityDetailStatus.submitting));

    try {
      await _repository.finishActivity(
        id: event.id,
        notes: event.notes,
        file: event.file,
      );

      // Muat ulang data terbaru setelah aksi berhasil
      ActivityItem updatedItem = state.activity.copyWith(
        status: ActivityStatus.completed,
        notes: event.notes,
      );
      try {
        final response = await _repository.getActivityDetail(event.id);
        updatedItem = response.toActivityItem(
          isMyActivity: state.activity.isMyActivity,
          currentEmployeeId: state.currentEmployeeId,
        );
      } catch (_) {}
      final isCreator = _determineIsCreator(updatedItem, state.currentEmployeeId);

      emit(state.copyWith(
        status: ActivityDetailStatus.actionSuccess,
        hasChanged: true,
        activity: updatedItem,
        isCreator: isCreator,
        actionMessage: 'Aktivitas berhasil diselesaikan!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivityDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCancelSubmitted(
    ActivityDetailCancelSubmitted event,
    Emitter<ActivityDetailState> emit,
  ) async {
    emit(state.copyWith(status: ActivityDetailStatus.submitting));

    try {
      await _repository.cancelActivity(
        id: event.id,
        notes: event.notes,
        file: event.file,
      );

      // Muat ulang data terbaru setelah aksi pembatalan berhasil
      ActivityItem updatedItem = state.activity.copyWith(
        status: ActivityStatus.canceled,
        notes: event.notes,
      );
      try {
        final response = await _repository.getActivityDetail(event.id);
        updatedItem = response.toActivityItem(
          isMyActivity: state.activity.isMyActivity,
          currentEmployeeId: state.currentEmployeeId,
        );
      } catch (_) {}
      final isCreator = _determineIsCreator(updatedItem, state.currentEmployeeId);

      emit(state.copyWith(
        status: ActivityDetailStatus.actionSuccess,
        hasChanged: true,
        activity: updatedItem,
        isCreator: isCreator,
        actionMessage: 'Aktivitas berhasil dibatalkan.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivityDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  bool _determineIsCreator(ActivityItem item, String? currentEmpId) {
    if (item.isMyActivity) return true;
    if (currentEmpId != null &&
        item.employeeId != null &&
        currentEmpId.trim().isNotEmpty &&
        currentEmpId.trim() == item.employeeId!.trim()) {
      return true;
    }
    return false;
  }
}
