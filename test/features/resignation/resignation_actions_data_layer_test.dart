import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/resignation/data/datasources/resignation_remote_datasource.dart';
import 'package:hris_flutter/features/resignation/data/models/exit_interview_request_model.dart';
import 'package:hris_flutter/features/resignation/data/repositories/resignation_repository_impl.dart';

import '../../helpers/recording_api_client.dart';

void main() {
  late RecordingApiClient api;
  late ResignationRemoteDataSourceImpl dataSource;

  setUp(() {
    api = RecordingApiClient()..responseData = {'success': true};
    dataSource = ResignationRemoteDataSourceImpl(apiClient: api);
  });

  group('ExitInterviewRequestModel.toJson', () {
    test('hanya mengirim rating yang diisi dan men-trim teks', () {
      const model = ExitInterviewRequestModel(
        satisfactionCulture: 4,
        satisfactionWorkLifeBalance: 2,
        reasonFeedback: '  Ingin pindah ',
        suggestions: '   ',
        wouldRecommend: false,
        isAnonymous: true,
      );

      expect(model.toJson(), {
        'satisfactionCulture': 4,
        'satisfactionWorkLifeBalance': 2,
        'reasonFeedback': 'Ingin pindah',
        'wouldRecommend': false,
        'isAnonymous': true,
        'isSkipped': false,
      });
    });

    test('saran terisi ikut dikirim; skipped() menandai isSkipped', () {
      expect(
        const ExitInterviewRequestModel(suggestions: ' Perbaiki onboarding ')
            .toJson()['suggestions'],
        'Perbaiki onboarding',
      );
      expect(const ExitInterviewRequestModel.skipped().toJson()['isSkipped'], isTrue);
    });
  });

  group('ResignationRemoteDataSourceImpl (aksi baru)', () {
    test('approve: POST ke endpoint approve dengan catatan ter-trim & early notice', () async {
      await dataSource.approveSubordinateResignation(
        'sub-1',
        managerNotes: '  Sudah 1-on-1  ',
        approveEarlyNotice: false,
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, ApiEndpoints.subordinateResignationApprove('sub-1'));
      expect(api.last.path, '/resignations/subordinates/sub-1/approve');
      expect(api.last.data, {
        'managerNotes': 'Sudah 1-on-1',
        'approveEarlyNotice': false,
      });
    });

    test('reject: POST ke endpoint reject dengan alasan ter-trim', () async {
      await dataSource.rejectSubordinateResignation(
        'sub-2',
        rejectionReason: ' Proyek kritis ',
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, '/resignations/subordinates/sub-2/reject');
      expect(api.last.data, {'rejectionReason': 'Proyek kritis'});
    });

    test('exit interview: POST ke /resignations/my/exit-interview', () async {
      await dataSource.submitExitInterview(
        const ExitInterviewRequestModel(
          satisfactionManager: 5,
          reasonFeedback: 'Pindah kota',
        ),
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, ApiEndpoints.resignationExitInterview);
      expect(api.last.data['satisfactionManager'], 5);
      expect(api.last.data['reasonFeedback'], 'Pindah kota');
    });

    test('success=false memakai pesan backend, atau pesan default bila kosong', () async {
      api.responseData = {'success': false, 'message': 'Sudah diproses'};
      await expectLater(
        dataSource.approveSubordinateResignation('x', managerNotes: 'ok ok'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'Sudah diproses'),
        ),
      );

      api.responseData = {'success': false};
      await expectLater(
        dataSource.rejectSubordinateResignation('x', rejectionReason: 'alasan'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Gagal menolak pengajuan resign.',
          ),
        ),
      );
    });

    test('ApiException 403/404 dari ApiClient diteruskan (message + statusCode)', () async {
      api.errorToThrow = const ApiException(
        message: 'Bukan atasan langsung',
        statusCode: 403,
      );

      await expectLater(
        dataSource.approveSubordinateResignation('x', managerNotes: 'catatan'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Bukan atasan langsung'),
        ),
      );

      api.errorToThrow = const ApiException(
        message: 'Pengajuan tidak ditemukan',
        statusCode: 404,
      );
      await expectLater(
        dataSource.submitExitInterview(const ExitInterviewRequestModel()),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('ResignationRepositoryImpl (aksi baru)', () {
    test('mendelegasikan approve, reject, dan exit interview ke datasource', () async {
      final repository = ResignationRepositoryImpl(remoteDataSource: dataSource);

      await repository.approveSubordinateResignation('a', managerNotes: 'catatan 1');
      expect(api.last.path, ApiEndpoints.subordinateResignationApprove('a'));
      expect(api.last.data['approveEarlyNotice'], isTrue);

      await repository.rejectSubordinateResignation('b', rejectionReason: 'alasan 2');
      expect(api.last.path, ApiEndpoints.subordinateResignationReject('b'));

      await repository.submitExitInterview(const ExitInterviewRequestModel.skipped());
      expect(api.last.path, ApiEndpoints.resignationExitInterview);
      expect(api.last.data['isSkipped'], isTrue);
    });
  });
}
