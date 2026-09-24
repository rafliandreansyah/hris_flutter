import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/repositories/resignation_repository_impl.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_event.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_state.dart';

class CreateResignationBloc
    extends Bloc<CreateResignationEvent, CreateResignationState> {
  final ResignationRepository _repository;

  CreateResignationBloc({ResignationRepository? repository})
      : _repository = repository ?? ResignationRepositoryImpl(),
        super(const CreateResignationState()) {
    on<CreateResignationStarted>(_onStarted);
    on<CreateResignationDateChanged>(_onDateChanged);
    on<CreateResignationEarlyWaiverToggled>(_onEarlyWaiverToggled);
    on<CreateResignationEarlyReasonChanged>(_onEarlyReasonChanged);
    on<CreateResignationCategoryChanged>(_onCategoryChanged);
    on<CreateResignationReasonNotesChanged>(_onReasonNotesChanged);
    on<CreateResignationColleagueSelected>(_onColleagueSelected);
    on<CreateResignationHandoverNotesChanged>(_onHandoverNotesChanged);
    on<CreateResignationFileChanged>(_onFileChanged);
    on<CreateResignationAgreementToggled>(_onAgreementToggled);
    on<CreateResignationSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateResignationStarted event,
    Emitter<CreateResignationState> emit,
  ) async {
    emit(state.copyWith(
      status: CreateResignationStatus.loadingInitial,
      clearError: true,
    ));

    try {
      final initialData = await _repository.getInitialFormData();

      DateTime? defaultDate;
      if (initialData.minSuggestedDate.isNotEmpty) {
        try {
          defaultDate = DateTime.parse(initialData.minSuggestedDate);
        } catch (_) {}
      }
      defaultDate ??= DateTime.now().add(
        Duration(days: initialData.companyPolicy.effectiveNoticePeriodDays),
      );

      emit(state.copyWith(
        status: CreateResignationStatus.initialLoaded,
        initialData: initialData,
        selectedEffectiveDate: defaultDate,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CreateResignationStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateResignationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onDateChanged(
    CreateResignationDateChanged event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      selectedEffectiveDate: event.date,
      clearError: true,
    ));
  }

  void _onEarlyWaiverToggled(
    CreateResignationEarlyWaiverToggled event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      isEarlyNotice: event.isEarlyNotice,
      clearError: true,
    ));
  }

  void _onEarlyReasonChanged(
    CreateResignationEarlyReasonChanged event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      earlyNoticeReason: event.reason,
      clearError: true,
    ));
  }

  void _onCategoryChanged(
    CreateResignationCategoryChanged event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      selectedCategory: event.category,
      clearError: true,
    ));
  }

  void _onReasonNotesChanged(
    CreateResignationReasonNotesChanged event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      reasonNotes: event.notes,
      clearError: true,
    ));
  }

  void _onColleagueSelected(
    CreateResignationColleagueSelected event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      selectedColleague: event.colleague,
      clearColleague: event.colleague == null,
      clearError: true,
    ));
  }

  void _onHandoverNotesChanged(
    CreateResignationHandoverNotesChanged event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      handoverNotes: event.notes,
      clearError: true,
    ));
  }

  void _onFileChanged(
    CreateResignationFileChanged event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      file: event.file,
      clearFile: event.file == null,
      clearError: true,
    ));
  }

  void _onAgreementToggled(
    CreateResignationAgreementToggled event,
    Emitter<CreateResignationState> emit,
  ) {
    emit(state.copyWith(
      isAgreed: event.isAgreed,
      clearError: true,
    ));
  }

  Future<void> _onSubmitted(
    CreateResignationSubmitted event,
    Emitter<CreateResignationState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        status: CreateResignationStatus.failure,
        errorMessage: 'Harap lengkapi semua kolom wajib.',
      ));
      return;
    }

    emit(state.copyWith(
      status: CreateResignationStatus.submitting,
      clearError: true,
    ));

    try {
      final formattedDate =
          DateFormat('yyyy-MM-dd').format(state.selectedEffectiveDate!);
      final request = SubmitResignationRequestModel(
        effectiveDate: formattedDate,
        reasonCategory: state.selectedCategory,
        reasonNotes: state.reasonNotes.trim(),
        isEarlyNotice: state.isEarlyNoticeTriggered && state.isEarlyNotice,
        earlyNoticeReason: state.isEarlyNoticeTriggered
            ? state.earlyNoticeReason.trim()
            : null,
        handoverToEmployeeId: state.selectedColleague?.id,
        handoverNotes: state.handoverNotes.trim().isNotEmpty
            ? state.handoverNotes.trim()
            : null,
        file: state.file,
      );

      await _repository.submitResignation(request);

      emit(state.copyWith(status: CreateResignationStatus.success));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CreateResignationStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateResignationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
