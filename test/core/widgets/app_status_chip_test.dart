import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AppStatusTone.fromStatus', () {
    test('memetakan status umum ke nada warna', () {
      expect(AppStatusTone.fromStatus('Approved'), AppStatusTone.success);
      expect(AppStatusTone.fromStatus('paid'), AppStatusTone.success);
      expect(AppStatusTone.fromStatus('Pending'), AppStatusTone.warning);
      expect(AppStatusTone.fromStatus('requested'), AppStatusTone.warning);
      expect(AppStatusTone.fromStatus('Rejected'), AppStatusTone.error);
      expect(AppStatusTone.fromStatus('cancelled'), AppStatusTone.error);
      expect(AppStatusTone.fromStatus('planned'), AppStatusTone.info);
      expect(AppStatusTone.fromStatus('apa-saja'), AppStatusTone.neutral);
      expect(AppStatusTone.fromStatus(null), AppStatusTone.neutral);
    });
  });

  group('AppStatusChip', () {
    testWidgets('selalu full rounded dan menampilkan label + dot', (t) async {
      await t.pumpWidget(
        _wrap(const AppStatusChip(label: 'Approved', tone: AppStatusTone.success)),
      );

      expect(find.text('Approved'), findsOneWidget);
      final box = t.widget<Container>(find.byType(Container).first);
      final deco = box.decoration! as BoxDecoration;
      expect(deco.borderRadius, AppRadius.borderFull);
    });

    testWidgets('ikon menggantikan dot', (t) async {
      await t.pumpWidget(
        _wrap(const AppStatusChip(
          label: 'Lunas',
          tone: AppStatusTone.success,
          icon: Icons.check,
        )),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('factory fromStatus memakai label sendiri bila diberikan', (t) async {
      await t.pumpWidget(
        _wrap(AppStatusChip.fromStatus('rejected', label: 'Ditolak'),
            brightness: Brightness.dark),
      );
      expect(find.text('Ditolak'), findsOneWidget);
    });
  });
}
