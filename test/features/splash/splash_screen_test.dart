import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/features/splash/presentation/pages/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget & Routing Tests', () {
    testWidgets('renders splash screen branding correctly', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});

      final router = GoRouter(
        initialLocation: Routes.SPLASH,
        routes: [
          GoRoute(
            path: Routes.SPLASH,
            name: Routes.SPLASH,
            builder: (context, state) => const SplashScreenPage(),
          ),
          GoRoute(
            path: Routes.LOGIN,
            name: Routes.LOGIN,
            builder: (context, state) => const Scaffold(body: Text('Login Screen Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      expect(find.text('Oasish'), findsOneWidget);

      // Selesaikan pending timer splash 750ms
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
    });

    testWidgets('redirects to LOGIN when hasActiveSession is false', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});

      final router = GoRouter(
        initialLocation: Routes.SPLASH,
        routes: [
          GoRoute(
            path: Routes.SPLASH,
            name: Routes.SPLASH,
            builder: (context, state) => const SplashScreenPage(),
          ),
          GoRoute(
            path: Routes.LOGIN,
            name: Routes.LOGIN,
            builder: (context, state) => const Scaffold(body: Text('Login Destination')),
          ),
          GoRoute(
            path: Routes.DASHBOARD,
            name: Routes.DASHBOARD,
            builder: (context, state) => const Scaffold(body: Text('Dashboard Destination')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Advance past the 750ms minimum splash timer
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Login Destination'), findsOneWidget);
      expect(find.text('Dashboard Destination'), findsNothing);
    });

    testWidgets('redirects to DASHBOARD when hasActiveSession is true', (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.accessTokenKey: 'valid_jwt_token_for_session',
      });

      final router = GoRouter(
        initialLocation: Routes.SPLASH,
        routes: [
          GoRoute(
            path: Routes.SPLASH,
            name: Routes.SPLASH,
            builder: (context, state) => const SplashScreenPage(),
          ),
          GoRoute(
            path: Routes.LOGIN,
            name: Routes.LOGIN,
            builder: (context, state) => const Scaffold(body: Text('Login Destination')),
          ),
          GoRoute(
            path: Routes.DASHBOARD,
            name: Routes.DASHBOARD,
            builder: (context, state) => const Scaffold(body: Text('Dashboard Destination')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Advance past the 750ms minimum splash timer
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Destination'), findsOneWidget);
      expect(find.text('Login Destination'), findsNothing);
    });
  });
}
