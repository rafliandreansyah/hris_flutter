import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('saves and retrieves employee ID successfully', () async {
      final storage = SecureStorageService.instance;

      // Before saving, should be null
      final initialId = await storage.getEmployeeId();
      expect(initialId, isNull);

      // Save employee ID
      const testEmployeeId = '123e4567-e89b-12d3-a456-426614174000';
      await storage.saveEmployeeId(testEmployeeId);

      // Retrieve employee ID
      final retrievedId = await storage.getEmployeeId();
      expect(retrievedId, equals(testEmployeeId));
    });

    test('clearAuthData clears employee ID along with auth tokens', () async {
      final storage = SecureStorageService.instance;

      await storage.saveAccessToken('token_abc');
      await storage.saveEmployeeId('EMP-001');

      expect(await storage.getAccessToken(), equals('token_abc'));
      expect(await storage.getEmployeeId(), equals('EMP-001'));

      await storage.clearAuthData();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getEmployeeId(), isNull);
    });
  });
}
