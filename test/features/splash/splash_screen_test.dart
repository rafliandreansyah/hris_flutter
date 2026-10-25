import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/app_constants.dart';
import 'package:hris_flutter/core/constants/legal_links.dart';
import 'package:hris_flutter/features/splash/presentation/pages/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../legal/fake_legal_consent_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget & Routing Tests', () {
    setUp(() {
      // Default: kebijakan sudah disetujui & bukan instalasi baru.
      SharedPreferences.setMockInitialValues({
        'legal_consent_accepted_version': LegalLinks.consentVersion,
        'app_install_marker': true,
      });
    });

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

    GoRouter buildRouter(FakeLegalConsentRepository repo) => GoRouter(
          initialLocation: Routes.SPLASH,
          routes: [
            GoRoute(
              path: Routes.SPLASH,
              name: Routes.SPLASH,
              builder: (context, state) =>
                  SplashScreenPage(consentRepository: repo),
            ),
            GoRoute(
              path: Routes.PRIVACY_CONSENT,
              name: Routes.PRIVACY_CONSENT,
              builder: (context, state) =>
                  const Scaffold(body: Text('Consent Destination')),
            ),
            GoRoute(
              path: Routes.LOGIN,
              name: Routes.LOGIN,
              builder: (context, state) =>
                  const Scaffold(body: Text('Login Destination')),
            ),
            GoRoute(
              path: Routes.DASHBOARD,
              name: Routes.DASHBOARD,
              builder: (context, state) =>
                  const Scaffold(body: Text('Dashboard Destination')),
            ),
          ],
        );

    testWidgets('redirects to PRIVACY_CONSENT when policy not accepted, even with session',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.accessTokenKey: 'token',
      });
      final repo = FakeLegalConsentRepository(accepted: false);

      await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter(repo)));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Consent Destination'), findsOneWidget);
      expect(find.text('Dashboard Destination'), findsNothing);
    });

    testWidgets('fresh install clears leftover keychain token and goes to LOGIN',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.accessTokenKey: 'stale-token',
      });
      final repo = FakeLegalConsentRepository(accepted: true, freshInstall: true);

      await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter(repo)));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Login Destination'), findsOneWidget);
      expect(repo.freshInstall, isFalse);
    });
  });
}
