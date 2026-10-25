import 'package:hris_flutter/features/legal/domain/repositories/legal_consent_repository.dart';

class FakeLegalConsentRepository implements LegalConsentRepository {
  bool accepted;
  bool freshInstall;
  Object? acceptError;
  int acceptCalls = 0;

  FakeLegalConsentRepository({
    this.accepted = false,
    this.freshInstall = false,
    this.acceptError,
  });

  @override
  Future<bool> hasAcceptedCurrentVersion() async => accepted;

  @override
  Future<void> acceptCurrentVersion() async {
    acceptCalls++;
    if (acceptError != null) throw acceptError!;
    accepted = true;
  }

  @override
  Future<bool> isFreshInstall() async => freshInstall;

  @override
  Future<void> markInstalled() async => freshInstall = false;
}
