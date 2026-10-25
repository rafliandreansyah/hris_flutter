import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';
import 'package:hris_flutter/core/utils/app_error_message.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  group('AppErrorMessage.from', () {
    test('pesan API dipakai apa adanya', () {
      expect(
        AppErrorMessage.from(const ApiException(message: 'Data tidak ditemukan', statusCode: 404)),
        'Data tidak ditemukan',
      );
    });

    test('error teknis tidak pernah bocor ke pengguna', () {
      final raw = Exception('LocalAuthException(code noCredentialsSet, null, null)');
      final msg = AppErrorMessage.from(raw);
      expect(msg, AppErrorMessage.generic);
      expect(msg, isNot(contains('Exception')));
      expect(AppErrorMessage.from(const FormatException('bad json')), AppErrorMessage.generic);
    });

    test('jaringan & timeout punya pesan khusus', () {
      expect(AppErrorMessage.from(const SocketException('x')), AppErrorMessage.noConnection);
      expect(AppErrorMessage.from(TimeoutException('x')), AppErrorMessage.timeout);
    });

    test('fallback kustom dipakai untuk error tak dikenal', () {
      expect(AppErrorMessage.from(StateError('x'), fallback: 'Foto gagal diambil.'), 'Foto gagal diambil.');
    });
  });

  group('BiometricService.handleLocalAuthCode', () {
    test('kunci layar belum diatur -> pesan manusiawi NOT_ENROLLED', () {
      for (final code in [
        LocalAuthExceptionCode.noCredentialsSet,
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noBiometricHardware,
      ]) {
        expect(
          () => BiometricService.handleLocalAuthCode(code),
          throwsA(
            isA<BiometricException>()
                .having((e) => e.code, 'code', 'NOT_ENROLLED')
                .having((e) => e.message, 'message', contains('Kunci layar')),
          ),
        );
      }
    });

    test('terkunci -> LOCKED_OUT', () {
      expect(
        () => BiometricService.handleLocalAuthCode(LocalAuthExceptionCode.temporaryLockout),
        throwsA(isA<BiometricException>().having((e) => e.code, 'code', 'LOCKED_OUT')),
      );
    });

    test('dibatalkan pengguna/sistem -> false tanpa error', () {
      expect(BiometricService.handleLocalAuthCode(LocalAuthExceptionCode.userCanceled), isFalse);
      expect(BiometricService.handleLocalAuthCode(LocalAuthExceptionCode.systemCanceled), isFalse);
    });

    test('kode lain -> pesan generik tanpa teks teknis', () {
      expect(
        () => BiometricService.handleLocalAuthCode(LocalAuthExceptionCode.uiUnavailable),
        throwsA(
          isA<BiometricException>().having((e) => e.message, 'message', isNot(contains('LocalAuthException'))),
        ),
      );
    });
  });
}
