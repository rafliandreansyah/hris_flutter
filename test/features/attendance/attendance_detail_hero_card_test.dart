import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_detail_hero_card.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget createTestApp(Widget child, [Locale locale = const Locale('id')]) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AttendanceDetailHeroCard Widget Tests', () {
    testWidgets('Clock In - displays Terlambat X mnt when lateInMinutes > 0', (tester) async {
      final detail = AttendanceDetailModel(
        id: 'att-1',
        attendanceType: 'Clock In',
        attendanceTime: DateTime(2026, 9, 17, 8, 15, 0),
        attendanceMethod: 'Face Biometric',
        lateInMinutes: 15,
        shift: const AttendanceShiftInfo(
          id: 'shift-1',
          name: 'Pagi',
          startTime: '08:00',
          endTime: '17:00',
        ),
      );

      await tester.pumpWidget(createTestApp(AttendanceDetailHeroCard(detail: detail)));
      await tester.pumpAndSettle();

      expect(find.text('Masuk Kerja'), findsOneWidget);
      expect(find.text('Terlambat 15 mnt'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clockAlert), findsOneWidget);
    });

    testWidgets('Clock In - displays Tepat Waktu when not late', (tester) async {
      final detail = AttendanceDetailModel(
        id: 'att-2',
        attendanceType: 'Clock In',
        attendanceTime: DateTime(2026, 9, 17, 7, 55, 0),
        attendanceMethod: 'Face Biometric',
        lateInMinutes: 0,
        shift: const AttendanceShiftInfo(
          id: 'shift-1',
          name: 'Pagi',
          startTime: '08:00',
          endTime: '17:00',
        ),
      );

      await tester.pumpWidget(createTestApp(AttendanceDetailHeroCard(detail: detail)));
      await tester.pumpAndSettle();

      expect(find.text('Masuk Kerja'), findsOneWidget);
      expect(find.text('Tepat Waktu'), findsOneWidget);
      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('Clock Out - displays Pulang Lebih Awal X mnt when earlyOutInMinutes > 0', (tester) async {
      final detail = AttendanceDetailModel(
        id: 'att-3',
        attendanceType: 'Clock Out',
        attendanceTime: DateTime(2026, 9, 17, 16, 40, 0),
        attendanceMethod: 'Face Biometric',
        earlyOutInMinutes: 20,
        shift: const AttendanceShiftInfo(
          id: 'shift-1',
          name: 'Pagi',
          startTime: '08:00',
          endTime: '17:00',
        ),
      );

      await tester.pumpWidget(createTestApp(AttendanceDetailHeroCard(detail: detail)));
      await tester.pumpAndSettle();

      expect(find.text('Pulang Kerja'), findsOneWidget);
      expect(find.text('Pulang Lebih Awal 20 mnt'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clockAlert), findsOneWidget);
    });

    testWidgets('Clock Out - automatically calculates early out from shift endTime and attendanceTime', (tester) async {
      final detail = AttendanceDetailModel(
        id: 'att-4',
        attendanceType: 'Clock Out',
        attendanceTime: DateTime(2026, 9, 17, 16, 30, 0), // 30 minutes before 17:00
        attendanceMethod: 'Face Biometric',
        shift: const AttendanceShiftInfo(
          id: 'shift-1',
          name: 'Pagi',
          startTime: '08:00',
          endTime: '17:00',
        ),
      );

      await tester.pumpWidget(createTestApp(AttendanceDetailHeroCard(detail: detail)));
      await tester.pumpAndSettle();

      expect(find.text('Pulang Kerja'), findsOneWidget);
      expect(find.text('Pulang Lebih Awal 30 mnt'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clockAlert), findsOneWidget);
    });

    testWidgets('Clock Out - displays Tepat Waktu when leaving at or after shift endTime', (tester) async {
      final detail = AttendanceDetailModel(
        id: 'att-5',
        attendanceType: 'Clock Out',
        attendanceTime: DateTime(2026, 9, 17, 17, 5, 0), // 5 minutes after 17:00
        attendanceMethod: 'Face Biometric',
        shift: const AttendanceShiftInfo(
          id: 'shift-1',
          name: 'Pagi',
          startTime: '08:00',
          endTime: '17:00',
        ),
      );

      await tester.pumpWidget(createTestApp(AttendanceDetailHeroCard(detail: detail)));
      await tester.pumpAndSettle();

      expect(find.text('Pulang Kerja'), findsOneWidget);
      expect(find.text('Tepat Waktu'), findsOneWidget);
      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('Clock Out - English localization displays Early by X mins', (tester) async {
      final detail = AttendanceDetailModel(
        id: 'att-6',
        attendanceType: 'Clock Out',
        attendanceTime: DateTime(2026, 9, 17, 16, 45, 0),
        attendanceMethod: 'Face Biometric',
        earlyOutInMinutes: 15,
        shift: const AttendanceShiftInfo(
          id: 'shift-1',
          name: 'Morning',
          startTime: '08:00',
          endTime: '17:00',
        ),
      );

      await tester.pumpWidget(createTestApp(
        AttendanceDetailHeroCard(detail: detail),
        const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Clock Out'), findsOneWidget);
      expect(find.text('Early by 15 mins'), findsOneWidget);
    });
  });
}
