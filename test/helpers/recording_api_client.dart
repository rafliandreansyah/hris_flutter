import 'package:dio/dio.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';

/// Satu panggilan HTTP yang direkam oleh [RecordingApiClient].
class RecordedCall {
  final String method;
  final String path;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;

  const RecordedCall(this.method, this.path, this.data, this.queryParameters);
}

/// Fake [ApiClient] yang merekam method, path, query & body, dan melempar
/// [ApiException] (perilaku ApiClient asli: DioException selalu dikonversi).
class RecordingApiClient implements ApiClient {
  final List<RecordedCall> calls = [];

  /// Body respons yang dikembalikan untuk setiap request.
  dynamic responseData;

  /// Bila diisi, setiap request melempar error ini.
  ApiException? errorToThrow;

  RecordedCall get last => calls.last;

  Future<Response<T>> _handle<T>(
    String method,
    String path,
    dynamic data,
    Map<String, dynamic>? query,
  ) async {
    calls.add(RecordedCall(method, path, data, query));
    if (errorToThrow != null) throw errorToThrow!;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: responseData as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _handle<T>('GET', path, null, queryParameters);

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _handle<T>('POST', path, data, queryParameters);

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _handle<T>('PUT', path, data, queryParameters);

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _handle<T>('PATCH', path, data, queryParameters);

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _handle<T>('DELETE', path, data, queryParameters);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
