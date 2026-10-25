import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/utils/app_error_message.dart';
import 'package:hris_flutter/features/legal/data/repositories/legal_consent_repository_impl.dart';
import 'package:hris_flutter/features/legal/domain/repositories/legal_consent_repository.dart';
import 'legal_consent_event.dart';
import 'legal_consent_state.dart';

export 'legal_consent_event.dart';
export 'legal_consent_state.dart';

class LegalConsentBloc extends Bloc<LegalConsentEvent, LegalConsentState> {
  final LegalConsentRepository _repository;

  LegalConsentBloc({LegalConsentRepository? repository})
      : _repository = repository ?? LegalConsentRepositoryImpl(),
        super(const LegalConsentState()) {
    on<LegalConsentAgreementToggled>(_onAgreementToggled);
    on<LegalConsentAccepted>(_onAccepted);
  }

  void _onAgreementToggled(
    LegalConsentAgreementToggled event,
    Emitter<LegalConsentState> emit,
  ) {
    emit(state.copyWith(isAgreed: event.isAgreed));
  }

  Future<void> _onAccepted(
    LegalConsentAccepted event,
    Emitter<LegalConsentState> emit,
  ) async {
    if (!state.isAgreed || state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true));
    try {
      await _repository.acceptCurrentVersion();
      emit(state.copyWith(isSubmitting: false, isAccepted: true));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: AppErrorMessage.from(e),
      ));
    }
  }
}
