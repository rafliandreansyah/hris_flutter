import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/create_overtime/create_overtime_bloc.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/create_overtime_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeOvertimeRepository implements OvertimeRepository {
  final OvertimeScheduleData scheduleData;

  _FakeOvertimeRepository({
    this.scheduleData = const OvertimeScheduleData(
      isGenerated: false,
      isDayOff: true,
      requiresCheckOut: false,
    ),
  });

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
    String? statusApprove,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  }) async {
    return scheduleData;
  }

  @override
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  }) async {
    return const CreateOvertimeResultModel(
      success: true,
      message: 'OK',
      id: 'ot-123',
    );
  }

  @override
  Future<OvertimeDetailData> getOvertimeDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOvertime(String id) async {
    throw UnimplementedError();
  }
}

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('CreateOvertimeScreen Widget Tests', () {
    testWidgets('renders all form sections according to Stitch specifications',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeOvertimeRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          CreateOvertimeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // 1. AppBar
      expect(find.text('Ajukan Lembur'), findsOneWidget);
      expect(find.text('Formulir permohonan lembur karyawan'), findsOneWidget);

      // 2. Sections (Konsisten dengan CreateLeaveScreen)
      expect(find.text('PERIODE & JADWAL LEMBUR'), findsOneWidget);
      expect(find.text('ALASAN / CATATAN'), findsOneWidget);
      expect(find.text('DOKUMEN PENDUKUNG'), findsOneWidget);

      // 3. Fields & Labels
      expect(find.text('Tanggal & Jam Mulai'), findsOneWidget);
      expect(find.text('Tanggal & Jam Selesai'), findsOneWidget);
      expect(find.textContaining('Total Durasi Lembur:'), findsOneWidget);
      expect(find.text('Lampirkan Foto Bukti Lembur'), findsOneWidget);
      expect(find.text('Wajib Diunggah'), findsOneWidget);

      // 4. Submit Button
      expect(find.text('Kirim Pengajuan Lembur'), findsOneWidget);
    });

    testWidgets('shows Pre-Shift banner when startOvertime is earlier than shift start',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeOvertimeRepository(
        scheduleData: const OvertimeScheduleData(
          isGenerated: true,
          isDayOff: false,
          requiresCheckOut: true,
          workScheduleId: 'ws-1',
          schedule: OvertimeScheduleInfoModel(
            id: 'ws-1',
            shift: OvertimeShiftModel(
              id: 's-1',
              startTime: '08:00:00',
              endTime: '17:00:00',
            ),
          ),
          attendance: OvertimeAttendanceInfoModel(
            id: 'a-1',
            checkIn: '06:00:00',
            checkOut: null,
          ),
        ),
      );

      final bloc = CreateOvertimeBloc(repository: repo);
      // Set start waktu lebih pagi dari jam 08:00
      bloc.add(CreateOvertimeStarted(
        initialStartTime: DateTime(2026, 8, 28, 6, 0),
      ));

      await tester.pumpWidget(
        buildTestableWidget(
          CreateOvertimeScreen(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lembur Sebelum Shift (Pre-Shift)'), findsOneWidget);
      expect(
        find.textContaining('foto bukti tugas nyata'),
        findsOneWidget,
      );
    });

    testWidgets('shows Blocked Check-Out banner when post-shift and checkOut is null',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeOvertimeRepository(
        scheduleData: const OvertimeScheduleData(
          isGenerated: true,
          isDayOff: false,
          requiresCheckOut: true,
          workScheduleId: 'ws-1',
          schedule: OvertimeScheduleInfoModel(
            id: 'ws-1',
            shift: OvertimeShiftModel(
              id: 's-1',
              startTime: '08:00:00',
              endTime: '17:00:00',
            ),
          ),
          attendance: OvertimeAttendanceInfoModel(
            id: 'a-1',
            checkIn: '08:00:00',
            checkOut: null, // Belum check-out!
          ),
        ),
      );

      final bloc = CreateOvertimeBloc(repository: repo);
      bloc.add(CreateOvertimeStarted(
        initialStartTime: DateTime(2026, 8, 28, 17, 30),
      ));

      await tester.pumpWidget(
        buildTestableWidget(
          CreateOvertimeScreen(bloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum Melakukan Check-Out'), findsOneWidget);
      expect(find.text('Buka Menu Presensi'), findsOneWidget);
    });

    testWidgets('shows validation warning when submitting without mandatory photo',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeOvertimeRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          CreateOvertimeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Isi alasan
      await tester.enterText(
        find.byKey(const ValueKey('overtime_notes_field')),
        'Pekerjaan deploy production dan verifikasi database',
      );
      await tester.pumpAndSettle();

      // Verifikasi badge 'Wajib Diunggah' ada dan tombol submit dinonaktifkan jika belum ada foto
      expect(find.text('Wajib Diunggah'), findsOneWidget);
      final submitBtn = tester.widget<AppButton>(
        find.byKey(const ValueKey('submit_overtime_btn')),
      );
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('shows help dialog when info icon tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeOvertimeRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          CreateOvertimeScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap help button in AppBar
      await tester.tap(find.byIcon(LucideIcons.helpCircle));
      await tester.pumpAndSettle();
      expect(find.text('Panduan Pengajuan Lembur'), findsOneWidget);
    });
  });
}
