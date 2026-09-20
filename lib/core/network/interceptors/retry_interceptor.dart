import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor cerdas untuk melakukan retry otomatis pada kegagalan koneksi atau timeout
/// pada permintaan HTTP idempoten (khususnya GET) dengan exponential backoff.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
    ],
  });

  static const String retryCountKey = 'x_retry_count';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // 1. Validasi apakah request memenuhi syarat untuk di-retry
    if (!_shouldRetry(err, requestOptions)) {
      handler.next(err);
      return;
    }

    final currentRetryCount =
        (requestOptions.extra[retryCountKey] as int?) ?? 0;

    if (currentRetryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final nextRetryCount = currentRetryCount + 1;
    final delayIndex = (nextRetryCount - 1).clamp(0, retryDelays.length - 1);
    final delay = retryDelays[delayIndex];

    debugPrint(
      '🔄 [RetryInterceptor] Retrying ${requestOptions.method} ${requestOptions.uri.path} '
      '(Attempt $nextRetryCount of $maxRetries after ${delay.inSeconds}s)...',
    );

    await Future.delayed(delay);

    try {
      final newOptions = Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        extra: Map<String, dynamic>.from(requestOptions.extra)
          ..[retryCountKey] = nextRetryCount,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
      );

      final response = await dio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: newOptions,
        cancelToken: requestOptions.cancelToken,
        onReceiveProgress: requestOptions.onReceiveProgress,
        onSendProgress: requestOptions.onSendProgress,
      );

      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (e) {
      handler.next(err);
    }
  }

  /// Menentukan apakah error layak untuk dilakukan retry
  bool _shouldRetry(DioException err, RequestOptions options) {
    // Hanya retry untuk metode idempoten (GET, HEAD, OPTIONS)
    final method = options.method.toUpperCase();
    final isIdempotent = method == 'GET' || method == 'HEAD' || method == 'OPTIONS';
    if (!isIdempotent) return false;

    // Jangan retry jika request dibatalkan oleh pengguna (CancelToken)
    if (err.type == DioExceptionType.cancel) return false;

    // Retry pada timeout jaringan atau kegagalan koneksi socket
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // SocketException / Network unreachable
    if (err.error is SocketException) {
      return true;
    }

    // Server sementara tidak tersedia (502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout)
    final statusCode = err.response?.statusCode;
    if (statusCode != null && (statusCode == 502 || statusCode == 503 || statusCode == 504)) {
      return true;
    }

    return false;
  }
}
