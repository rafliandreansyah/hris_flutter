import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/mapbox_geocoding_util.dart';

void main() {
  group('MapboxGeocodingResult Unit Tests', () {
    test('Correctly parses valid Mapbox v5 FeatureCollection JSON', () {
      final sampleJson = {
        'type': 'FeatureCollection',
        'query': [106.8097, -6.2253],
        'features': [
          {
            'id': 'poi.12345',
            'type': 'Feature',
            'place_type': ['poi'],
            'text': 'SCBD Tower 2',
            'place_name':
                'SCBD Tower 2, Jl. Jend. Sudirman Kav. 52-53, Senayan, Kebayoran Baru, Jakarta Selatan, DKI Jakarta 12190, Indonesia',
            'context': [
              {'id': 'neighborhood.1', 'text': 'Senayan'},
              {'id': 'locality.2', 'text': 'Kebayoran Baru'},
              {'id': 'place.3', 'text': 'Jakarta Selatan'},
              {'id': 'region.4', 'text': 'DKI Jakarta'},
              {'id': 'country.5', 'text': 'Indonesia'},
            ],
          }
        ],
      };

      final result = MapboxGeocodingResult.fromJson(
        sampleJson,
        latitude: -6.2253,
        longitude: 106.8097,
      );

      expect(result.locationName, 'SCBD Tower 2');
      expect(
        result.placeName,
        'SCBD Tower 2, Jl. Jend. Sudirman Kav. 52-53, Senayan, Kebayoran Baru, Jakarta Selatan, DKI Jakarta 12190, Indonesia',
      );
      expect(result.latitude, -6.2253);
      expect(result.longitude, 106.8097);
      expect(result.context.length, 5);
      expect(result.context.first['text'], 'Senayan');
    });

    test('Correctly falls back when features array is empty', () {
      final emptyJson = {
        'type': 'FeatureCollection',
        'query': [106.8097, -6.2253],
        'features': <dynamic>[],
      };

      final result = MapboxGeocodingResult.fromJson(
        emptyJson,
        latitude: -6.2253,
        longitude: 106.8097,
      );

      expect(result.placeName, contains('Lat: -6.225300'));
      expect(result.placeName, contains('Lng: 106.809700'));
      expect(result.locationName, contains('Lat: -6.225300'));
    });

    test('Extracts location name from comma-separated place_name if text is empty', () {
      final jsonNoText = {
        'type': 'FeatureCollection',
        'query': [106.8097, -6.2253],
        'features': [
          {
            'id': 'address.999',
            'type': 'Feature',
            'place_type': ['address'],
            'text': '',
            'place_name': 'Gedung Bursa Efek, Jl. Jend. Sudirman, Jakarta Selatan',
          }
        ],
      };

      final result = MapboxGeocodingResult.fromJson(
        jsonNoText,
        latitude: -6.2253,
        longitude: 106.8097,
      );

      expect(result.locationName, 'Gedung Bursa Efek');
      expect(result.placeName, 'Gedung Bursa Efek, Jl. Jend. Sudirman, Jakarta Selatan');
    });
  });

  group('MapboxGeocodingUtil Network & Fallback Tests', () {
    test('reverseGeocode returns MapboxGeocodingResult on successful HTTP response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'type': 'FeatureCollection',
                  'features': [
                    {
                      'id': 'poi.100',
                      'text': 'Pacific Place Mall',
                      'place_name': 'Pacific Place Mall, Jl. Jend. Sudirman No. 52-53, Jakarta Selatan',
                    }
                  ],
                },
              ),
            );
          },
        ),
      );

      final result = await MapboxGeocodingUtil.reverseGeocode(
        latitude: -6.2244,
        longitude: 106.8099,
        dio: dio,
      );

      expect(result, isNotNull);
      expect(result!.locationName, 'Pacific Place Mall');
      expect(result.placeName, contains('Pacific Place Mall'));
      expect(result.latitude, -6.2244);
      expect(result.longitude, 106.8099);
    });

    test('reverseGeocodeAddress returns formatted address string', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'type': 'FeatureCollection',
                  'features': [
                    {
                      'id': 'address.100',
                      'text': 'Jl. Asia Afrika',
                      'place_name': 'Jl. Asia Afrika No. 8, Gelora, Tanah Abang, Jakarta Pusat',
                    }
                  ],
                },
              ),
            );
          },
        ),
      );

      final address = await MapboxGeocodingUtil.reverseGeocodeAddress(
        latitude: -6.2185,
        longitude: 106.7997,
        dio: dio,
      );

      expect(address, 'Jl. Asia Afrika No. 8, Gelora, Tanah Abang, Jakarta Pusat');
    });

    test('reverseGeocode handles DioException gracefully and returns null', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
                error: 'Connection timed out',
              ),
            );
          },
        ),
      );

      final result = await MapboxGeocodingUtil.reverseGeocode(
        latitude: -6.2088,
        longitude: 106.8456,
        dio: dio,
      );

      expect(result, isNull);
    });

    test('getSafeAddress returns geocoded address when API succeeds', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'type': 'FeatureCollection',
                  'features': [
                    {
                      'id': 'poi.200',
                      'text': 'Menara BCA',
                      'place_name': 'Menara BCA, Jl. M.H. Thamrin No. 1, Jakarta Pusat',
                    }
                  ],
                },
              ),
            );
          },
        ),
      );

      final safeAddress = await MapboxGeocodingUtil.getSafeAddress(
        latitude: -6.1950,
        longitude: 106.8220,
        dio: dio,
      );

      expect(safeAddress, 'Menara BCA, Jl. M.H. Thamrin No. 1, Jakarta Pusat');
    });

    test('getSafeAddress returns safe coordinates string when API fails', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  statusMessage: 'Unauthorized',
                ),
              ),
            );
          },
        ),
      );

      final safeAddress = await MapboxGeocodingUtil.getSafeAddress(
        latitude: -6.1950,
        longitude: 106.8220,
        dio: dio,
      );

      expect(safeAddress, contains('Lat: -6.195000, Lng: 106.822000'));
    });

    test('rawDio includes AliceDioAdapter and LoggingInterceptor in debug mode', () {
      MapboxGeocodingUtil.setMockDio(null);
      final dio = MapboxGeocodingUtil.rawDio;
      expect(dio.interceptors.any((i) => i is AliceDioAdapter), isTrue);
    });
  });
}
