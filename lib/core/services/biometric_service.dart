import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Pengecualian khusus untuk kegagalan autentikasi biometrik.
class BiometricException implements Exception {
  final String message;
  final String? code;

  const BiometricException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service terpusat untuk mengelola autentikasi biometrik (Sidik Jari / Face ID).
class BiometricService {
  static BiometricService _instance = BiometricService._internal();
  static BiometricService get instance => _instance;

  final LocalAuthentication _auth;

  /// Hook pengujian unit test untuk menyimulasikan hasil autentikasi
  @visibleForTesting
  static Future<bool> Function({String localizedReason})? testAuthenticateHandler;

  @visibleForTesting
  static Future<bool> Function()? testCanAuthenticateHandler;

  @visibleForTesting
  static void setMockInstance(BiometricService mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = BiometricService._internal();
  }

  factory BiometricService({LocalAuthentication? auth}) {
    if (auth != null) {
      return BiometricService._internal(auth: auth);
    }
    return _instance;
  }

  BiometricService._internal({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Memeriksa apakah perangkat mendukung sensor biometrik dan sudah dikonfigurasi oleh pengguna
  Future<bool> canAuthenticate() async {
    if (testCanAuthenticateHandler != null) {
      return await testCanAuthenticateHandler!();
    }
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      debugPrint('⚠️ [BiometricService.canAuthenticate] $e');
      return false;
    }
  }

  /// Mengambil jenis biometrik yang terpasang di perangkat (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('⚠️ [BiometricService.getAvailableBiometrics] $e');
      return [];
    }
  }

  /// Melakukan pemindaian biometrik lokal pada perangkat pengguna.
  /// Mengembalikan `true` jika verifikasi berhasil, `false` jika dibatalkan oleh pengguna.
  /// Melempar `BiometricException` jika perangkat tidak mendukung atau terjadi kesalahan platform.
  Future<bool> authenticate({
    String localizedReason = 'Pindai sidik jari atau wajah Anda untuk konfirmasi presensi',
  }) async {
    if (testAuthenticateHandler != null) {
      return await testAuthenticateHandler!(localizedReason: localizedReason);
    }

    try {
      final isSupported = await canAuthenticate();
      if (!isSupported) {
        throw const BiometricException(
          'Perangkat tidak mendukung biometrik atau belum ada sidik jari/wajah yang didaftarkan.',
          code: 'NOT_AVAILABLE',
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('⚠️ [BiometricService.authenticate PlatformException] code: ${e.code}, msg: ${e.message}');
      if (e.code == 'NotAvailable' || e.code == 'PasscodeNotSet') {
        throw const BiometricException(
          'Biometrik belum diaktifkan pada perangkat Anda. Silakan atur di Pengaturan perangkat.',
          code: 'NOT_ENROLLED',
        );
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        throw const BiometricException(
          'Sensor biometrik terkunci karena terlalu banyak percobaan gagal. Silakan coba beberapa saat lagi.',
          code: 'LOCKED_OUT',
        );
      }
      throw BiometricException(
        e.message ?? 'Verifikasi biometrik gagal.',
        code: e.code,
      );
    } catch (e) {
      if (e is BiometricException) rethrow;
      throw BiometricException(e.toString());
    }
  }
}
