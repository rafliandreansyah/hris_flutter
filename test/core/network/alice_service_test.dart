import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/app/routes/app_router.dart';
import 'package:hris_flutter/core/network/alice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AliceService Tests', () {
    test('instance returns singleton', () {
      final instance1 = AliceService.instance;
      final instance2 = AliceService.instance;

      expect(instance1, same(instance2));
    });

    test('alice instance is configured with AppRouter.rootNavigatorKey', () {
      final service = AliceService.instance;

      expect(service.alice, isNotNull);
      expect(service.alice.getNavigatorKey(), equals(AppRouter.rootNavigatorKey));
    });

    test('dioAdapter is created and attached to alice', () {
      final service = AliceService.instance;

      expect(service.dioAdapter, isNotNull);
    });

    test('showInspector does not throw when context is not ready', () {
      final service = AliceService.instance;

      expect(() => service.showInspector(), returnsNormally);
    });
  });
}
