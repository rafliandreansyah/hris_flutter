import 'package:hris_flutter/core/constants/legal_links.dart';
import 'package:hris_flutter/features/legal/data/datasources/legal_consent_local_datasource.dart';
import 'package:hris_flutter/features/legal/domain/repositories/legal_consent_repository.dart';

class LegalConsentRepositoryImpl implements LegalConsentRepository {
  final LegalConsentLocalDatasource _localDatasource;
  final String currentVersion;
  final DateTime Function() _now;

  LegalConsentRepositoryImpl({
    LegalConsentLocalDatasource? localDatasource,
    this.currentVersion = LegalLinks.consentVersion,
    DateTime Function()? now,
  })  : _localDatasource = localDatasource ?? LegalConsentLocalDatasource(),
        _now = now ?? DateTime.now;

  @override
  Future<bool> hasAcceptedCurrentVersion() async {
    return await _localDatasource.getAcceptedVersion() == currentVersion;
  }

  @override
  Future<void> acceptCurrentVersion() {
    return _localDatasource.saveAcceptance(
      version: currentVersion,
      acceptedAt: _now(),
    );
  }

  @override
  Future<bool> isFreshInstall() async {
    return !await _localDatasource.hasInstallMarker();
  }

  @override
  Future<void> markInstalled() => _localDatasource.saveInstallMarker();
}
