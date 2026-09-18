import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_request.dart';
import 'package:hris_flutter/features/attendance/data/models/live_attendance_response.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_state.dart';
import 'package:image_picker/image_picker.dart';

class _MockAttendanceRequestRepo extends Fake implements AttendanceRequestRepository {
  LiveAttendanceRequest? lastSubmittedRequest;
  bool shouldThrow = false;
  String errorMessage = 'Gagal mengirim data';

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
    lastSubmittedRequest = request;
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 400);
    }
    return const LiveAttendanceResponse(
      success: true,
      message: 'Presensi live berhasil dikirim.',
      data: LiveAttendanceData(id: 'res-live-123'),
    );
  }
}

void main() {
  final initialTime = DateTime(2026, 8, 29, 23, 51);

  group('LiveAttendanceBloc Unit Tests', () {
    late _MockAttendanceRequestRepo mockRepo;

    setUp(() {
      mockRepo = _MockAttendanceRequestRepo();
    });

    test('state awal terinisialisasi dengan benar', () {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      expect(bloc.state.attendanceMethod, 'photo');
      expect(bloc.state.attendanceType, 'in');
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.submissionSuccess, isFalse);
      expect(bloc.state.isPhotoMethod, isTrue);
      expect(bloc.state.isBiometricMethod, isFalse);

      bloc.close();
    });

    test('LiveAttendanceStarted mengubah attendanceMethod jika initialMethod disertakan', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<LiveAttendanceState>((s) =>
              s.attendanceMethod == 'biometric' &&
              s.isBiometricMethod &&
              !s.isPhotoMethod),
        ),
      );

      bloc.add(const LiveAttendanceStarted(initialMethod: 'biometric'));
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceClockTicked memperbarui currentClockTime', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      final targetTime = DateTime(2026, 8, 29, 23, 52);
      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<LiveAttendanceState>((s) => s.currentClockTime == targetTime),
        ),
      );

      bloc.add(LiveAttendanceClockTicked(targetTime));
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceTypeChanged beralih antara "in" dan "out"', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<LiveAttendanceState>((s) => s.attendanceType == 'out'),
        ),
      );

      bloc.add(const LiveAttendanceTypeChanged('out'));
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceLocationUpdated memperbarui koordinat dan akurasi GPS', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<LiveAttendanceState>((s) =>
              s.latitude == -6.2297 &&
              s.longitude == 106.8166 &&
              s.gpsAccuracy == '±2m' &&
              !s.isLocating &&
              s.hasValidCoordinates),
        ),
      );

      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±2m',
      ));
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceReasonChanged dan LiveAttendancePhotoChanged memperbarui state form', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<LiveAttendanceState>(
              (s) => s.reason == 'Meeting klien di Sudirman'),
          predicate<LiveAttendanceState>(
              (s) => s.photo?.path == 'path/selfie.jpg'),
        ]),
      );

      bloc.add(const LiveAttendanceReasonChanged('Meeting klien di Sudirman'));
      bloc.add(LiveAttendancePhotoChanged(XFile('path/selfie.jpg')));
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceSubmitted gagal validasi jika koordinat belum terdeteksi', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      final expectation = expectLater(
        bloc.stream,
        emits(
          predicate<LiveAttendanceState>((s) =>
              s.errorMessage != null &&
              s.errorMessage!.contains('Koordinat GPS belum ditemukan')),
        ),
      );

      bloc.add(const LiveAttendanceSubmitted());
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceSubmitted gagal validasi jika alasan kosong', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±2m',
      ));

      final expectation = expectLater(
        bloc.stream.skip(1), // lewati state location update
        emits(
          predicate<LiveAttendanceState>((s) =>
              s.errorMessage != null &&
              s.errorMessage!.contains('Alasan presensi luar kantor wajib diisi')),
        ),
      );

      bloc.add(const LiveAttendanceSubmitted());
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceSubmitted mode photo gagal jika foto belum diambil', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
      );

      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±2m',
      ));
      bloc.add(const LiveAttendanceReasonChanged('Meeting Sudirman'));

      final expectation = expectLater(
        bloc.stream.skip(2), // lewati location & reason update
        emits(
          predicate<LiveAttendanceState>((s) =>
              s.errorMessage != null &&
              s.errorMessage!.contains('Foto bukti kehadiran / selfie wajib diambil')),
        ),
      );

      bloc.add(const LiveAttendanceSubmitted());
      await expectation;
      await bloc.close();
    });

    test('LiveAttendanceSubmitted mode photo berhasil mengirim data ke server', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
        addressFetcher: ({required latitude, required longitude}) async {
          return 'Menara Mandiri, Jl. Jend. Sudirman, Jakarta Selatan';
        },
      );

      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±2m',
      ));
      bloc.add(const LiveAttendanceReasonChanged('Tugas monitoring lapangan'));
      bloc.add(LiveAttendancePhotoChanged(XFile('test/selfie.jpg')));

      final expectation = expectLater(
        bloc.stream.skip(3),
        emitsInOrder([
          predicate<LiveAttendanceState>((s) => s.isSubmitting && s.errorMessage == null),
          predicate<LiveAttendanceState>((s) =>
              !s.isSubmitting &&
              s.submissionSuccess &&
              s.successMessage == 'Presensi live berhasil dikirim.' &&
              s.submissionResult?.id == 'res-live-123'),
        ]),
      );

      bloc.add(const LiveAttendanceSubmitted());
      await expectation;

      expect(mockRepo.lastSubmittedRequest, isNotNull);
      expect(mockRepo.lastSubmittedRequest!.attendanceMethod, 'photo');
      expect(mockRepo.lastSubmittedRequest!.attendanceType, 'in');
      expect(mockRepo.lastSubmittedRequest!.address,
          'Menara Mandiri, Jl. Jend. Sudirman, Jakarta Selatan');
      expect(mockRepo.lastSubmittedRequest!.reason, 'Tugas monitoring lapangan');
      expect(mockRepo.lastSubmittedRequest!.file?.path, 'test/selfie.jpg');

      await bloc.close();
    });

    test('LiveAttendanceSubmitted mode biometric berhasil tanpa foto', () async {
      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
        addressFetcher: ({required latitude, required longitude}) async {
          return 'Kawasan SCBD Jakarta';
        },
      );

      bloc.add(const LiveAttendanceStarted(initialMethod: 'biometric'));
      bloc.add(const LiveAttendanceTypeChanged('out'));
      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±2m',
      ));
      bloc.add(const LiveAttendanceReasonChanged('Selesai tugas audit'));

      final expectation = expectLater(
        bloc.stream.skip(4),
        emitsInOrder([
          predicate<LiveAttendanceState>((s) => s.isSubmitting),
          predicate<LiveAttendanceState>(
              (s) => !s.isSubmitting && s.submissionSuccess),
        ]),
      );

      bloc.add(const LiveAttendanceSubmitted());
      await expectation;

      expect(mockRepo.lastSubmittedRequest, isNotNull);
      expect(mockRepo.lastSubmittedRequest!.attendanceMethod, 'biometric');
      expect(mockRepo.lastSubmittedRequest!.file, isNull);
      expect(mockRepo.lastSubmittedRequest!.address, 'Kawasan SCBD Jakarta');

      await bloc.close();
    });

    test('LiveAttendanceSubmitted menangani error ApiException dengan benar', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Lokasi GPS tidak valid atau di luar zona';

      final bloc = LiveAttendanceBloc(
        repository: mockRepo,
        initialTime: initialTime,
        autoStartTimer: false,
        addressFetcher: ({required latitude, required longitude}) async =>
            'Jl. Sudirman',
      );

      bloc.add(const LiveAttendanceStarted(initialMethod: 'biometric'));
      bloc.add(const LiveAttendanceLocationUpdated(
        latitude: -6.2297,
        longitude: 106.8166,
        accuracy: '±2m',
      ));
      bloc.add(const LiveAttendanceReasonChanged('Testing error'));

      final expectation = expectLater(
        bloc.stream.skip(3),
        emitsInOrder([
          predicate<LiveAttendanceState>((s) => s.isSubmitting),
          predicate<LiveAttendanceState>((s) =>
              !s.isSubmitting &&
              !s.submissionSuccess &&
              s.errorMessage == 'Lokasi GPS tidak valid atau di luar zona'),
        ]),
      );

      bloc.add(const LiveAttendanceSubmitted());
      await expectation;
      await bloc.close();
    });
  });
}
