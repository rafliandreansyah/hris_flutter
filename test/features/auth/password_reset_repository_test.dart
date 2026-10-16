import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/auth/data/repositories/password_reset_repository.dart';

import '../../helpers/recording_api_client.dart';

void main() {
  late RecordingApiClient api;
  late PasswordResetRepositoryImpl repository;

  setUp(() {
    api = RecordingApiClient();
    repository = PasswordResetRepositoryImpl(apiClient: api);
  });

  test('mengirim POST /auth/reset-password dengan email ter-trim', () async {
    api.responseData = {'success': true, 'message': 'Email terkirim'};

    final message = await repository.requestPasswordReset('  user@oasish.com ');

    expect(api.last.method, 'POST');
    expect(api.last.path, ApiEndpoints.resetPassword);
    expect(api.last.data, {'email': 'user@oasish.com'});
    expect(message, 'Email terkirim');
  });

  test('memakai pesan default bila backend tidak mengirim message', () async {
    api.responseData = {'success': true};

    final message = await repository.requestPasswordReset('a@b.com');

    expect(message, contains('reset kata sandi'));
  });

  test('success=false melempar ApiException berpesan backend', () async {
    api.responseData = {'success': false, 'message': 'Email tidak terdaftar'};

    await expectLater(
      repository.requestPasswordReset('x@y.com'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Email tidak terdaftar',
        ),
      ),
    );
  });

  test('ApiException dari ApiClient (mis. 429) diteruskan utuh', () async {
    api.errorToThrow = const ApiException(
      message: 'Terlalu banyak percobaan',
      statusCode: 429,
    );

    await expectLater(
      repository.requestPasswordReset('x@y.com'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.message, 'message', 'Terlalu banyak percobaan'),
      ),
    );
  });
}
