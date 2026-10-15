import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_bloc.dart';

String _token(Map<String, dynamic> payload) {
  String enc(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'none'})}.${enc(payload)}.signature';
}

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);
  final nowSec = now.millisecondsSinceEpoch ~/ 1000;

  test('token dengan exp di masa depan dianggap valid', () {
    final token = _token({'exp': nowSec + 3600});
    expect(AuthBloc.isJwtExpired(token, now: now), isFalse);
  });

  test('token dengan exp di masa lalu dianggap kedaluwarsa', () {
    final token = _token({'exp': nowSec - 60});
    expect(AuthBloc.isJwtExpired(token, now: now), isTrue);
  });

  test('token tanpa claim exp atau format tidak valid tidak dianggap kedaluwarsa', () {
    // Dibiarkan lolos di sisi klien; validitas final tetap diputuskan server.
    expect(AuthBloc.isJwtExpired(_token({'sub': '1'}), now: now), isFalse);
    expect(AuthBloc.isJwtExpired('bukan-jwt', now: now), isFalse);
  });
}
