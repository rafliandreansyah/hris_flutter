import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/live_attendance_screen.dart';

class _FakeAttendanceRequestRepo extends Fake implements AttendanceRequestRepository {
  LiveAttendanceRequest? submitted;

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
    submitted = request;
    return const LiveAttendanceResponse(
      success: true,
      message: 'Presensi live berhasil dikirim.',
      data: LiveAttendanceData(id: 'live-test-id'),
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
  });

  group('LiveAttendanceScreen Widget Tests', () {
    testWidgets('merender AppBar dengan judul Presensi Luar (Live) dan subtitle', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
      );

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Presensi Luar (Live)'), findsOneWidget);
      expect(find.text('Check-in / Check-out real-time di lokasi tugas'), findsOneWidget);

      bloc.close();
    });

    testWidgets('merender Card 1: Banner jam WIB dan switcher Masuk/Pulang', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
      );

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sinkronisasi Waktu Server Standar WIB'), findsOneWidget);
      expect(find.byKey(const Key('live-attendance-clock-text')), findsOneWidget);
      expect(find.text('Absen Masuk (In)'), findsOneWidget);
      expect(find.text('Absen Pulang (Out)'), findsOneWidget);

      // Tapping Absen Pulang (Out)
      await tester.tap(find.byKey(const Key('live-attendance-type-out')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(bloc.state.attendanceType, 'out');

      // Tapping Absen Masuk (In)
      await tester.tap(find.byKey(const Key('live-attendance-type-in')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(bloc.state.attendanceType, 'in');

      bloc.close();
    });

    testWidgets('merender Card 2: Peta GPS dengan chip koordinat dan TANPA alamat statis', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
      );

      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±3m',
      ));

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lokasi Presensi'), findsOneWidget);
      expect(find.text('Real-time'), findsOneWidget);
      expect(find.byKey(const Key('live-attendance-refresh-gps-button')), findsOneWidget);
      expect(find.text('Perbarui Koordinat GPS'), findsOneWidget);

      // Memastikan chip koordinat tampil
      expect(find.textContaining('6.2297'), findsOneWidget);
      expect(find.textContaining('106.8166'), findsOneWidget);

      // Memastikan TIDAK ADA teks alamat statis pada kartu peta (sesuai instruksi user)
      expect(find.textContaining('Menara Mandiri, Jl. Jend. Sudirman'), findsNothing);

      bloc.close();
    });

    testWidgets('mode photo: merender section foto selfie strict camera dan badge photo', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
      );

      bloc.add(const LiveAttendanceStarted(initialMethod: 'photo'));

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Metode: Photo Verification'), findsOneWidget);
      expect(find.textContaining('Foto Bukti Kehadiran / Selfie'), findsOneWidget);
      expect(find.byKey(const Key('live-attendance-camera-trigger')), findsOneWidget);
      expect(find.text('Ketuk untuk Ambil Foto Selfie via Kamera'), findsOneWidget);

      // Memastikan section biometrik TIDAK dirender pada mode photo
      expect(find.text('Verifikasi Identitas Biometrik'), findsNothing);

      bloc.close();
    });

    testWidgets('mode biometric: merender section biometrik dan TIDAK merender box foto', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
      );

      bloc.add(const LiveAttendanceStarted(initialMethod: 'biometric'));

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Metode: Biometric Verification'), findsOneWidget);
      expect(find.text('Verifikasi Identitas Biometrik'), findsOneWidget);
      expect(find.text('Autentikasi Sidik Jari / Face ID'), findsOneWidget);

      // Memastikan box upload foto selfie TIDAK dirender pada mode biometric (sesuai instruksi)
      expect(find.byKey(const Key('live-attendance-camera-trigger')), findsNothing);
      expect(find.text('Metode: Photo Verification'), findsNothing);

      bloc.close();
    });

    testWidgets('menampilkan validasi warning saat alasan belum diisi', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
      );

      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±3m',
      ));

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Kirim Presensi Live Sekarang tanpa mengisi alasan
      await tester.tap(find.byKey(const Key('live-attendance-submit-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Form Belum Lengkap'), findsOneWidget);
      expect(find.text('Alasan presensi luar kantor wajib diisi.'), findsOneWidget);

      bloc.close();
    });

    testWidgets('mode photo: menampilkan warning saat foto belum diambil', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
      );

      bloc.add(const LiveAttendanceStarted(initialMethod: 'photo'));
      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±3m',
      ));

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Isi teks alasan
      await tester.enterText(
        find.byKey(const Key('live-attendance-reason-input')),
        'Supervisi instalasi jaringan kantor cabang',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Kirim
      await tester.tap(find.byKey(const Key('live-attendance-submit-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Foto Belum Diambil'), findsOneWidget);
      expect(find.text('Foto bukti kehadiran / selfie wajib diambil menggunakan kamera.'), findsOneWidget);

      bloc.close();
    });

    testWidgets('mode biometric: berhasil memicu biometrik dan submit ke server', (tester) async {
      final repo = _FakeAttendanceRequestRepo();
      final bloc = LiveAttendanceBloc(
        repository: repo,
        autoStartTimer: false,
        addressFetcher: ({required latitude, required longitude}) async {
          return 'SCBD Sudirman Jakarta';
        },
      );

      bloc.add(const LiveAttendanceStarted(initialMethod: 'biometric'));
      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±3m',
      ));

      // Mock biometric authenticate agar mengembalikan true
      BiometricService.testAuthenticateHandler = ({String localizedReason = ''}) async => true;

      await tester.pumpWidget(
        _wrapWidget(LiveAttendanceScreen(bloc: bloc)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Isi teks alasan
      await tester.enterText(
        find.byKey(const Key('live-attendance-reason-input')),
        'Audit sistem finansial client SCBD',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Kirim
      await tester.tap(find.byKey(const Key('live-attendance-submit-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Memastikan dialog sukses muncul
      expect(find.text('Presensi Live Berhasil'), findsOneWidget);
      expect(find.text('Presensi live berhasil dikirim.'), findsOneWidget);
      expect(repo.submitted, isNotNull);
      expect(repo.submitted!.attendanceMethod, 'biometric');
      expect(repo.submitted!.file, isNull);
      expect(repo.submitted!.address, 'SCBD Sudirman Jakarta');

      BiometricService.testAuthenticateHandler = null;
      bloc.close();
    });
  });
}
