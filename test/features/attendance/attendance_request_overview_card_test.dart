import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_overview_card.dart';

void main() {
  Widget buildTestCard(AttendanceRequestDetailData detail) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AttendanceRequestOverviewCard(detail: detail),
        ),
      ),
    );
  }

  group('AttendanceRequestOverviewCard Widget Tests', () {
    const employee = AttendanceRequestEmployeeModel(
      id: 'emp-1',
      firstName: 'Budi',
      lastName: 'Santoso',
    );

    testWidgets(
        'type "in": renders only Waktu Masuk, hides Pulang and middle divider',
        (tester) async {
      final detailIn = AttendanceRequestDetailData(
        id: 'req-in',
        employee: employee,
        status: 'requested',
        method: 'photo',
        attendanceType: 'in',
        attendanceInTime: DateTime(2026, 9, 18, 8, 30),
        timezone: 'WIB',
        reason: 'Meeting klien',
      );

      await tester.pumpWidget(buildTestCard(detailIn));
      await tester.pumpAndSettle();

      // Memastikan 'Waktu Masuk' muncul
      expect(find.text('Waktu Masuk'), findsOneWidget);
      expect(find.textContaining('08:30 WIB'), findsOneWidget);
      expect(find.text('IN'), findsOneWidget);

      // Memastikan 'Pulang' atau 'Waktu Pulang' tidak muncul sama sekali
      expect(find.text('Waktu Pulang'), findsNothing);
      expect(find.text('Pulang'), findsNothing);
    });

    testWidgets(
        'type "out": renders only Waktu Pulang, hides Masuk and middle divider',
        (tester) async {
      final detailOut = AttendanceRequestDetailData(
        id: 'req-out',
        employee: employee,
        status: 'requested',
        method: 'photo',
        attendanceType: 'out',
        attendanceOutTime: DateTime(2026, 9, 18, 17, 30),
        timezone: 'WIB',
        reason: 'Selesai tugas luar',
      );

      await tester.pumpWidget(buildTestCard(detailOut));
      await tester.pumpAndSettle();

      // Memastikan 'Waktu Pulang' muncul
      expect(find.text('Waktu Pulang'), findsOneWidget);
      expect(find.textContaining('17:30 WIB'), findsOneWidget);
      expect(find.text('OUT'), findsOneWidget);

      // Memastikan 'Masuk' atau 'Waktu Masuk' tidak muncul sama sekali
      expect(find.text('Waktu Masuk'), findsNothing);
      expect(find.text('Masuk'), findsNothing);
    });

    testWidgets(
        'type "inout": renders both Masuk and Pulang side by side',
        (tester) async {
      final detailInOut = AttendanceRequestDetailData(
        id: 'req-inout',
        employee: employee,
        status: 'requested',
        method: 'photo',
        attendanceType: 'inout',
        attendanceInTime: DateTime(2026, 9, 18, 8, 0),
        attendanceOutTime: DateTime(2026, 9, 18, 17, 0),
        timezone: 'WIB',
        reason: 'Dinas seharian',
      );

      await tester.pumpWidget(buildTestCard(detailInOut));
      await tester.pumpAndSettle();

      // Memastikan Masuk dan Pulang keduanya muncul
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Pulang'), findsOneWidget);
      expect(find.textContaining('08:00 WIB'), findsOneWidget);
      expect(find.textContaining('17:00 WIB'), findsOneWidget);
      expect(find.text('IN & OUT'), findsOneWidget);
    });
  });
}
