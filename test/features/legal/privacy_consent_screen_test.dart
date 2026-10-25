import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/legal_links.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/legal/presentation/bloc/legal_consent/legal_consent_bloc.dart';
import 'package:hris_flutter/features/legal/presentation/pages/privacy_consent_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'fake_legal_consent_repository.dart';

class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launched = [];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> canLaunch(String url) async => true;
}

void main() {
  late FakeLegalConsentRepository repo;
  late _FakeUrlLauncher launcher;

  setUp(() {
    repo = FakeLegalConsentRepository();
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  Future<GoRouter> pumpScreen(WidgetTester tester, {String? from}) async {
    final router = GoRouter(
      initialLocation: Uri(
        path: Routes.PRIVACY_CONSENT,
        queryParameters: {'from': ?from},
      ).toString(),
      routes: [
        GoRoute(
          path: Routes.PRIVACY_CONSENT,
          name: Routes.PRIVACY_CONSENT,
          builder: (context, state) => PrivacyConsentScreen(
            pendingLink: state.uri.queryParameters['from'],
            bloc: LegalConsentBloc(repository: repo),
          ),
        ),
        GoRoute(
          path: Routes.SPLASH,
          name: Routes.SPLASH,
          builder: (context, state) => Scaffold(
            body: Text('Splash ${state.uri.queryParameters['from'] ?? '-'}'),
          ),
        ),
      ],
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  AppButton acceptButton(WidgetTester tester) => tester.widget<AppButton>(
        find.byKey(const Key('consent_accept_button')),
      );

  testWidgets('tombol Setuju nonaktif sebelum checkbox dicentang', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Kebijakan Privasi & Syarat Ketentuan'), findsOneWidget);
    expect(acceptButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('consent_agreement')));
    await tester.pump();

    expect(acceptButton(tester).onPressed, isNotNull);
  });

  testWidgets('setuju menyimpan persetujuan lalu kembali ke splash dengan deep link',
      (tester) async {
    await pumpScreen(tester, from: '/leave-detail/abc');

    await tester.tap(find.byKey(const Key('consent_agreement')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('consent_accept_button')));
    await tester.pumpAndSettle();

    expect(repo.accepted, isTrue);
    expect(find.text('Splash /leave-detail/abc'), findsOneWidget);
  });

  testWidgets('tautan dokumen membuka URL kebijakan', (tester) async {
    await pumpScreen(tester);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Kebijakan Privasi'), 200,
        scrollable: scrollable);
    await tester.tap(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hapus Akun & Data'), 200,
        scrollable: scrollable);
    await tester.tap(find.text('Hapus Akun & Data'));
    await tester.pumpAndSettle();

    expect(launcher.launched, [LegalLinks.privacyPolicy, LegalLinks.deleteData]);
  });
}
