import 'dart:io';
import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hris_flutter/app/routes/app_router.dart';

/// Service singleton untuk mengelola HTTP Inspector (Alice / Chucker)
class AliceService {
  static AliceService? _instance;
  static AliceService get instance => _instance ??= AliceService._internal();

  @visibleForTesting
  static void setMockInstance(AliceService? mock) {
    _instance = mock;
  }

  late final Alice alice;
  late final AliceDioAdapter dioAdapter;

  AliceService._internal({AliceConfiguration? configuration}) {
    final isTestEnvironment =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    alice = Alice(
      configuration: configuration ??
          AliceConfiguration(
            navigatorKey: AppRouter.rootNavigatorKey,
            showNotification: kDebugMode && !isTestEnvironment,
            showInspectorOnShake: kDebugMode && !isTestEnvironment,
            notificationIcon: '@mipmap/ic_launcher',
          ),
    );

    dioAdapter = AliceDioAdapter();
    if (kDebugMode) {
      alice.addAdapter(dioAdapter);
    }
  }

  /// Menampilkan inspector secara aman, menunggu post-frame jika context/overlay belum siap
  void showInspector() {
    final overlay = AppRouter.rootNavigatorKey.currentState?.overlay;
    if (overlay != null) {
      alice.showInspector();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          alice.showInspector();
        });
      });
    }
  }
}
