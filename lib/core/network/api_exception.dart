import 'package:dio/dio.dart';

/// Kelas penanganan error jaringan dan respons API terstruktur.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final DioExceptionType? type;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.type,
  });

  /// Factory untuk memetakan DioException ke ApiException dengan pesan yang ramah pengguna.
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException(
          message: 'Koneksi ke server terputus karena timeout. Periksa internet Anda.',
          statusCode: 408,
          type: DioExceptionType.connectionTimeout,
        );

      case DioExceptionType.sendTimeout:
        return const ApiException(
          message: 'Waktu pengiriman data ke server habis. Silakan coba lagi.',
          statusCode: 408,
          type: DioExceptionType.sendTimeout,
        );

      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Server membutuhkan waktu terlalu lama untuk merespons.',
          statusCode: 408,
          type: DioExceptionType.receiveTimeout,
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Sertifikat keamanan server tidak valid.',
          statusCode: 495,
          type: DioExceptionType.badCertificate,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String errorMessage = 'Terjadi kesalahan pada server ($statusCode).';

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('message') &&
              responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('error') &&
              responseData['error'] != null) {
            errorMessage = responseData['error'].toString();
          }
        }

        switch (statusCode) {
          case 400:
            return ApiException(
              message: errorMessage.isNotEmpty ? errorMessage : 'Permintaan data tidak valid (Bad Request).',
              statusCode: 400,
              data: responseData,
              type: error.type,
            );
          case 401:
            return ApiException(
              message: errorMessage.isNotEmpty ? errorMessage : 'Sesi Anda telah berakhir. Silakan login kembali.',
              statusCode: 401,
              data: responseData,
              type: error.type,
            );
          case 403:
            return ApiException(
              message: errorMessage.isNotEmpty ? errorMessage : 'Anda tidak memiliki hak akses untuk aksi ini.',
              statusCode: 403,
              data: responseData,
              type: error.type,
            );
          case 404:
            return ApiException(
              message: errorMessage.isNotEmpty ? errorMessage : 'Layanan atau data yang dicari tidak ditemukan (404).',
              statusCode: 404,
              data: responseData,
              type: error.type,
            );
          case 422:
            return ApiException(
              message: errorMessage.isNotEmpty ? errorMessage : 'Validasi data gagal.',
              statusCode: 422,
              data: responseData,
              type: error.type,
            );
          case 500:
          case 502:
          case 503:
            return ApiException(
              message: errorMessage.isNotEmpty ? errorMessage : 'Terjadi gangguan pada sistem server. Silakan coba beberapa saat lagi.',
              statusCode: statusCode,
              data: responseData,
              type: error.type,
            );
          default:
            return ApiException(
              message: errorMessage,
              statusCode: statusCode,
              data: responseData,
              type: error.type,
            );
        }

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Permintaan dibatalkan.',
          type: DioExceptionType.cancel,
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Tidak dapat terhubung ke server backend. Pastikan server aktif dan koneksi stabil.',
          type: DioExceptionType.connectionError,
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: error.message ?? 'Terjadi kesalahan jaringan yang tidak diketahui.',
          type: DioExceptionType.unknown,
        );
    }
  }

  @override
  String toString() => message;
}
