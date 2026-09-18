import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:hris_flutter/core/network/alice_service.dart';
import 'package:hris_flutter/core/network/interceptors/logging_interceptor.dart';

/// Model hasil representasi reverse geocoding dari Mapbox Places API v5
class MapboxGeocodingResult {
  /// Alamat lengkap terformat (misal: "Jl. Jend. Sudirman Kav. 52-53, Jakarta Selatan, DKI Jakarta 12190, Indonesia")
  final String placeName;

  /// Nama tempat / venue / POI atau jalan utama (misal: "SCBD Tower" atau "Jl. Jend. Sudirman")
  final String locationName;

  /// Koordinat latitude yang di-query
  final double latitude;

  /// Koordinat longitude yang di-query
  final double longitude;

  /// Daftar konteks hirarki wilayah (kelurahan, kecamatan, kota, provinsi, kode pos, negara)
  final List<Map<String, dynamic>> context;

  /// Raw JSON dari fitur pertama Mapbox
  final Map<String, dynamic> rawFeature;

  const MapboxGeocodingResult({
    required this.placeName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.context = const [],
    this.rawFeature = const {},
  });

  /// Factory constructor untuk mem-parse JSON FeatureCollection dari Mapbox
  factory MapboxGeocodingResult.fromJson(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
  }) {
    final features = json['features'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      final fallbackCoord =
          'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      return MapboxGeocodingResult(
        placeName: fallbackCoord,
        locationName: fallbackCoord,
        latitude: latitude,
        longitude: longitude,
      );
    }

    final firstFeature = features.first as Map<String, dynamic>;
    final placeName = firstFeature['place_name']?.toString().trim() ?? '';
    final text = firstFeature['text']?.toString().trim() ?? '';

    // Nama lokasi: prioritaskan text POI/jalan, jika kosong ambil bagian pertama sebelum koma
    final locationName = text.isNotEmpty
        ? text
        : (placeName.contains(',') ? placeName.split(',').first.trim() : placeName);

    final contextList = (firstFeature['context'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];

    return MapboxGeocodingResult(
      placeName: placeName.isNotEmpty
          ? placeName
          : 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
      locationName: locationName.isNotEmpty ? locationName : 'Lokasi Terdeteksi',
      latitude: latitude,
      longitude: longitude,
      context: contextList,
      rawFeature: firstFeature,
    );
  }

  @override
  String toString() =>
      'MapboxGeocodingResult(locationName: $locationName, placeName: $placeName, lat: $latitude, lng: $longitude)';
}

/// Utility mandiri untuk Geocoding dan Reverse Geocoding menggunakan Mapbox Places API v5.
///
/// Utility ini berjalan menggunakan instance [Dio] independen tanpa interceptor otentikasi HRIS
/// guna menghindari kebocoran token internal serta mencegah dampak auto-logout 401.
/// Dilengkapi dengan [AliceService] dan [LoggingInterceptor] saat [kDebugMode] untuk inspeksi jaringan.
abstract class MapboxGeocodingUtil {
  static Dio? _defaultDio;

  @visibleForTesting
  static void setMockDio(Dio? mockDio) {
    _defaultDio = mockDio;
  }

  @visibleForTesting
  static Dio get rawDio => _dio;

  static Dio get _dio {
    if (_defaultDio == null) {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          responseType: ResponseType.json,
        ),
      );

      // HTTP Inspector (Alice) & Logging saat mode Debug
      if (kDebugMode) {
        dio.interceptors.add(AliceService.instance.dioAdapter);
        dio.interceptors.add(LoggingInterceptor.instance);
      }

      _defaultDio = dio;
    }
    return _defaultDio!;
  }

  /// Melakukan reverse geocoding dari koordinat GPS ([latitude], [longitude]) menjadi objek [MapboxGeocodingResult].
  ///
  /// Mengembalikan `null` jika terjadi kesalahan jaringan atau jika token tidak tersedia dan request gagal.
  static Future<MapboxGeocodingResult?> reverseGeocode({
    required double latitude,
    required double longitude,
    String? accessToken,
    Dio? dio,
  }) async {
    final client = dio ?? _dio;
    final token = (accessToken != null && accessToken.isNotEmpty)
        ? accessToken
        : MapsConfig.mapboxAccessToken;

    if (token.isEmpty) {
      debugPrint('[MapboxGeocodingUtil] Warning: Mapbox Access Token is empty.');
      return null;
    }

    try {
      // Endpoint Mapbox v5: {longitude},{latitude}.json
      final url = '${MapsConfig.mapboxGeocodingBaseUrl}/$longitude,$latitude.json';

      final response = await client.get<Map<String, dynamic>>(
        url,
        queryParameters: {
          'access_token': token,
          'types': 'poi,address,neighborhood,locality,place',
          'language': 'id,en',
          'limit': 1,
        },
      );

      final data = response.data;
      if (data != null) {
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          return MapboxGeocodingResult.fromJson(
            data,
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('[MapboxGeocodingUtil] Reverse geocoding failed: $e');
      return null;
    }
  }

  /// Mengambil string alamat lengkap terformat dari koordinat GPS ([latitude], [longitude]).
  ///
  /// Mengembalikan string alamat jika berhasil, atau `null` jika reverse geocode gagal.
  static Future<String?> reverseGeocodeAddress({
    required double latitude,
    required double longitude,
    String? accessToken,
    Dio? dio,
  }) async {
    final result = await reverseGeocode(
      latitude: latitude,
      longitude: longitude,
      accessToken: accessToken,
      dio: dio,
    );
    return result?.placeName;
  }

  /// Mengambil string alamat lengkap terformat secara aman (Safe Address).
  ///
  /// Jika reverse geocoding via Mapbox berhasil, mengembalikan [MapboxGeocodingResult.placeName].
  /// Jika terjadi kegagalan jaringan atau offline, mengembalikan fallback koordinat
  /// `Lat: -6.123456, Lng: 106.123456` sehingga pengiriman data ke server backend
  /// tidak terhambat karena kolom alamat backend bersifat wajib.
  static Future<String> getSafeAddress({
    required double latitude,
    required double longitude,
    String? accessToken,
    Dio? dio,
  }) async {
    final address = await reverseGeocodeAddress(
      latitude: latitude,
      longitude: longitude,
      accessToken: accessToken,
      dio: dio,
    );

    if (address != null && address.trim().isNotEmpty) {
      return address.trim();
    }

    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }
}
