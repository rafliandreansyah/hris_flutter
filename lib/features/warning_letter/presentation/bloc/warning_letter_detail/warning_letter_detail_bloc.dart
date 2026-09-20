import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/warning_letter/data/repositories/warning_letter_repository_impl.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_event.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_state.dart';

class WarningLetterDetailBloc
    extends Bloc<WarningLetterDetailEvent, WarningLetterDetailState> {
  final WarningLetterRepository _repository;
  String? _currentId;

  WarningLetterDetailBloc({
    WarningLetterRepository? repository,
  })  : _repository = repository ?? WarningLetterRepositoryImpl(),
        super(const WarningLetterDetailInitial()) {
    on<FetchWarningLetterDetail>(_onFetchDetail);
    on<RefreshWarningLetterDetail>(_onRefreshDetail);
  }

  Future<void> _onFetchDetail(
    FetchWarningLetterDetail event,
    Emitter<WarningLetterDetailState> emit,
  ) async {
    _currentId = event.id;
    emit(const WarningLetterDetailLoading());

    try {
      final detail = await _repository.getWarningLetterDetail(event.id);
      emit(WarningLetterDetailLoaded(detail));
    } on ApiException catch (e) {
      emit(
        WarningLetterDetailError(
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      emit(
        WarningLetterDetailError(
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshDetail(
    RefreshWarningLetterDetail event,
    Emitter<WarningLetterDetailState> emit,
  ) async {
    final id = _currentId;
    if (id == null || id.isEmpty) return;

    try {
      final detail = await _repository.getWarningLetterDetail(id);
      emit(WarningLetterDetailLoaded(detail));
    } on ApiException catch (e) {
      emit(
        WarningLetterDetailError(
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      emit(
        WarningLetterDetailError(
          message: e.toString(),
        ),
      );
    }
  }
}
