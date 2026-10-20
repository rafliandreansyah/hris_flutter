import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/approver_share/data/datasources/approver_share_remote_datasource.dart';
import 'package:hris_flutter/features/approver_share/data/models/approver_model.dart';
import 'package:hris_flutter/features/approver_share/domain/repositories/approver_share_repository.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_bloc.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_event.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_state.dart';

import '../../helpers/recording_api_client.dart';

class _FakeRepo implements ApproverShareRepository {
  List<ApproverModel> approvers = const [];
  Exception? error;
  final calls = <String>[];

  @override
  Future<List<ApproverModel>> getApprovers({
    required String module,
    required String requestId,
  }) async {
    calls.add('$module:$requestId');
    if (error != null) throw error!;
    return approvers;
  }
}

const _approver = ApproverModel(
  id: 'e1',
  fullName: 'Siti Atasan',
  phone: '08123',
  email: 'siti@kantor.id',
);

void main() {
  group('ApproverShareBloc', () {
    late _FakeRepo repo;
    late ApproverShareBloc bloc;

    setUp(() {
      repo = _FakeRepo();
      bloc = ApproverShareBloc(repository: repo);
    });

    tearDown(() => bloc.close());

    test('initial state adalah ApproverShareInitial', () {
      expect(bloc.state, const ApproverShareInitial());
    });

    test('FetchApprovers emit loading lalu loaded', () async {
      repo.approvers = const [_approver];
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder(const [
          ApproverShareLoading(),
          ApproverShareLoaded([_approver]),
        ]),
      );
      bloc.add(const FetchApprovers(module: 'leave', requestId: 'l1'));
      await expectation;
      expect(repo.calls, ['leave:l1']);
    });

    test('FetchApprovers emit loaded kosong bila tidak ada atasan', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder(const [ApproverShareLoading(), ApproverShareLoaded([])]),
      );
      bloc.add(const FetchApprovers(module: 'leave', requestId: 'l1'));
      await expectation;
    });

    test('ApiException diteruskan sebagai error dengan message & statusCode',
        () async {
      repo.error = const ApiException(message: 'Akses ditolak', statusCode: 403);
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder(const [
          ApproverShareLoading(),
          ApproverShareError(message: 'Akses ditolak', statusCode: 403),
        ]),
      );
      bloc.add(const FetchApprovers(module: 'leave', requestId: 'l1'));
      await expectation;
    });

    test('RefreshApprovers memuat ulang tanpa state loading', () async {
      bloc.add(const FetchApprovers(module: 'overtime', requestId: 'o1'));
      await bloc.stream.firstWhere((s) => s is ApproverShareLoaded);

      repo.approvers = const [_approver];
      final expectation = expectLater(
        bloc.stream,
        emits(const ApproverShareLoaded([_approver])),
      );
      bloc.add(const RefreshApprovers());
      await expectation;
      expect(repo.calls, ['overtime:o1', 'overtime:o1']);
    });

    test('RefreshApprovers sebelum fetch tidak melakukan apa-apa', () async {
      bloc.add(const RefreshApprovers());
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, isEmpty);
      expect(bloc.state, const ApproverShareInitial());
    });
  });

  group('ApproverShareRemoteDataSource', () {
    test('memanggil GET /approvers dengan module & id lalu mem-parsing data',
        () async {
      final client = RecordingApiClient()
        ..responseData = {
          'data': [
            {
              'id': 'e1',
              'fullName': 'Siti Atasan',
              'employeeNumber': 'EMP-01',
              'position': {'name': 'Manager'},
              'department': 'HR',
              'phone': '08123',
              'email': 'siti@kantor.id',
            },
          ],
        };
      final ds = ApproverShareRemoteDataSourceImpl(apiClient: client);

      final result = await ds.getApprovers(module: 'leave', requestId: 'l1');

      expect(client.last.method, 'GET');
      expect(client.last.path, ApiEndpoints.approvers);
      expect(client.last.queryParameters, {'module': 'leave', 'id': 'l1'});
      expect(result.single.fullName, 'Siti Atasan');
      expect(result.single.position, 'Manager');
      expect(result.single.department, 'HR');
      expect(result.single.hasPhone, isTrue);
      expect(result.single.hasEmail, isTrue);
    });

    test('kontak kosong terbaca sebagai tidak tersedia', () {
      final model = ApproverModel.fromJson(
          const {'id': 'e2', 'fullName': 'Budi', 'phone': ' ', 'email': null});
      expect(model.hasPhone, isFalse);
      expect(model.hasEmail, isFalse);
    });
  });
}
