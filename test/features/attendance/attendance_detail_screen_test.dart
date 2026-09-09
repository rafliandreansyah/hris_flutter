import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_detail/attendance_detail_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_detail_screen.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'attendance_detail_bloc_test.dart';

Widget createTestApp(Widget child, [Locale locale = const Locale('id')]) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fullDetail = AttendanceDetailModel(
    id: 'att-001',
    attendanceType: 'Clock In',
    attendanceTime: DateTime(2026, 9, 9, 14, 25, 30),
    attendanceMethod: 'Photo Face Recognition',
    employee: const AttendanceEmployeeInfo(
      id: 'emp-101',
      firstName: 'Budi',
      lastName: 'Santoso',
      photoUrl: null,
      company: 'PT Oasish Global',
      department: 'Technology',
      position: 'Mobile Engineer',
      level: 'L4',
    ),
    latitude: -6.2088,
    longitude: 106.8456,
    workLocation: const AttendanceWorkLocationInfo(
      id: 'loc-01',
      name: 'Wisma Nusantara HQ',
    ),
    address: 'Jl. M.H. Thamrin No. 59, Jakarta Pusat',
    filePath: 'https://example.com/photos/attendance_001.jpg',
    attendanceRequestId: 'REQ-OUTSIDE-8829',
    lateInMinutes: 12,
    workDate: '2026-09-09',
    shift: const AttendanceShiftInfo(
      id: 'shift-01',
      name: 'Regular Morning',
      startTime: '08:00',
      endTime: '17:00',
    ),
    timezone: 'WIB',
  );

  group('AttendanceDetailScreen Widget Tests', () {
    testWidgets('renders all Stitch elements including map, outside attendance, and photo proof', (tester) async {
      final repository = MockAttendanceDetailRepository(mockDetail: fullDetail);
      final bloc = AttendanceDetailBloc(repository: repository)
        ..add(const AttendanceDetailStarted('att-001'));

      await tester.pumpWidget(createTestApp(
        AttendanceDetailScreen(attendanceId: 'att-001', bloc: bloc),
      ));
      await tester.pumpAndSettle();

      // Top title
      expect(find.text('Detail Presensi'), findsAtLeast(1));

      // Hero Card: 24-hour time format & dynamic timezone chip
      expect(find.text('14:25:30'), findsOneWidget);
      expect(find.text('WIB'), findsAtLeast(1));

      // Punctuality: Late by 12 mins
      expect(find.text('Terlambat 12 mnt'), findsAtLeast(1));

      // Map card: Location title & Address
      expect(find.text('Wisma Nusantara HQ'), findsAtLeast(1));
      expect(find.text('Jl. M.H. Thamrin No. 59, Jakarta Pusat'), findsOneWidget);
      expect(find.text('Buka di Maps'), findsOneWidget);

      // Outside Attendance card: Header, notice text, and request ID
      expect(find.text('Kehadiran Luar Kantor'), findsAtLeast(1));
      expect(
        find.text('Absen dari pengajuan Outside Attendance / Kehadiran luar kantor'),
        findsOneWidget,
      );
      expect(find.text('REQ-OUTSIDE-8829'), findsOneWidget);

      // Employee Profile
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Mobile Engineer • L4'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('PT Oasish Global'), findsOneWidget);

      // Shift & Method Bento
      expect(find.text('Regular Morning'), findsOneWidget);
      expect(find.text('08:00 - 17:00'), findsOneWidget);
      expect(find.text('Photo Face Recognition'), findsOneWidget);

      // Photo Proof Card
      expect(find.text('Bukti Foto Presensi'), findsOneWidget);
      expect(find.text('Ketuk untuk memperbesar foto'), findsOneWidget);

      // Correction button
      expect(find.text('Ajukan Koreksi Absensi'), findsOneWidget);

      bloc.close();
    });

    testWidgets('hides Outside Attendance info when attendanceRequestId is null or empty', (tester) async {
      final detailWithoutRequest = AttendanceDetailModel(
        id: 'att-002',
        attendanceType: 'Clock In',
        attendanceTime: DateTime(2026, 9, 9, 8, 0, 0),
        attendanceMethod: 'Fingerprint',
        attendanceRequestId: null,
        lateInMinutes: 0,
        timezone: 'WITA',
      );

      final repository = MockAttendanceDetailRepository(mockDetail: detailWithoutRequest);
      final bloc = AttendanceDetailBloc(repository: repository)
        ..add(const AttendanceDetailStarted('att-002'));

      await tester.pumpWidget(createTestApp(
        AttendanceDetailScreen(attendanceId: 'att-002', bloc: bloc),
      ));
      await tester.pumpAndSettle();

      // Outside Attendance notice should NOT be found
      expect(
        find.text('Absen dari pengajuan Outside Attendance / Kehadiran luar kantor'),
        findsNothing,
      );

      bloc.close();
    });

    testWidgets('hides Photo Proof card when attendanceMethod is not photo or filePath is null', (tester) async {
      final detailWithoutPhoto = AttendanceDetailModel(
        id: 'att-003',
        attendanceType: 'Clock Out',
        attendanceTime: DateTime(2026, 9, 9, 17, 0, 0),
        attendanceMethod: 'Geofence GPS Only',
        filePath: null,
        lateInMinutes: 0,
        timezone: 'WIT',
      );

      final repository = MockAttendanceDetailRepository(mockDetail: detailWithoutPhoto);
      final bloc = AttendanceDetailBloc(repository: repository)
        ..add(const AttendanceDetailStarted('att-003'));

      await tester.pumpWidget(createTestApp(
        AttendanceDetailScreen(attendanceId: 'att-003', bloc: bloc),
      ));
      await tester.pumpAndSettle();

      // Proof attachment should NOT be found
      expect(find.text('Bukti Foto Presensi'), findsNothing);
      expect(find.text('Ketuk untuk memperbesar foto'), findsNothing);

      // Verify dynamic timezone "WIT" is shown
      expect(find.text('WIT'), findsOneWidget);

      bloc.close();
    });

    testWidgets('handles 404 error with only Kembali button and no retry', (tester) async {
      final repository = MockAttendanceDetailRepository(
        shouldThrow: true,
        throwStatusCode: 404,
        throwMessage: 'Data presensi tidak ditemukan',
      );
      final bloc = AttendanceDetailBloc(repository: repository)
        ..add(const AttendanceDetailStarted('att-404'));

      await tester.pumpWidget(createTestApp(
        AttendanceDetailScreen(attendanceId: 'att-404', bloc: bloc),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Data presensi tidak ditemukan'), findsAtLeast(1));
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);

      bloc.close();
    });

    testWidgets('handles 403 error with only Kembali button and no retry', (tester) async {
      final repository = MockAttendanceDetailRepository(
        shouldThrow: true,
        throwStatusCode: 403,
        throwMessage: 'Tidak ada hak akses',
      );
      final bloc = AttendanceDetailBloc(repository: repository)
        ..add(const AttendanceDetailStarted('att-403'));

      await tester.pumpWidget(createTestApp(
        AttendanceDetailScreen(attendanceId: 'att-403', bloc: bloc),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada hak akses'), findsAtLeast(1));
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);

      bloc.close();
    });

    testWidgets('handles 500 server error with Coba Lagi and Kembali buttons', (tester) async {
      final repository = MockAttendanceDetailRepository(
        shouldThrow: true,
        throwStatusCode: 500,
        throwMessage: 'Terjadi kesalahan pada server internal',
      );
      final bloc = AttendanceDetailBloc(repository: repository)
        ..add(const AttendanceDetailStarted('att-500'));

      await tester.pumpWidget(createTestApp(
        AttendanceDetailScreen(attendanceId: 'att-500', bloc: bloc),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Terjadi kesalahan pada server internal'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);

      bloc.close();
    });
  });
}
