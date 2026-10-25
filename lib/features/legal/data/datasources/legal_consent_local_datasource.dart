import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan persetujuan Kebijakan Privasi di perangkat.
/// Sengaja memakai shared_preferences (bukan secure storage): tidak ikut terhapus saat logout,
/// tetapi hilang saat aplikasi di-uninstall sehingga persetujuan diminta lagi setelah reinstall.
class LegalConsentLocalDatasource {
  static const String acceptedVersionKey = 'legal_consent_accepted_version';
  static const String acceptedAtKey = 'legal_consent_accepted_at';
  static const String installMarkerKey = 'app_install_marker';

  Future<String?> getAcceptedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(acceptedVersionKey);
  }

  Future<void> saveAcceptance({
    required String version,
    required DateTime acceptedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(acceptedVersionKey, version);
    await prefs.setString(acceptedAtKey, acceptedAt.toUtc().toIso8601String());
  }

  Future<bool> hasInstallMarker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(installMarkerKey) ?? false;
  }

  Future<void> saveInstallMarker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(installMarkerKey, true);
  }
}
