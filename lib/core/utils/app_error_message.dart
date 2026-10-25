import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';

/// Mengubah error teknis menjadi kalimat manusiawi untuk ditampilkan ke pengguna.
///
/// Pesan dari API ([ApiException.message]) dipakai apa adanya karena backend
/// sudah menyesuaikan bahasa pengguna. Error lain tidak boleh dilempar mentah
/// (mis. `LocalAuthException(...)`, `SocketException: ...`).
abstract class AppErrorMessage {
  static const String generic =
      'Terjadi kendala saat memproses permintaan. Silakan coba lagi.';
  static const String noConnection =
      'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.';
  static const String timeout =
      'Server terlalu lama merespons. Silakan coba lagi sebentar lagi.';

  /// Pesan ramah pengguna untuk [error]. Detail teknis hanya dicatat ke log.
  static String from(Object? error, {String? fallback}) {
    if (error is ApiException) {
      return error.message.trim().isNotEmpty ? error.message : (fallback ?? generic);
    }
    if (error is BiometricException) return error.message;
    if (error is SocketException) return noConnection;
    if (error is TimeoutException) return timeout;
    if (error != null) debugPrint('⚠️ [AppErrorMessage] ${error.runtimeType}: $error');
    return fallback ?? generic;
  }
}
