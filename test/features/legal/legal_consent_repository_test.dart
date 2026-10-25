import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/legal/data/datasources/legal_consent_local_datasource.dart';
import 'package:hris_flutter/features/legal/data/repositories/legal_consent_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LegalConsentRepositoryImpl', () {
    test('belum pernah setuju -> hasAcceptedCurrentVersion false', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LegalConsentRepositoryImpl(currentVersion: 'v2');

      expect(await repo.hasAcceptedCurrentVersion(), isFalse);
    });

    test('acceptCurrentVersion menyimpan versi & waktu persetujuan', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LegalConsentRepositoryImpl(
        currentVersion: 'v2',
        now: () => DateTime.utc(2026, 10, 25, 8),
      );

      await repo.acceptCurrentVersion();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LegalConsentLocalDatasource.acceptedVersionKey), 'v2');
      expect(prefs.getString(LegalConsentLocalDatasource.acceptedAtKey),
          '2026-10-25T08:00:00.000Z');
      expect(await repo.hasAcceptedCurrentVersion(), isTrue);
    });

    test('versi kebijakan naik -> persetujuan lama tidak berlaku', () async {
      SharedPreferences.setMockInitialValues({
        LegalConsentLocalDatasource.acceptedVersionKey: 'v1',
      });
      final repo = LegalConsentRepositoryImpl(currentVersion: 'v2');

      expect(await repo.hasAcceptedCurrentVersion(), isFalse);
    });

    test('penanda instalasi: fresh install sampai markInstalled dipanggil', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LegalConsentRepositoryImpl();

      expect(await repo.isFreshInstall(), isTrue);
      await repo.markInstalled();
      expect(await repo.isFreshInstall(), isFalse);
    });
  });
}
