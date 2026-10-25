import 'package:equatable/equatable.dart';

class LegalConsentState extends Equatable {
  final bool isAgreed;
  final bool isSubmitting;
  final bool isAccepted;
  final String? errorMessage;

  const LegalConsentState({
    this.isAgreed = false,
    this.isSubmitting = false,
    this.isAccepted = false,
    this.errorMessage,
  });

  LegalConsentState copyWith({
    bool? isAgreed,
    bool? isSubmitting,
    bool? isAccepted,
    String? errorMessage,
  }) {
    return LegalConsentState(
      isAgreed: isAgreed ?? this.isAgreed,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isAccepted: isAccepted ?? this.isAccepted,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isAgreed, isSubmitting, isAccepted, errorMessage];
}
