import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/contact_launcher_util.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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
  Future<bool> canLaunch(String url) async => true;
}

void main() {
  group('normalizePhone', () {
    test('08xx -> 628xx, +62 dan spasi/strip dibersihkan', () {
      expect(ContactLauncherUtil.normalizePhone('0812-3456-7890'), '6281234567890');
      expect(ContactLauncherUtil.normalizePhone('+62 812 3456 7890'), '6281234567890');
      expect(ContactLauncherUtil.normalizePhone('6281234567890'), '6281234567890');
      expect(ContactLauncherUtil.normalizePhone(''), isNull);
      expect(ContactLauncherUtil.normalizePhone(null), isNull);
    });
  });

  group('aksi kontak', () {
    late _FakeUrlLauncher fake;
    setUp(() {
      fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;
    });

    Widget host(void Function(BuildContext) onPressed) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => onPressed(context),
                child: const Text('go'),
              ),
            ),
          ),
        );

    testWidgets('telepon: pilih WhatsApp membuka wa.me dengan nomor pegawai', (tester) async {
      await tester.pumpWidget(host((c) => ContactLauncherUtil.showPhoneOptions(
            c,
            name: 'Budi',
            phone: '0812-3456-7890',
          )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Telepon'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('contact_whatsapp_option')));
      await tester.pumpAndSettle();
      expect(fake.launched, ['https://wa.me/6281234567890']);
    });

    testWidgets('telepon: pilih Telepon membuka tel: dengan nomor pegawai', (tester) async {
      await tester.pumpWidget(host((c) => ContactLauncherUtil.showPhoneOptions(
            c,
            name: 'Budi',
            phone: '0812-3456-7890',
          )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('contact_call_option')));
      await tester.pumpAndSettle();
      expect(fake.launched, ['tel:+6281234567890']);
    });

    testWidgets('telepon tanpa nomor menampilkan dialog error, tanpa membuka apa pun', (tester) async {
      await tester.pumpWidget(host((c) =>
          ContactLauncherUtil.showPhoneOptions(c, name: 'Budi', phone: null)));
      await tester.tap(find.text('go'));
      // Dialog pro_dialog beranimasi terus-menerus: jangan pumpAndSettle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nomor Belum Tersedia'), findsOneWidget);
      expect(fake.launched, isEmpty);
    });

    testWidgets('email membuka mailto: dengan alamat pegawai', (tester) async {
      await tester.pumpWidget(host((c) => ContactLauncherUtil.composeEmail(
            c,
            name: 'Budi',
            email: 'budi@oasis.corp',
          )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(fake.launched, ['mailto:budi@oasis.corp']);
    });
  });
}
