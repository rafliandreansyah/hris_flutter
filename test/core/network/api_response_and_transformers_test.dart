import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/network/api_response.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';

class _SearchEvent {
  final String query;
  const _SearchEvent(this.query);
}

class _SearchBloc extends Bloc<_SearchEvent, List<String>> {
  _SearchBloc(EventTransformer<_SearchEvent> transformer) : super(const []) {
    on<_SearchEvent>((event, emit) {
      emit([...state, event.query]);
    }, transformer: transformer);
  }
}

void main() {
  group('ApiResponse.fromJson', () {
    test('mem-parse success, message, data, errors, dan meta', () {
      final response = ApiResponse<Map<String, dynamic>>.fromJson({
        'success': true,
        'message': 'OK',
        'data': {'id': 1},
        'meta': {'page': 1},
      }, null);

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(response.data, {'id': 1});
      expect(response.meta, {'page': 1});
      expect(response.errors, isNull);
    });

    test('memakai fromJsonT untuk mengubah data', () {
      final response = ApiResponse<int>.fromJson({
        'success': true,
        'data': '42',
      }, (raw) => int.parse(raw as String));

      expect(response.data, 42);
    });

    test('success dianggap true bila tidak ada "success" dan tidak ada "error"', () {
      expect(ApiResponse<dynamic>.fromJson({}, null).success, isTrue);
      expect(
        ApiResponse<dynamic>.fromJson({'error': 'boom'}, null).success,
        isFalse,
      );
    });

    test('errors fallback ke "error" dan meta fallback ke "pagination"', () {
      final response = ApiResponse<dynamic>.fromJson({
        'success': false,
        'error': 'bad',
        'pagination': {'total': 9},
      }, null);

      expect(response.errors, 'bad');
      expect(response.meta, {'total': 9});
      expect(response.data, isNull);
    });
  });

  group('ApiException.fromDioException', () {
    DioException dio(DioExceptionType type, {int? status, dynamic data}) {
      final options = RequestOptions(path: '/x');
      return DioException(
        requestOptions: options,
        type: type,
        response: status == null
            ? null
            : Response(requestOptions: options, statusCode: status, data: data),
      );
    }

    test('timeout (connect/send/receive) memakai statusCode 408', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = ApiException.fromDioException(dio(type));
        expect(e.statusCode, 408, reason: '$type');
        expect(e.type, type);
        expect(e.message, isNotEmpty);
      }
    });

    for (final status in [400, 401, 403, 404, 409, 422, 500, 502, 503]) {
      test('badResponse $status mengambil pesan dari backend', () {
        final e = ApiException.fromDioException(
          dio(
            DioExceptionType.badResponse,
            status: status,
            data: {'message': 'Pesan backend $status'},
          ),
        );

        expect(e.statusCode, status);
        expect(e.message, contains('Pesan backend $status'));
      });
    }

    test('badResponse tanpa message backend tetap menghasilkan pesan non-kosong', () {
      final e = ApiException.fromDioException(
        dio(DioExceptionType.badResponse, status: 500, data: null),
      );

      expect(e.statusCode, 500);
      expect(e.message, isNotEmpty);
    });

    test('cancel, badCertificate, connectionError, unknown menghasilkan pesan', () {
      for (final type in [
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.connectionError,
        DioExceptionType.unknown,
      ]) {
        final e = ApiException.fromDioException(dio(type));
        expect(e.message, isNotEmpty, reason: '$type');
        expect(e.type, type);
      }
    });
  });

  group('bloc_transformers', () {
    test('debounceRestartable hanya memproses event terakhir dalam jendela debounce', () {
      fakeAsync((async) {
        final bloc = _SearchBloc(
          debounceRestartable(const Duration(milliseconds: 300)),
        );

        bloc.add(const _SearchEvent('a'));
        async.elapse(const Duration(milliseconds: 100));
        bloc.add(const _SearchEvent('ab'));
        async.elapse(const Duration(milliseconds: 100));
        bloc.add(const _SearchEvent('abc'));
        async.elapse(const Duration(milliseconds: 299));
        expect(bloc.state, isEmpty, reason: 'Belum lewat durasi debounce');

        async.elapse(const Duration(milliseconds: 5));
        expect(bloc.state, ['abc']);

        bloc.close();
      });
    });

    test('debounceRestartable memproses event terpisah jauh satu per satu', () {
      fakeAsync((async) {
        final bloc = _SearchBloc(
          debounceRestartable(const Duration(milliseconds: 300)),
        );

        bloc.add(const _SearchEvent('x'));
        async.elapse(const Duration(milliseconds: 400));
        bloc.add(const _SearchEvent('y'));
        async.elapse(const Duration(milliseconds: 400));

        expect(bloc.state, ['x', 'y']);
        bloc.close();
      });
    });

    test('debounceSequential juga hanya memproses event terakhir setelah debounce', () {
      fakeAsync((async) {
        final bloc = _SearchBloc(
          debounceSequential(const Duration(milliseconds: 200)),
        );

        bloc.add(const _SearchEvent('k'));
        async.elapse(const Duration(milliseconds: 50));
        bloc.add(const _SearchEvent('kl'));
        async.elapse(const Duration(milliseconds: 250));

        expect(bloc.state, ['kl']);
        bloc.close();
      });
    });
  });
}
