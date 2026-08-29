import 'package:dio/dio.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';

/// Interceptor untuk menyisipkan Bearer token autentikasi pada setiap permintaan HTTP
/// dan mendeteksi respons 401 Unauthorized.
class AuthInterceptor extends Interceptor {
  String? _accessToken;
  final void Function()? onUnauthorized;

  AuthInterceptor({this.onUnauthorized});

  /// Memperbarui token autentikasi yang sedang aktif
  void setToken(String? token) {
    _accessToken = token;
  }

  /// Menghapus token saat logout
  void clearToken() {
    _accessToken = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      options.headers[AppConstants.headerAuthorization] =
          '${AppConstants.headerBearerPrefix}$_accessToken';
    }
    options.headers[AppConstants.headerContentType] = AppConstants.jsonContentType;
    options.headers[AppConstants.headerAccept] = AppConstants.jsonContentType;

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
