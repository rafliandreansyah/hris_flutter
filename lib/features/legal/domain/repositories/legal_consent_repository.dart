abstract class LegalConsentRepository {
  /// True bila pengguna sudah menyetujui versi kebijakan yang berlaku di perangkat ini.
  Future<bool> hasAcceptedCurrentVersion();

  Future<void> acceptCurrentVersion();

  /// True pada pembukaan pertama setelah instalasi (data shared_preferences masih kosong).
  Future<bool> isFreshInstall();

  Future<void> markInstalled();
}
