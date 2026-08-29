import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/network/interceptors/auth_interceptor.dart';
import 'package:hris_flutter/core/network/interceptors/logging_interceptor.dart';

/// Client jaringan utama berbasis Dio untuk mengelola semua HTTP request ke backend Muratech HRIS.
class ApiClient {
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  /// Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;
  factory ApiClient() => _instance;

  ApiClient._internal() {
    final baseOptions = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      headers: {
        AppConstants.headerContentType: AppConstants.jsonContentType,
        AppConstants.headerAccept: AppConstants.jsonContentType,
      },
      responseType: ResponseType.json,
    );

    _dio = Dio(baseOptions);
    _authInterceptor = AuthInterceptor();

    _dio.interceptors.add(_authInterceptor);

    // Logging hanya aktif saat mode Debug
    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor.instance);
    }
  }

  /// Mengambil instance Dio mentah jika diperlukan konfigurasi khusus
  Dio get dio => _dio;

  /// Mengatur token autentikasi global
  void setAuthToken(String? token) {
    _authInterceptor.setToken(token);
  }

  /// Menghapus token saat user logout
  void clearAuthToken() {
    _authInterceptor.clearToken();
  }

  // ==========================================
  // --- 🌐 HTTP METHODS WRAPPERS ---
  // ==========================================

  /// HTTP GET Request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// HTTP POST Request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// HTTP PUT Request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// HTTP PATCH Request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// HTTP DELETE Request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
