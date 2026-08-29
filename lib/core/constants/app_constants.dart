/// Konstanta global aplikasi (Timeout durasi, Storage keys, Header constants).
abstract class AppConstants {
  // --- Network Timeouts ---
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // --- Storage & Cache Keys ---
  static const String accessTokenKey = 'muratech_access_token';
  static const String refreshTokenKey = 'muratech_refresh_token';
  static const String userProfileKey = 'muratech_user_profile';
  static const String themeModeKey = 'muratech_theme_mode';

  // --- HTTP Headers ---
  static const String headerAuthorization = 'Authorization';
  static const String headerBearerPrefix = 'Bearer ';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String jsonContentType = 'application/json';
}
