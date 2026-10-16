import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/repositories/lifecycle_repository_impl.dart';
import 'package:hris_flutter/features/lifecycle/domain/repositories/lifecycle_repository.dart';

sealed class EvaluationFormEvent extends Equatable {
  const EvaluationFormEvent();
  @override
  List<Object?> get props => [];
}

class EvaluationFormStarted extends EvaluationFormEvent {
  final String id;
  const EvaluationFormStarted(this.id);
  @override
  List<Object?> get props => [id];
}

class EvaluationFormRatingChanged extends EvaluationFormEvent {
  final String itemId;
  final int score;
  const EvaluationFormRatingChanged(this.itemId, this.score);
  @override
  List<Object?> get props => [itemId, score];
}

class EvaluationFormTextChanged extends EvaluationFormEvent {
  final String itemId;
  final String text;
  const EvaluationFormTextChanged(this.itemId, this.text);
  @override
  List<Object?> get props => [itemId, text];
}

class EvaluationFormProposalChanged extends EvaluationFormEvent {
  final String? proposal;
  const EvaluationFormProposalChanged(this.proposal);
  @override
  List<Object?> get props => [proposal];
}

class EvaluationFormNotesChanged extends EvaluationFormEvent {
  final String notes;
  const EvaluationFormNotesChanged(this.notes);
  @override
  List<Object?> get props => [notes];
}

/// Dipicu otomatis (debounce) setelah ada perubahan; juga dapat dipanggil manual.
class EvaluationFormAutoSaveRequested extends EvaluationFormEvent {
  const EvaluationFormAutoSaveRequested();
}

class EvaluationFormSubmitted extends EvaluationFormEvent {
  const EvaluationFormSubmitted();
}

enum EvaluationFormStatus { initial, loading, loaded, failure, submitting, submitted }

enum EvaluationDraftSaveState { idle, dirty, saving, saved, error }

class EvaluationFormState extends Equatable {
  final EvaluationFormStatus status;
  final EvaluationForm? form;
  final Map<String, int> scores;
  final Map<String, String> texts;
  final String? proposal;
  final String evaluatorNotes;
  final EvaluationDraftSaveState saveState;
  final String? errorMessage;
  final int? errorStatusCode;
  final EvaluationSubmitResult? submitResult;

  const EvaluationFormState({
    this.status = EvaluationFormStatus.initial,
    this.form,
    this.scores = const {},
    this.texts = const {},
    this.proposal,
    this.evaluatorNotes = '',
    this.saveState = EvaluationDraftSaveState.idle,
    this.errorMessage,
    this.errorStatusCode,
    this.submitResult,
  });

  /// Skor sementara untuk tampilan saja (skor resmi dihitung server saat kirim).
  double? get tentativeScore {
    final f = form;
    if (f == null) return null;
    var weighted = 0.0;
    var totalWeight = 0.0;
    for (final item in f.items.where((i) => i.isRating)) {
      final s = scores[item.id];
      if (s == null) continue;
      final w = item.weight ?? 0;
      weighted += s * w;
      totalWeight += w;
    }
    if (totalWeight == 0) return null;
    return (weighted / totalWeight * 100).round() / 100;
  }

  /// Kriteria wajib yang belum terisi.
  List<EvaluationTemplateItem> get missingRequired {
    final f = form;
    if (f == null) return const [];
    return f.items.where((i) {
      if (!i.isRequired) return false;
      return i.isRating
          ? scores[i.id] == null
          : (texts[i.id] ?? '').trim().isEmpty;
    }).toList();
  }

  bool get canSubmit =>
      form != null &&
      form!.canEdit &&
      missingRequired.isEmpty &&
      proposal != null &&
      status == EvaluationFormStatus.loaded;

  EvaluationFormState copyWith({
    EvaluationFormStatus? status,
    EvaluationForm? form,
    Map<String, int>? scores,
    Map<String, String>? texts,
    String? proposal,
    bool clearProposal = false,
    String? evaluatorNotes,
    EvaluationDraftSaveState? saveState,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
    EvaluationSubmitResult? submitResult,
  }) =>
      EvaluationFormState(
        status: status ?? this.status,
        form: form ?? this.form,
        scores: scores ?? this.scores,
        texts: texts ?? this.texts,
        proposal: clearProposal ? null : (proposal ?? this.proposal),
        evaluatorNotes: evaluatorNotes ?? this.evaluatorNotes,
        saveState: saveState ?? this.saveState,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        errorStatusCode:
            clearError ? null : (errorStatusCode ?? this.errorStatusCode),
        submitResult: submitResult ?? this.submitResult,
      );

  @override
  List<Object?> get props => [
        status,
        form,
        scores,
        texts,
        proposal,
        evaluatorNotes,
        saveState,
        errorMessage,
        errorStatusCode,
        submitResult,
      ];
}

class EvaluationFormBloc extends Bloc<EvaluationFormEvent, EvaluationFormState> {
  final LifecycleRepository _repository;

  EvaluationFormBloc({
    LifecycleRepository? repository,
    Duration autoSaveDelay = const Duration(milliseconds: 1200),
  })  : _repository = repository ?? LifecycleRepositoryImpl(),
        super(const EvaluationFormState()) {
    on<EvaluationFormStarted>(_onStarted);
    on<EvaluationFormRatingChanged>(_onRating);
    on<EvaluationFormTextChanged>(_onText);
    on<EvaluationFormProposalChanged>(_onProposal);
    on<EvaluationFormNotesChanged>(_onNotes);
    on<EvaluationFormAutoSaveRequested>(
      _onAutoSave,
      transformer: debounceRestartable(autoSaveDelay),
    );
    on<EvaluationFormSubmitted>(_onSubmit);
  }

  List<EvaluationAnswer> _currentAnswers() {
    final f = state.form!;
    return f.items
        .where((i) => i.isRating
            ? state.scores[i.id] != null
            : (state.texts[i.id] ?? '').trim().isNotEmpty)
        .map(
          (i) => EvaluationAnswer(
            templateItemId: i.id,
            score: i.isRating ? state.scores[i.id] : null,
            textAnswer: i.isRating ? null : state.texts[i.id]!.trim(),
          ),
        )
        .toList();
  }

  Future<void> _onStarted(
    EvaluationFormStarted event,
    Emitter<EvaluationFormState> emit,
  ) async {
    emit(const EvaluationFormState(status: EvaluationFormStatus.loading));
    try {
      final form = await _repository.getEvaluationForm(event.id);
      emit(
        EvaluationFormState(
          status: EvaluationFormStatus.loaded,
          form: form,
          scores: {
            for (final a in form.answers)
              if (a.score != null) a.templateItemId: a.score!,
          },
          texts: {
            for (final a in form.answers)
              if ((a.textAnswer ?? '').isNotEmpty) a.templateItemId: a.textAnswer!,
          },
          proposal: form.evaluatorProposal,
          evaluatorNotes: form.evaluatorNotes ?? '',
        ),
      );
    } on ApiException catch (e) {
      emit(
        EvaluationFormState(
          status: EvaluationFormStatus.failure,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }

  bool get _editable =>
      state.form?.canEdit == true && state.status == EvaluationFormStatus.loaded;

  void _markDirty(Emitter<EvaluationFormState> emit, EvaluationFormState next) {
    emit(next.copyWith(saveState: EvaluationDraftSaveState.dirty, clearError: true));
    add(const EvaluationFormAutoSaveRequested());
  }

  void _onRating(EvaluationFormRatingChanged e, Emitter<EvaluationFormState> emit) {
    if (!_editable) return;
    _markDirty(emit, state.copyWith(scores: {...state.scores, e.itemId: e.score}));
  }

  void _onText(EvaluationFormTextChanged e, Emitter<EvaluationFormState> emit) {
    if (!_editable) return;
    _markDirty(emit, state.copyWith(texts: {...state.texts, e.itemId: e.text}));
  }

  void _onProposal(EvaluationFormProposalChanged e, Emitter<EvaluationFormState> emit) {
    if (!_editable) return;
    _markDirty(
      emit,
      e.proposal == null
          ? state.copyWith(clearProposal: true)
          : state.copyWith(proposal: e.proposal),
    );
  }

  void _onNotes(EvaluationFormNotesChanged e, Emitter<EvaluationFormState> emit) {
    if (!_editable) return;
    _markDirty(emit, state.copyWith(evaluatorNotes: e.notes));
  }

  Future<void> _onAutoSave(
    EvaluationFormAutoSaveRequested event,
    Emitter<EvaluationFormState> emit,
  ) async {
    if (!_editable || state.saveState != EvaluationDraftSaveState.dirty) return;
    final answers = _currentAnswers();
    if (answers.isEmpty) {
      emit(state.copyWith(saveState: EvaluationDraftSaveState.idle));
      return;
    }
    emit(state.copyWith(saveState: EvaluationDraftSaveState.saving));
    try {
      await _repository.saveEvaluationAnswers(
        state.form!.id,
        answers: answers,
        evaluatorProposal: state.proposal,
        evaluatorNotes: state.evaluatorNotes.trim().isEmpty
            ? null
            : state.evaluatorNotes.trim(),
      );
      emit(state.copyWith(saveState: EvaluationDraftSaveState.saved));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          saveState: EvaluationDraftSaveState.error,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }

  Future<void> _onSubmit(
    EvaluationFormSubmitted event,
    Emitter<EvaluationFormState> emit,
  ) async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: EvaluationFormStatus.submitting, clearError: true));
    try {
      // Jawaban dikirim lengkap bersama submit agar satu panggilan cukup (draf menunggu debounce).
      final result = await _repository.submitEvaluation(
        state.form!.id,
        answers: _currentAnswers(),
        evaluatorProposal: state.proposal,
        evaluatorNotes: state.evaluatorNotes.trim().isEmpty
            ? null
            : state.evaluatorNotes.trim(),
      );
      emit(
        state.copyWith(
          status: EvaluationFormStatus.submitted,
          submitResult: result,
          saveState: EvaluationDraftSaveState.idle,
        ),
      );
    } on ApiException catch (e) {
      // 409 (status berubah/kalah balapan) & 400 (validasi server) ditampilkan apa adanya.
      emit(
        state.copyWith(
          status: EvaluationFormStatus.loaded,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    }
  }
}
