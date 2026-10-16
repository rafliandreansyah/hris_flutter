import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/data/repositories/lifecycle_repository_impl.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';

class OnboardingCardState extends Equatable {
  final LoadStatus status;
  final OnboardingProgressModel? onboarding;

  const OnboardingCardState({this.status = LoadStatus.initial, this.onboarding});

  /// Kartu dashboard tampil hanya bila ada onboarding aktif dengan pekerjaan tersisa.
  /// Gagal memuat → tersembunyi (tidak boleh memblokir dashboard).
  bool get visible => onboarding != null && onboarding!.hasOpenWork;

  @override
  List<Object?> get props => [status, onboarding];
}

class OnboardingCardCubit extends Cubit<OnboardingCardState> {
  final LifecycleRepository _repository;

  OnboardingCardCubit({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const OnboardingCardState());

  Future<void> load() async {
    try {
      final o = await _repository.getMyOnboarding();
      emit(OnboardingCardState(status: LoadStatus.success, onboarding: o));
    } on ApiException {
      emit(const OnboardingCardState(status: LoadStatus.failure));
    }
  }
}

class TaskActionState extends Equatable {
  final String? busyTaskId;
  final String? completedTaskId;
  final String? errorMessage;
  final int? errorStatusCode;

  const TaskActionState({
    this.busyTaskId,
    this.completedTaskId,
    this.errorMessage,
    this.errorStatusCode,
  });

  @override
  List<Object?> get props => [busyTaskId, completedTaskId, errorMessage, errorStatusCode];
}

/// Menyelesaikan task (acknowledgment / document_upload / manual). Satu task diproses sekali pada satu waktu.
class TaskActionCubit extends Cubit<TaskActionState> {
  final LifecycleRepository _repository;

  TaskActionCubit({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const TaskActionState());

  Future<void> complete(
    LifecycleTaskModel task, {
    String? notes,
    String? attachmentUrl,
  }) async {
    if (state.busyTaskId != null) return;
    if (!task.canComplete) return;
    emit(TaskActionState(busyTaskId: task.id));
    try {
      await _repository.completeTask(
        task.id,
        notes: notes,
        attachmentUrl: attachmentUrl,
      );
      emit(TaskActionState(completedTaskId: task.id));
    } on ApiException catch (e) {
      emit(TaskActionState(errorMessage: e.message, errorStatusCode: e.statusCode));
    }
  }
}

class MyTasksState extends Equatable {
  final LoadStatus status;
  final List<LifecycleTaskModel> tasks;
  final String? errorMessage;

  const MyTasksState({
    this.status = LoadStatus.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, tasks, errorMessage];
}

class MyTasksCubit extends Cubit<MyTasksState> {
  final LifecycleRepository _repository;

  MyTasksCubit({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const MyTasksState());

  Future<void> load({String status = 'pending'}) async {
    emit(const MyTasksState(status: LoadStatus.loading));
    try {
      final tasks = await _repository.getMyTasks(status: status);
      emit(MyTasksState(status: LoadStatus.success, tasks: tasks));
    } on ApiException catch (e) {
      emit(MyTasksState(status: LoadStatus.failure, errorMessage: e.message));
    }
  }
}
