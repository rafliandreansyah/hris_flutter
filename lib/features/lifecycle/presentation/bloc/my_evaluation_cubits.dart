import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/repositories/lifecycle_repository_impl.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';

enum LoadStatus { initial, loading, success, failure }

class MyEvaluationsState extends Equatable {
  final LoadStatus status;
  final List<MyEvaluationItem> items;
  final String? errorMessage;
  final int? errorStatusCode;

  const MyEvaluationsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.errorStatusCode,
  });

  /// Ada hasil yang belum dikonfirmasi karyawan (untuk badge/pengingat).
  bool get hasUnacknowledged =>
      items.any((e) => e.status == 'decided' && !e.acknowledged);

  @override
  List<Object?> get props => [status, items, errorMessage, errorStatusCode];
}

class MyEvaluationsCubit extends Cubit<MyEvaluationsState> {
  final LifecycleRepository _repository;

  MyEvaluationsCubit({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const MyEvaluationsState());

  Future<void> load() async {
    emit(const MyEvaluationsState(status: LoadStatus.loading));
    try {
      final items = await _repository.getMyEvaluations();
      emit(MyEvaluationsState(status: LoadStatus.success, items: items));
    } on ApiException catch (e) {
      emit(
        MyEvaluationsState(
          status: LoadStatus.failure,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }
}

class MyEvaluationDetailState extends Equatable {
  final LoadStatus status;
  final MyEvaluationDetail? detail;
  final bool isAcknowledging;
  final bool justAcknowledged;
  final String? errorMessage;
  final int? errorStatusCode;

  const MyEvaluationDetailState({
    this.status = LoadStatus.initial,
    this.detail,
    this.isAcknowledging = false,
    this.justAcknowledged = false,
    this.errorMessage,
    this.errorStatusCode,
  });

  MyEvaluationDetailState copyWith({
    LoadStatus? status,
    MyEvaluationDetail? detail,
    bool? isAcknowledging,
    bool? justAcknowledged,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
  }) =>
      MyEvaluationDetailState(
        status: status ?? this.status,
        detail: detail ?? this.detail,
        isAcknowledging: isAcknowledging ?? this.isAcknowledging,
        justAcknowledged: justAcknowledged ?? this.justAcknowledged,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        errorStatusCode:
            clearError ? null : (errorStatusCode ?? this.errorStatusCode),
      );

  @override
  List<Object?> get props => [
        status,
        detail,
        isAcknowledging,
        justAcknowledged,
        errorMessage,
        errorStatusCode,
      ];
}

class MyEvaluationDetailCubit extends Cubit<MyEvaluationDetailState> {
  final LifecycleRepository _repository;

  MyEvaluationDetailCubit({LifecycleRepository? repository})
      : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const MyEvaluationDetailState());

  Future<void> load(String id) async {
    emit(const MyEvaluationDetailState(status: LoadStatus.loading));
    try {
      final detail = await _repository.getMyEvaluation(id);
      emit(MyEvaluationDetailState(status: LoadStatus.success, detail: detail));
    } on ApiException catch (e) {
      emit(
        MyEvaluationDetailState(
          status: LoadStatus.failure,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }

  /// Konfirmasi hasil; server idempoten sehingga klik ganda aman. Setelah sukses detail dimuat ulang
  /// agar tombol berubah menjadi status "sudah dikonfirmasi".
  Future<void> acknowledge({String? comment}) async {
    final current = state.detail;
    if (current == null || state.isAcknowledging) return;
    emit(state.copyWith(isAcknowledging: true, clearError: true));
    try {
      await _repository.acknowledgeEvaluation(current.summary.id, comment: comment);
      final fresh = await _repository.getMyEvaluation(current.summary.id);
      emit(
        state.copyWith(
          detail: fresh,
          isAcknowledging: false,
          justAcknowledged: true,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          isAcknowledging: false,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }
}
