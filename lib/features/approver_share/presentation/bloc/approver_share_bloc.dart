import 'package:hris_flutter/core/utils/app_error_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/approver_share/data/repositories/approver_share_repository_impl.dart';
import 'package:hris_flutter/features/approver_share/domain/repositories/approver_share_repository.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_event.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_state.dart';

class ApproverShareBloc extends Bloc<ApproverShareEvent, ApproverShareState> {
  final ApproverShareRepository _repository;
  String? _module;
  String? _requestId;

  ApproverShareBloc({ApproverShareRepository? repository})
      : _repository = repository ?? ApproverShareRepositoryImpl(),
        super(const ApproverShareInitial()) {
    on<FetchApprovers>(_onFetch);
    on<RefreshApprovers>(_onRefresh);
  }

  Future<void> _onFetch(
    FetchApprovers event,
    Emitter<ApproverShareState> emit,
  ) async {
    _module = event.module;
    _requestId = event.requestId;
    emit(const ApproverShareLoading());
    await _load(emit);
  }

  Future<void> _onRefresh(
    RefreshApprovers event,
    Emitter<ApproverShareState> emit,
  ) async {
    if (_module == null || _requestId == null) return;
    await _load(emit);
  }

  Future<void> _load(Emitter<ApproverShareState> emit) async {
    try {
      final approvers = await _repository.getApprovers(
        module: _module!,
        requestId: _requestId!,
      );
      emit(ApproverShareLoaded(approvers));
    } on ApiException catch (e) {
      emit(ApproverShareError(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(ApproverShareError(message: AppErrorMessage.from(e)));
    }
  }
}
