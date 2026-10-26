import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/team_expiring_contracts_cubit.dart';
import 'package:hris_flutter/features/lifecycle/presentation/pages/team_expiring_contracts_screen.dart';

import 'fake_lifecycle_repository.dart';

TeamExpiringContract _item({String? evaluationId = 'ev1', int days = 10}) =>
    TeamExpiringContract(
      contractId: 'k1',
      contractNumber: 'K-1',
      type: 'pkwt',
      endDate: DateTime(2026, 11, 5),
      daysRemaining: days,
      evaluationId: evaluationId,
      employeeId: 'e2',
      employeeName: 'Budi Santoso',
      positionName: 'Staf IT',
    );

void main() {
  group('TeamExpiringContract.fromJson', () {
    test('memetakan respons API', () {
      final m = TeamExpiringContract.fromJson(const {
        'contractId': 'k1',
        'contractNumber': 'K-1',
        'type': 'pkwt',
        'endDate': '2026-11-05',
        'daysRemaining': 10,
        'evaluationId': null,
        'employee': {'id': 'e2', 'name': 'Budi', 'positionName': 'Staf'},
      });
      expect(m.employeeName, 'Budi');
      expect(m.daysRemaining, 10);
      expect(m.evaluationId, isNull);
      expect(m.endDate, DateTime(2026, 11, 5));
    });
  });

  group('TeamExpiringContractsCubit', () {
    test('memuat dengan jendela 30 hari', () async {
      final repo = FakeLifecycleRepository()..teamExpiring = [_item()];
      final cubit = TeamExpiringContractsCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.items, hasLength(1));
      expect(repo.teamExpiringDays, [30]);
    });

    test('403 diteruskan beserta pesan API', () async {
      final repo = FakeLifecycleRepository()
        ..teamExpiringError = const ApiException(message: 'Dilarang', statusCode: 403);
      final cubit = TeamExpiringContractsCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorStatusCode, 403);
      expect(cubit.state.errorMessage, 'Dilarang');
    });
  });

  group('TeamExpiringContractsScreen', () {
    Future<void> pump(WidgetTester tester, FakeLifecycleRepository repo, {bool? access}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TeamExpiringContractsScreen(repository: repo, hasAccessOverride: access),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan kontrak bawahan beserta sisa hari', (tester) async {
      await pump(tester, FakeLifecycleRepository()..teamExpiring = [_item()]);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Sisa 10 hari'), findsOneWidget);
      expect(find.text('Lihat Evaluasi'), findsOneWidget);
    });

    testWidgets('kosong → state kosong', (tester) async {
      await pump(tester, FakeLifecycleRepository());
      expect(find.text('Tidak Ada Kontrak yang Segera Berakhir'), findsOneWidget);
    });

    testWidgets('tanpa akses → forbidden dan tidak memanggil API', (tester) async {
      final repo = FakeLifecycleRepository()..teamExpiring = [_item()];
      await pump(tester, repo, access: false);
      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(repo.teamExpiringDays, isEmpty);
    });

    testWidgets('403 dari server → forbidden', (tester) async {
      final repo = FakeLifecycleRepository()
        ..teamExpiringError = const ApiException(message: 'Dilarang', statusCode: 403);
      await pump(tester, repo);
      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);
    });
  });
}
