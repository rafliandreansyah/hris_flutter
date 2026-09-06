import 'package:url_launcher/url_launcher.dart';

/// Konfigurasi terpusat untuk Google Maps pada Oasish HRIS.
///
/// Tempat memasukkan Google Maps API Key Anda:
/// 1. Masukkan API Key Anda pada variabel [googleMapsApiKey] di bawah ini.
/// 2. Masukkan juga API Key yang sama pada:
///    - **Android**: `android/app/src/main/AndroidManifest.xml`
///      `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_MAPS_API_KEY"/>`
///    - **iOS**: `ios/Runner/AppDelegate.swift`
///      `GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")`
class MapsConfig {
  /// Masukkan Google Maps API Key Anda di sini
  /// Dapatkan API Key melalui Google Cloud Console:
  /// https://console.cloud.google.com/google/maps-apis/overview
  static const String googleMapsApiKey =
      'AIzaSyAxluVQ5yX2bwyqDMxXRP066Q5xgxk83vQ';

  /// Memeriksa apakah API Key telah dikonfigurasi (bukan default placeholder)
  static bool get isApiKeyConfigured =>
      googleMapsApiKey.isNotEmpty &&
      googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Koordinat default (SCBD Tower Jakarta)
  static const double defaultLatitude = -6.2253;
  static const double defaultLongitude = 106.8097;
  static const double defaultZoom = 15.0;

  /// Membuka lokasi pada aplikasi Google Maps atau browser
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? queryLabel,
  }) async {
    final label = queryLabel != null ? Uri.encodeComponent(queryLabel) : '';
    final url = Uri.parse(
      label.isNotEmpty
          ? 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude($label)'
          : 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
