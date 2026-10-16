import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/lifecycle_task_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/pages/evaluation_form_screen.dart';
import 'package:hris_flutter/features/lifecycle/presentation/pages/my_evaluation_detail_screen.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_profile_section.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/lifecycle_task_action_sheet.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/offboarding_status_card.dart';
import 'package:hris_flutter/features/lifecycle/presentation/widgets/onboarding_progress_card.dart';

import 'fake_lifecycle_repository.dart';

const _emp = EvaluationEmployeeBrief(id: 'x', name: 'Budi Santoso', departmentName: 'IT');

EvaluationForm _form({
  bool canEdit = true,
  String status = 'draft',
  String? revision,
  List<EvaluationAnswer> answers = const [],
}) =>
    EvaluationForm(
      id: 'e1',
      referenceNumber: 'EVK-1',
      evaluationType: 'contract_renewal',
      status: status,
      employee: _emp,
      canEdit: canEdit,
      revisionNotes: revision,
      templateName: 'PKWT',
      scaleMin: 1,
      scaleMax: 5,
      scaleLabels: const {'1': 'Buruk', '5': 'Baik'},
      items: const [
        EvaluationTemplateItem(id: 'i1', code: 'p', title: 'Kinerja', isRating: true, weight: 60, isRequired: true),
        EvaluationTemplateItem(id: 'i2', code: 'n', title: 'Catatan', isRating: false, isRequired: false),
      ],
      allowedProposals: const ['extend_contract', 'end_contract'],
      answers: answers,
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink()); // paksa state lama dibuang saat pump berulang
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

LifecycleTaskModel _task({
  String type = 'manual',
  String status = 'pending',
  bool isMine = true,
  bool canComplete = true,
}) =>
    LifecycleTaskModel(
      id: 't1',
      title: 'Tugas A',
      type: type,
      assigneeRole: 'employee',
      isRequired: true,
      status: status,
      isMine: isMine,
      canComplete: canComplete,
    );

void main() {
  group('EvaluationFormScreen', () {
    testWidgets('menampilkan kriteria dinamis; Kirim nonaktif sampai wajib terisi', (tester) async {
      final repo = FakeLifecycleRepository()..form = _form();
      await _pump(tester, EvaluationFormScreen(evaluationId: 'e1', repository: repo));

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Kinerja *', findRichText: true), findsOneWidget);
      expect(find.textContaining('Lengkapi kriteria wajib: Kinerja'), findsOneWidget);
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.byKey(const ValueKey('rating-3')), findsOneWidget);

      final submit = find.widgetWithText(ElevatedButton, 'Kirim Penilaian');
      // tombol aksi ada tetapi dinonaktifkan
      expect(find.text('Kirim Penilaian'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(submit.evaluate().isNotEmpty ? submit : find.byType(ElevatedButton).last).onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('rating-4')));
      await tester.tap(find.byKey(const ValueKey('proposal-extend_contract')));
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
        isNotNull,
      );
      expect(find.textContaining('Skor sementara'), findsOneWidget);
      // hentikan timer debounce agar tidak menggantung
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('catatan revisi HR tampil untuk penilai', (tester) async {
      final repo = FakeLifecycleRepository()
        ..form = _form(status: 'revision_requested', revision: 'Mohon lengkapi bukti');
      await _pump(tester, EvaluationFormScreen(evaluationId: 'e1', repository: repo));
      expect(find.byKey(const ValueKey('revision-banner')), findsOneWidget);
      expect(find.text('Mohon lengkapi bukti'), findsOneWidget);
    });

    testWidgets('form read-only: tanpa tombol Kirim', (tester) async {
      final repo = FakeLifecycleRepository()..form = _form(canEdit: false, status: 'submitted');
      await _pump(tester, EvaluationFormScreen(evaluationId: 'e1', repository: repo));
      expect(find.text('Kirim Penilaian'), findsNothing);
      expect(find.textContaining('tidak dapat diubah'), findsOneWidget);
    });

    testWidgets('error dari server ditampilkan, 404 tanpa tombol coba lagi', (tester) async {
      final repo = FakeLifecycleRepository()
        ..error = const ApiException(message: 'Data tidak ditemukan', statusCode: 404);
      await _pump(tester, EvaluationFormScreen(evaluationId: 'e1', repository: repo));
      expect(find.text('Data tidak ditemukan'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });
  });

  group('MyEvaluationDetailScreen', () {
    const summary = MyEvaluationItem(
      id: 'e9',
      referenceNumber: 'EVK-9',
      evaluationType: 'contract_renewal',
      status: 'decided',
      decision: 'extend_contract',
      overallScore: 4.2,
      bandLabel: 'Memuaskan',
    );

    testWidgets('tombol konfirmasi tampil lalu hilang setelah acknowledge', (tester) async {
      final repo = FakeLifecycleRepository()
        ..myDetail = const MyEvaluationDetail(summary: summary, requiresAcknowledgment: true)
        ..myDetailAfterAck = MyEvaluationDetail(
          summary: const MyEvaluationItem(
            id: 'e9',
            referenceNumber: 'EVK-9',
            evaluationType: 'contract_renewal',
            status: 'decided',
            acknowledged: true,
          ),
          acknowledgedAt: DateTime(2026, 11, 2),
        );
      await _pump(tester, MyEvaluationDetailScreen(evaluationId: 'e9', repository: repo));

      expect(find.text('4.20'), findsOneWidget);
      expect(find.text('Kontrak diperpanjang'), findsOneWidget);
      expect(find.text('Saya sudah membaca'), findsOneWidget);

      await tester.tap(find.text('Saya sudah membaca'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // tutup dialog sukses agar tidak ada timer/animasi tersisa
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(repo.ackCalls, 1);
      expect(find.text('Saya sudah membaca'), findsNothing);
      expect(find.byKey(const ValueKey('ack-status')), findsOneWidget);
    });

    testWidgets('tidak menampilkan catatan internal; tanpa tombol bila sudah dikonfirmasi', (tester) async {
      final repo = FakeLifecycleRepository()
        ..myDetail = MyEvaluationDetail(
          summary: summary,
          acknowledgedAt: DateTime(2026, 11, 2),
        );
      await _pump(tester, MyEvaluationDetailScreen(evaluationId: 'e9', repository: repo));
      expect(find.text('Saya sudah membaca'), findsNothing);
      expect(find.textContaining('catatan HR'), findsNothing);
    });
  });

  group('LifecycleProfileSection', () {
    Future<void> pumpProfile(WidgetTester tester, FakeLifecycleRepository repo) =>
        _pump(tester, Scaffold(body: SingleChildScrollView(child: LifecycleProfileSection(repository: repo))));

    testWidgets('terisi: kontrak aktif, bar PKWT, riwayat kontrak, linimasa karier', (tester) async {
      final repo = FakeLifecycleRepository()
        ..contracts = ContractOverviewModel(
          activeContract: ActiveContractModel(
            id: 'c1',
            contractNumber: 'PKWT-1',
            type: 'pkwt',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 11, 5),
            daysUntilExpiry: 20,
            isNearExpiry: true,
          ),
          contracts: [
            ContractHistoryItem(
              id: 'c1',
              contractNumber: 'PKWT-1',
              sequence: 1,
              type: 'pkwt',
              status: 'active',
              startDate: DateTime(2026, 1, 1),
              endDate: DateTime(2026, 11, 5),
            ),
          ],
          pkwtSummary: const PkwtSummary(totalPkwtMonths: 10, maxContractMonths: 60, pkwtMonthsRemaining: 50),
        )
        ..career = [
          CareerHistoryItem(
            id: 'h1',
            changeType: 'promotion',
            effectiveDate: DateTime(2026, 3, 1),
            companyName: 'PT A',
            departmentName: 'IT',
            positionName: 'Lead',
            prevCompanyName: 'PT A',
            prevDepartmentName: 'IT',
            prevPositionName: 'Staff',
          ),
        ];
      await pumpProfile(tester, repo);
      expect(find.byKey(const ValueKey('contracts-card')), findsOneWidget);
      expect(find.text('Segera berakhir'), findsOneWidget);
      expect(find.text('Sisa 20 hari'), findsOneWidget);
      expect(find.text('10 dari 60 bulan'), findsOneWidget);
      expect(find.text('Promosi'), findsOneWidget);
      expect(find.text('Staff → Lead'), findsOneWidget);
      // tidak ada gaji
      expect(find.textContaining('Rp'), findsNothing);
      expect(find.textContaining('Gaji'), findsNothing);
    });

    testWidgets('kosong', (tester) async {
      await pumpProfile(tester, FakeLifecycleRepository());
      expect(find.byKey(const ValueKey('lifecycle-profile-empty')), findsOneWidget);
    });

    testWidgets('error total + coba lagi', (tester) async {
      final repo = FakeLifecycleRepository()
        ..contractsError = const ApiException(message: 'Gagal kontrak')
        ..careerError = const ApiException(message: 'Gagal karier');
      await pumpProfile(tester, repo);
      expect(find.byKey(const ValueKey('lifecycle-profile-error')), findsOneWidget);
      expect(find.text('Gagal kontrak'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });

  group('OffboardingStatusCard', () {
    OffboardingStatusModel off({bool settled = false}) => OffboardingStatusModel(
          id: 'off1',
          referenceNumber: 'OFB-1',
          exitType: 'resignation',
          status: settled ? 'settled' : 'pending_clearance',
          lastWorkingDate: DateTime(2026, 10, 30),
          effectiveExitDate: DateTime(2026, 10, 31),
          progress: const LifecycleProgress(done: 1, total: 2, requiredDone: 1, requiredTotal: 2),
          tasks: [_task(status: 'done'), _task(isMine: false, canComplete: false)],
          paklaring: PaklaringInfo(
            issued: settled,
            number: settled ? 'PKL-1' : null,
            issuedAt: settled ? DateTime(2026, 11, 2) : null,
          ),
        );

    testWidgets('timeline tanggal, clearance, dan tanpa nominal', (tester) async {
      await _pump(
        tester,
        Scaffold(body: SingleChildScrollView(child: OffboardingStatusCard(offboarding: off(), onTaskChanged: () {}))),
      );
      expect(find.text('Menunggu clearance'), findsOneWidget);
      expect(find.text('30 Okt 2026'), findsOneWidget);
      expect(find.text('1 dari 2 selesai'), findsOneWidget);
      expect(find.byKey(const ValueKey('paklaring-info')), findsNothing);
      expect(find.textContaining('Rp'), findsNothing);
    });

    testWidgets('paklaring tampil saat settled', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: OffboardingStatusCard(offboarding: off(settled: true), onTaskChanged: () {}),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('paklaring-info')), findsOneWidget);
      expect(find.textContaining('PKL-1'), findsOneWidget);
    });
  });

  group('OnboardingProgressCard (dashboard)', () {
    testWidgets('muncul dengan progres, tersembunyi bila tidak ada / gagal', (tester) async {
      final repo = FakeLifecycleRepository()
        ..onboarding = const OnboardingProgressModel(
          id: 'o1',
          referenceNumber: 'ONB-1',
          status: 'in_progress',
          progress: LifecycleProgress(done: 2, total: 5, requiredDone: 2, requiredTotal: 4),
        );
      await _pump(tester, Scaffold(body: OnboardingProgressCard(repository: repo)));
      expect(find.text('Lengkapi data Anda (2 dari 5)'), findsOneWidget);

      final none = FakeLifecycleRepository();
      await _pump(tester, Scaffold(body: OnboardingProgressCard(repository: none)));
      expect(find.textContaining('Lengkapi data Anda'), findsNothing);

      final failing = FakeLifecycleRepository()..error = const ApiException(message: 'offline');
      await _pump(tester, Scaffold(body: OnboardingProgressCard(repository: failing)));
      expect(find.textContaining('Lengkapi data Anda'), findsNothing);
    });

    testWidgets('selesai (done == total) → kartu hilang', (tester) async {
      final repo = FakeLifecycleRepository()
        ..onboarding = const OnboardingProgressModel(
          id: 'o1',
          referenceNumber: 'ONB-1',
          status: 'in_progress',
          progress: LifecycleProgress(done: 5, total: 5, requiredDone: 4, requiredTotal: 4),
        );
      await _pump(tester, Scaffold(body: OnboardingProgressCard(repository: repo)));
      expect(find.textContaining('Lengkapi data Anda'), findsNothing);
    });
  });

  group('LifecycleTaskActionSheet per tipe task', () {
    Future<FakeLifecycleRepository> pumpSheet(WidgetTester tester, LifecycleTaskModel task) async {
      final repo = FakeLifecycleRepository();
      await _pump(
        tester,
        Scaffold(
          body: BlocProvider(
            create: (_) => TaskActionCubit(repository: repo),
            child: SingleChildScrollView(child: LifecycleTaskActionSheet(task: task)),
          ),
        ),
      );
      return repo;
    }

    testWidgets('acknowledgment → tombol Setuju menyelesaikan tugas', (tester) async {
      final repo = await pumpSheet(tester, _task(type: 'acknowledgment'));
      await tester.tap(find.text('Setuju'));
      await tester.pump();
      expect(repo.completedTasks, ['t1']);
    });

    testWidgets('manual → Tandai Selesai', (tester) async {
      final repo = await pumpSheet(tester, _task());
      await tester.tap(find.text('Tandai Selesai'));
      await tester.pump();
      expect(repo.completedTasks, ['t1']);
    });

    testWidgets('system_check → hanya status, tanpa tombol selesai', (tester) async {
      await pumpSheet(tester, _task(type: 'system_check', canComplete: false));
      expect(find.text('Tandai Selesai'), findsNothing);
      expect(find.text('Setuju'), findsNothing);
      expect(find.text('Buka Profil'), findsOneWidget);
    });

    testWidgets('document_upload → informasi (unggah belum didukung di mobile)', (tester) async {
      await pumpSheet(tester, _task(type: 'document_upload'));
      expect(find.text('Tandai Selesai'), findsNothing);
      expect(find.textContaining('unggahan berkas'), findsOneWidget);
    });

    testWidgets('bukan milik saya atau sudah selesai → tanpa tombol', (tester) async {
      await pumpSheet(tester, _task(isMine: false, canComplete: false));
      expect(find.text('Tandai Selesai'), findsNothing);
      await pumpSheet(tester, _task(status: 'done'));
      expect(find.text('Tandai Selesai'), findsNothing);
    });
  });
}
