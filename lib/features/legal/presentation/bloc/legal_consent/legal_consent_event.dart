import 'package:equatable/equatable.dart';

abstract class LegalConsentEvent extends Equatable {
  const LegalConsentEvent();

  @override
  List<Object?> get props => [];
}

/// Checkbox "Saya telah membaca dan menyetujui…" dicentang / dilepas.
class LegalConsentAgreementToggled extends LegalConsentEvent {
  final bool isAgreed;

  const LegalConsentAgreementToggled(this.isAgreed);

  @override
  List<Object?> get props => [isAgreed];
}

/// Tombol "Setuju & Lanjutkan" ditekan.
class LegalConsentAccepted extends LegalConsentEvent {
  const LegalConsentAccepted();
}
