import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/repositories/lifecycle_repository_impl.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';

sealed class EvaluationAssignedEvent extends Equatable {
  const EvaluationAssignedEvent();
  @override
  List<Object?> get props => [];
}

class EvaluationAssignedStarted extends EvaluationAssignedEvent {
  const EvaluationAssignedStarted();
}

/// `open` = perlu dinilai/direvisi, `history` = sudah dikirim/diproses.
class EvaluationAssignedFilterChanged extends EvaluationAssignedEvent {
  final String status;
  const EvaluationAssignedFilterChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class EvaluationAssignedRefreshed extends EvaluationAssignedEvent {
  const EvaluationAssignedRefreshed();
}

class EvaluationAssignedLoadMore extends EvaluationAssignedEvent {
  const EvaluationAssignedLoadMore();
}

enum EvaluationAssignedStatus { initial, loading, success, failure }

class EvaluationAssignedState extends Equatable {
  final EvaluationAssignedStatus status;
  final String filter;
  final List<EvaluationAssignedItem> items;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final String? errorMessage;
  final int? errorStatusCode;

  const EvaluationAssignedState({
    this.status = EvaluationAssignedStatus.initial,
    this.filter = 'open',
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.errorMessage,
    this.errorStatusCode,
  });

  bool get hasMore => page < totalPages;

  EvaluationAssignedState copyWith({
    EvaluationAssignedStatus? status,
    String? filter,
    List<EvaluationAssignedItem>? items,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
  }) =>
      EvaluationAssignedState(
        status: status ?? this.status,
        filter: filter ?? this.filter,
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        errorStatusCode:
            clearError ? null : (errorStatusCode ?? this.errorStatusCode),
      );

  @override
  List<Object?> get props => [
        status,
        filter,
        items,
        page,
        totalPages,
        isLoadingMore,
        errorMessage,
        errorStatusCode,
      ];
}

class EvaluationAssignedBloc
    extends Bloc<EvaluationAssignedEvent, EvaluationAssignedState> {
  final LifecycleRepository _repository;
  static const int pageSize = 10;

  EvaluationAssignedBloc({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const EvaluationAssignedState()) {
    on<EvaluationAssignedStarted>((e, emit) => _load(emit, state.filter));
    on<EvaluationAssignedRefreshed>((e, emit) => _load(emit, state.filter));
    on<EvaluationAssignedFilterChanged>((e, emit) => _load(emit, e.status));
    on<EvaluationAssignedLoadMore>(_onLoadMore);
  }

  Future<void> _load(Emitter<EvaluationAssignedState> emit, String filter) async {
    emit(
      state.copyWith(
        status: EvaluationAssignedStatus.loading,
        filter: filter,
        items: const [],
        page: 1,
        totalPages: 1,
        clearError: true,
      ),
    );
    try {
      final res = await _repository.getAssignedEvaluations(
        status: filter,
        page: 1,
        size: pageSize,
      );
      emit(
        state.copyWith(
          status: EvaluationAssignedStatus.success,
          items: res.items,
          page: res.page,
          totalPages: res.totalPages,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: EvaluationAssignedStatus.failure,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    EvaluationAssignedLoadMore event,
    Emitter<EvaluationAssignedState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final res = await _repository.getAssignedEvaluations(
        status: state.filter,
        page: state.page + 1,
        size: pageSize,
      );
      emit(
        state.copyWith(
          items: [...state.items, ...res.items],
          page: res.page,
          totalPages: res.totalPages,
          isLoadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }
}
