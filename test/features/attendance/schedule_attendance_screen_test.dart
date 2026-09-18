import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/schedule_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/schedule_attendance_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/schedule_location_picker_modal.dart';

class _FakeAttendanceRequestRepo extends Fake implements AttendanceRequestRepository {
  ScheduleAttendanceRequest? submitted;

  @override
  Future<AttendanceRequestListResponse> getAttendanceRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    return const AttendanceRequestListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: AttendanceRequestPaginationMeta(
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<LiveAttendanceResponse> submitLiveAttendance(
    LiveAttendanceRequest request,
  ) async {
    return const LiveAttendanceResponse(
      success: true,
      message: 'OK',
      data: LiveAttendanceData(id: 'live-test-id'),
    );
  }

  @override
  Future<ScheduleAttendanceResponse> submitScheduleAttendance(
    ScheduleAttendanceRequest request,
  ) async {
    submitted = request;
    return const ScheduleAttendanceResponse(
      success: true,
      message: 'Pengajuan presensi terjadwal berhasil diajukan.',
      data: ScheduleAttendanceData(id: 'sched-test-id'),
    );
  }
}

Widget _wrapWidget(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  setUp(() {
    PermissionUtil.bypassInTest = true;
    ScheduleLocationPickerModal.bypassInTest = true;
  });

  group('ScheduleAttendanceScreen Widget Tests', () {
    testWidgets('merender AppBar dengan judul Presensi Luar (Schedule) dan subtitle', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Presensi Luar (Schedule)'), findsOneWidget);
      expect(find.text('Ajukan jadwal presensi luar kantor terencana'), findsOneWidget);

      bloc.close();
    });

    testWidgets('merender Switcher Tiga Opsi Jenis Presensi (In, Out, In & Out)', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('schedule-type-in')), findsOneWidget);
      expect(find.byKey(const Key('schedule-type-out')), findsOneWidget);
      expect(find.byKey(const Key('schedule-type-inout')), findsOneWidget);

      bloc.close();
    });

    testWidgets('merender Card Tanggal & Waktu Presensi', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('TANGGAL & WAKTU PRESENSI'), findsOneWidget);
      expect(find.textContaining('17 September 2026'), findsOneWidget);
      expect(find.text('08:30 WIB'), findsOneWidget);
      expect(find.text('17:00 WIB'), findsOneWidget);

      bloc.close();
    });

    testWidgets('merender Card Lokasi GPS, badge Sama dengan In, dan tombol Pilih saat sameLocation off', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('LOKASI GPS'), findsOneWidget);
      expect(find.byKey(const Key('schedule-pick-in-location-button')), findsOneWidget);
      expect(find.text('Sama dengan In'), findsOneWidget);
      expect(find.byKey(const Key('schedule-same-location-checkbox')), findsOneWidget);

      // Ketika sameLocation dimatikan, tombol pilih lokasi pulang muncul
      bloc.add(const ScheduleAttendanceSameLocationToggled(false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('schedule-pick-out-location-button')), findsOneWidget);

      bloc.close();
    });

    testWidgets('merender Card Bukti Foto saat mode Photo (2 card foto untuk inout)', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('BUKTI VERIFIKASI KEHADIRAN'), findsOneWidget);
      expect(find.text('Metode: Photo Verification'), findsOneWidget);
      expect(find.byKey(const Key('schedule-photo-in-trigger')), findsOneWidget);
      expect(find.byKey(const Key('schedule-photo-out-trigger')), findsOneWidget);

      bloc.close();
    });

    testWidgets('menampilkan Card Biometrik saat mode Biometric diaktifkan', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      bloc.add(const ScheduleAttendanceMethodChanged('biometric'));

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('BUKTI VERIFIKASI KEHADIRAN'), findsOneWidget);
      expect(find.text('Metode: Biometric Verification'), findsOneWidget);
      expect(find.text('Autentikasi Sidik Jari / Face ID'), findsOneWidget);
      expect(find.byKey(const Key('schedule-photo-in-trigger')), findsNothing);

      bloc.close();
    });

    testWidgets('merender Form Alasan dan Tombol Ajukan Presensi Terencana', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('ALASAN & PENJELASAN TUGAS LUAR'), findsOneWidget);
      expect(find.byKey(const Key('schedule-reason-input')), findsOneWidget);
      expect(find.byKey(const Key('schedule-attendance-submit-button')), findsOneWidget);

      bloc.close();
    });

    testWidgets('menampilkan warning dialog jika submit dengan alasan kosong', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = ScheduleAttendanceBloc(
        repository: repo,
        initialDate: DateTime(2026, 9, 17),
      );

      await tester.pumpWidget(
        _wrapWidget(ScheduleAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('schedule-attendance-submit-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Form Belum Lengkap'), findsOneWidget);
      expect(find.text('Alasan pengajuan presensi terjadwal wajib diisi.'), findsOneWidget);

      bloc.close();
    });
  });
}
