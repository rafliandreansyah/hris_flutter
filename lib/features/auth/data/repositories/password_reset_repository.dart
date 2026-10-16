import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_client.dart';
import 'package:hris_flutter/core/network/api_exception.dart';

/// Permintaan reset password (lupa kata sandi) ke `POST /auth/reset-password`.
abstract class PasswordResetRepository {
  /// Mengirim tautan reset ke [email]. Mengembalikan pesan sukses dari backend.
  ///
  /// Melempar [ApiException] (dengan `message` dan `statusCode` dari API) saat gagal.
  Future<String> requestPasswordReset(String email);
}

class PasswordResetRepositoryImpl implements PasswordResetRepository {
  final ApiClient _apiClient;

  PasswordResetRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  static const _defaultSuccessMessage =
      'Tautan reset kata sandi telah dikirim ke email Anda.';

  @override
  Future<String> requestPasswordReset(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {'email': email.trim()},
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      if (raw['success'] == false) {
        throw ApiException(
          message: raw['message']?.toString() ?? 'Gagal mengirim tautan reset.',
          statusCode: response.statusCode,
        );
      }
      final message = raw['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
    }
    return _defaultSuccessMessage;
  }
}
