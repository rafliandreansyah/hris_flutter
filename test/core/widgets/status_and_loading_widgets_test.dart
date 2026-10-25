import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/core/widgets/app_status_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('AppStatusIcon', () {
    testWidgets('hanya ikon (tanpa teks) dengan tooltip & semantics', (tester) async {
      await tester.pumpWidget(_wrap(AppStatusIcon.fromStatus('approved')));

      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
      expect(find.text('Disetujui'), findsNothing);
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.bySemanticsLabel('Status: Disetujui'), findsOneWidget);
    });

    test('pemetaan label & ikon status pengajuan seragam', () {
      expect(AppStatusIcon.labelFor('requested'), 'Menunggu Persetujuan');
      expect(AppStatusIcon.labelFor('submitted'), 'Menunggu Persetujuan');
      expect(AppStatusIcon.labelFor('rejected'), 'Ditolak');
      expect(AppStatusIcon.labelFor('disbursed'), 'Dicairkan');
      expect(AppStatusIcon.iconFor('requested'), LucideIcons.clock);
      expect(AppStatusIcon.iconFor('rejected'), LucideIcons.circleX);
      expect(AppStatusIcon.iconFor('canceled'), LucideIcons.ban);
      expect(AppStatusIcon.iconFor('settled'), LucideIcons.badgeCheck);
    });

    testWidgets('ikon eksplisit menimpa ikon bawaan nada', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppStatusIcon(
            label: 'Dicairkan',
            tone: AppStatusTone.info,
            icon: LucideIcons.wallet,
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
    });
  });

  group('AppLoadingIndicator', () {
    testWidgets('ukuran & ketebalan seragam', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              AppLoadingIndicator(),
              AppLoadingIndicator.small(),
            ],
          ),
        ),
      );

      final spinners = tester
          .widgetList<CircularProgressIndicator>(find.byType(CircularProgressIndicator))
          .toList();
      expect(spinners, hasLength(2));
      for (final s in spinners) {
        expect(s.strokeWidth, AppLoadingIndicator.strokeWidth);
      }
      final sizes = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(AppLoadingIndicator),
              matching: find.byType(SizedBox),
            ),
          )
          .map((b) => b.width)
          .toList();
      expect(sizes, [AppLoadingIndicator.regularSize, AppLoadingIndicator.smallSize]);
    });
  });
}
