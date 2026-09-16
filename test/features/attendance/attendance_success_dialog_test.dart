import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_success_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummySuccessInfo = AttendanceSuccessInfo(
    attendanceType: 'in',
    title: 'Presensi Masuk Berhasil',
    message: 'Presensi Masuk Anda berhasil dicatat oleh sistem.',
    date: DateTime(2026, 9, 16, 8, 45, 0),
    formattedDate: 'Rabu, 16 September 2026',
    formattedTime: '08:45 WIB',
    locationName: 'Headquarters Office',
  );

  testWidgets('AttendanceSuccessDialog displays correct info details and OK button', (tester) async {
    bool okPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AttendanceSuccessDialog.show(
                  context,
                  successInfo: dummySuccessInfo,
                  onOk: () {
                    okPressed = true;
                    Navigator.of(context).pop();
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify Title & Message
    expect(find.text('Presensi Masuk Berhasil'), findsOneWidget);
    expect(find.text('Presensi Masuk Anda berhasil dicatat oleh sistem.'), findsOneWidget);

    // Verify Details (Tanggal, Waktu, Lokasi)
    expect(find.text('Tanggal'), findsOneWidget);
    expect(find.text('Rabu, 16 September 2026'), findsOneWidget);
    expect(find.text('Waktu Presensi'), findsOneWidget);
    expect(find.text('08:45 WIB'), findsOneWidget);
    expect(find.text('Lokasi Kerja'), findsOneWidget);
    expect(find.text('Headquarters Office'), findsOneWidget);

    // Verify dialog cannot be dismissed by tapping outside (barrier)
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceSuccessDialog), findsOneWidget);

    // Tap OK button
    final okButton = find.byKey(const ValueKey('attendance_success_dialog_ok_button'));
    expect(okButton, findsOneWidget);
    await tester.tap(okButton);
    await tester.pumpAndSettle();

    expect(okPressed, isTrue);
    expect(find.byType(AttendanceSuccessDialog), findsNothing);
  });
}
