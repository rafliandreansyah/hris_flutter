import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/evaluation_assigned_bloc.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/evaluation_form_bloc.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/lifecycle_profile_cubit.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/lifecycle_task_cubits.dart';
import 'package:hris_flutter/features/lifecycle/presentation/bloc/my_evaluation_cubits.dart';

import 'fake_lifecycle_repository.dart';

const _employee = EvaluationEmployeeBrief(id: 'x', name: 'Budi');

EvaluationAssignedItem _assigned(String id) => EvaluationAssignedItem(
      id: id,
      referenceNumber: 'EVK-$id',
      evaluationType: 'contract_renewal',
      status: 'draft',
      employee: _employee,
    );

EvaluationForm _form({bool canEdit = true, List<EvaluationAnswer> answers = const []}) =>
    EvaluationForm(
      id: 'e1',
      referenceNumber: 'EVK-1',
      evaluationType: 'contract_renewal',
      status: canEdit ? 'draft' : 'submitted',
      employee: _employee,
      canEdit: canEdit,
      templateName: 'PKWT',
      scaleMin: 1,
      scaleMax: 5,
      items: const [
        EvaluationTemplateItem(id: 'i1', code: 'p', title: 'Kinerja', isRating: true, weight: 60, isRequired: true),
        EvaluationTemplateItem(id: 'i2', code: 'a', title: 'Sikap', isRating: true, weight: 40, isRequired: true),
        EvaluationTemplateItem(id: 'i3', code: 'n', title: 'Catatan', isRating: false, isRequired: false),
      ],
      allowedProposals: const ['extend_contract', 'end_contract'],
      answers: answers,
    );

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  group('EvaluationAssignedBloc', () {
    test('load → success, ganti filter memuat ulang, load more menambah halaman', () async {
      final repo = FakeLifecycleRepository()
        ..assignedPage = EvaluationAssignedPage(
          items: [_assigned('1')],
          total: 2,
          page: 1,
          totalPages: 2,
        );
      final bloc = EvaluationAssignedBloc(repository: repo)
        ..add(const EvaluationAssignedStarted());
      await _settle();
      expect(bloc.state.status, EvaluationAssignedStatus.success);
      expect(bloc.state.items, hasLength(1));
      expect(bloc.state.hasMore, true);

      repo.assignedPage = EvaluationAssignedPage(
        items: [_assigned('2')],
        total: 2,
        page: 2,
        totalPages: 2,
      );
      bloc.add(const EvaluationAssignedLoadMore());
      await _settle();
      expect(bloc.state.items.map((e) => e.id), ['1', '2']);
      expect(bloc.state.hasMore, false);
      expect(repo.assignedPages.last, 2);

      bloc.add(const EvaluationAssignedFilterChanged('history'));
      await _settle();
      expect(bloc.state.filter, 'history');
      expect(repo.assignedCalls.last, 'history');
      await bloc.close();
    });

    test('error API → failure dengan pesan & status code dari server', () async {
      final repo = FakeLifecycleRepository()
        ..error = const ApiException(message: 'Data tidak ditemukan', statusCode: 404);
      final bloc = EvaluationAssignedBloc(repository: repo)
        ..add(const EvaluationAssignedStarted());
      await _settle();
      expect(bloc.state.status, EvaluationAssignedStatus.failure);
      expect(bloc.state.errorMessage, 'Data tidak ditemukan');
      expect(bloc.state.errorStatusCode, 404);
      await bloc.close();
    });
  });

  group('EvaluationFormBloc', () {
    EvaluationFormBloc make(FakeLifecycleRepository repo) =>
        EvaluationFormBloc(repository: repo, autoSaveDelay: const Duration(milliseconds: 10));

    test('memuat jawaban tersimpan sebagai state awal', () async {
      final repo = FakeLifecycleRepository()
        ..form = _form(answers: const [EvaluationAnswer(templateItemId: 'i1', score: 4)]);
      final bloc = make(repo)..add(const EvaluationFormStarted('e1'));
      await _settle();
      expect(bloc.state.status, EvaluationFormStatus.loaded);
      expect(bloc.state.scores, {'i1': 4});
      expect(bloc.state.canSubmit, false);
      await bloc.close();
    });

    test('Kirim nonaktif sampai kriteria wajib + usulan terisi; skor sementara dihitung', () async {
      final repo = FakeLifecycleRepository()..form = _form();
      final bloc = make(repo)..add(const EvaluationFormStarted('e1'));
      await _settle();
      bloc.add(const EvaluationFormRatingChanged('i1', 5));
      await _settle();
      expect(bloc.state.missingRequired.map((e) => e.id), ['i2']);
      expect(bloc.state.canSubmit, false);
      bloc.add(const EvaluationFormRatingChanged('i2', 4));
      bloc.add(const EvaluationFormProposalChanged('extend_contract'));
      await _settle();
      expect(bloc.state.canSubmit, true);
      expect(bloc.state.tentativeScore, 4.6); // (5*60 + 4*40) / 100
      await bloc.close();
    });

    test('draf tersimpan otomatis (debounce) dengan jawaban yang terisi saja', () async {
      final repo = FakeLifecycleRepository()..form = _form();
      final bloc = make(repo)..add(const EvaluationFormStarted('e1'));
      await _settle();
      bloc.add(const EvaluationFormRatingChanged('i1', 3));
      bloc.add(const EvaluationFormRatingChanged('i1', 4));
      bloc.add(const EvaluationFormTextChanged('i3', '  Rajin  '));
      await _settle();
      expect(repo.savedAnswers, hasLength(1)); // perubahan beruntun digabung
      expect(repo.savedAnswers.single.map((a) => a.templateItemId), ['i1', 'i3']);
      expect(repo.savedAnswers.single.first.score, 4);
      expect(repo.savedAnswers.single.last.textAnswer, 'Rajin');
      expect(bloc.state.saveState, EvaluationDraftSaveState.saved);
      await bloc.close();
    });

    test('gagal simpan draf → saveState error dengan pesan server', () async {
      final repo = FakeLifecycleRepository()
        ..form = _form()
        ..saveError = const ApiException(message: 'Status berubah', statusCode: 409);
      final bloc = make(repo)..add(const EvaluationFormStarted('e1'));
      await _settle();
      bloc.add(const EvaluationFormRatingChanged('i1', 3));
      await _settle();
      expect(bloc.state.saveState, EvaluationDraftSaveState.error);
      expect(bloc.state.errorStatusCode, 409);
      await bloc.close();
    });

    test('submit sukses → submitted + hasil skor dari server', () async {
      final repo = FakeLifecycleRepository()..form = _form();
      final bloc = make(repo)..add(const EvaluationFormStarted('e1'));
      await _settle();
      bloc
        ..add(const EvaluationFormRatingChanged('i1', 5))
        ..add(const EvaluationFormRatingChanged('i2', 4))
        ..add(const EvaluationFormProposalChanged('extend_contract'));
      await _settle();
      bloc.add(const EvaluationFormSubmitted());
      await _settle();
      expect(bloc.state.status, EvaluationFormStatus.submitted);
      expect(bloc.state.submitResult!.overallScore, 4.6);
      expect(repo.submitCalls, 1);
      await bloc.close();
    });

    test('submit 409 (kalah balapan) → kembali ke loaded dengan pesan', () async {
      final repo = FakeLifecycleRepository()
        ..form = _form()
        ..submitError = const ApiException(message: 'Penilaian sudah dikirim', statusCode: 409);
      final bloc = make(repo)..add(const EvaluationFormStarted('e1'));
      await _settle();
      bloc
        ..add(const EvaluationFormRatingChanged('i1', 5))
        ..add(const EvaluationFormRatingChanged('i2', 4))
        ..add(const EvaluationFormProposalChanged('extend_contract'));
      await _settle();
      bloc.add(const EvaluationFormSubmitted());
      await _settle();
      expect(bloc.state.status, EvaluationFormStatus.loaded);
      expect(bloc.state.errorStatusCode, 409);
      await bloc.close();
    });

    test('form read-only (canEdit=false) mengabaikan perubahan dan submit', () async {
      final repo = FakeLifecycleRepository()..form = _form(canEdit: false);
      final bloc = make(repo)..add(const EvaluationFormStarted('e1'));
      await _settle();
      bloc.add(const EvaluationFormRatingChanged('i1', 5));
      bloc.add(const EvaluationFormSubmitted());
      await _settle();
      expect(bloc.state.scores, isEmpty);
      expect(repo.submitCalls, 0);
      expect(repo.savedAnswers, isEmpty);
      await bloc.close();
    });
  });

  group('MyEvaluation cubits', () {
    const item = MyEvaluationItem(
      id: 'e9',
      referenceNumber: 'EVK-9',
      evaluationType: 'contract_renewal',
      status: 'decided',
      decision: 'extend_contract',
      overallScore: 4.2,
    );

    test('daftar hasil + hasUnacknowledged', () async {
      final repo = FakeLifecycleRepository()..myEvaluations = const [item];
      final cubit = MyEvaluationsCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.hasUnacknowledged, true);
    });

    test('acknowledge → memuat ulang detail, tombol berubah; klik ganda diabaikan', () async {
      final repo = FakeLifecycleRepository()
        ..myDetail = const MyEvaluationDetail(summary: item, requiresAcknowledgment: true)
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
      final cubit = MyEvaluationDetailCubit(repository: repo);
      await cubit.load('e9');
      expect(cubit.state.detail!.requiresAcknowledgment, true);
      final first = cubit.acknowledge(comment: 'Terima kasih');
      final second = cubit.acknowledge();
      await Future.wait([first, second]);
      expect(repo.ackCalls, 1);
      expect(cubit.state.detail!.requiresAcknowledgment, false);
      expect(cubit.state.detail!.acknowledgedAt, isNotNull);
      expect(cubit.state.justAcknowledged, true);
    });

    test('acknowledge gagal → pesan error, detail tetap', () async {
      final repo = FakeLifecycleRepository()
        ..myDetail = const MyEvaluationDetail(summary: item, requiresAcknowledgment: true)
        ..ackError = const ApiException(message: 'Belum bisa dikonfirmasi', statusCode: 400);
      final cubit = MyEvaluationDetailCubit(repository: repo);
      await cubit.load('e9');
      await cubit.acknowledge();
      expect(cubit.state.errorMessage, 'Belum bisa dikonfirmasi');
      expect(cubit.state.detail!.requiresAcknowledgment, true);
      expect(cubit.state.isAcknowledging, false);
    });
  });

  group('LifecycleProfileCubit', () {
    test('dua bagian gagal terpisah; satu gagal tidak mengosongkan yang lain', () async {
      final repo = FakeLifecycleRepository()
        ..contractsError = const ApiException(message: 'Gagal kontrak', statusCode: 500)
        ..career = const [
          CareerHistoryItem(
            id: 'h1',
            changeType: 'promotion',
            companyName: 'A',
            departmentName: 'IT',
            prevCompanyName: 'A',
            prevDepartmentName: 'IT',
          ),
        ];
      final cubit = LifecycleProfileCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.contractsError, 'Gagal kontrak');
      expect(cubit.state.career, hasLength(1));
      expect(cubit.state.isEmpty, false);
    });

    test('kosong dan gagal total', () async {
      final empty = LifecycleProfileCubit(repository: FakeLifecycleRepository());
      await empty.load();
      expect(empty.state.isEmpty, true);

      final failing = FakeLifecycleRepository()
        ..contractsError = const ApiException(message: 'x')
        ..careerError = const ApiException(message: 'y');
      final cubit = LifecycleProfileCubit(repository: failing);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
    });
  });

  group('Onboarding card & task action', () {
    LifecycleTaskModel task({bool canComplete = true}) => LifecycleTaskModel(
          id: 't1',
          title: 'Isi data',
          type: 'acknowledgment',
          assigneeRole: 'employee',
          isRequired: true,
          status: 'pending',
          isMine: true,
          canComplete: canComplete,
        );

    test('kartu tampil bila ada pekerjaan tersisa; hilang saat selesai; tersembunyi saat gagal', () async {
      final repo = FakeLifecycleRepository()
        ..onboarding = const OnboardingProgressModel(
          id: 'o1',
          referenceNumber: 'ONB-1',
          status: 'in_progress',
          progress: LifecycleProgress(done: 2, total: 5, requiredDone: 2, requiredTotal: 4),
        );
      final cubit = OnboardingCardCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.visible, true);

      repo.onboarding = const OnboardingProgressModel(
        id: 'o1',
        referenceNumber: 'ONB-1',
        status: 'in_progress',
        progress: LifecycleProgress(done: 5, total: 5, requiredDone: 4, requiredTotal: 4),
      );
      await cubit.load();
      expect(cubit.state.visible, false);

      repo.onboarding = null;
      await cubit.load();
      expect(cubit.state.visible, false);

      repo.error = const ApiException(message: 'offline');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.visible, false);
    });

    test('TaskActionCubit menyelesaikan task; system_check/canComplete=false ditolak lokal', () async {
      final repo = FakeLifecycleRepository();
      final cubit = TaskActionCubit(repository: repo);
      await cubit.complete(task(canComplete: false));
      expect(repo.completedTasks, isEmpty);
      await cubit.complete(task());
      expect(repo.completedTasks, ['t1']);
      expect(cubit.state.completedTaskId, 't1');
    });

    test('TaskActionCubit melaporkan error server (mis. 404/409)', () async {
      final repo = FakeLifecycleRepository()
        ..error = const ApiException(message: 'Status tugas berubah', statusCode: 409);
      final cubit = TaskActionCubit(repository: repo);
      await cubit.complete(task());
      expect(cubit.state.errorMessage, 'Status tugas berubah');
      expect(cubit.state.errorStatusCode, 409);
      expect(cubit.state.busyTaskId, isNull);
    });

    test('MyTasksCubit memuat daftar', () async {
      final repo = FakeLifecycleRepository()..tasks = [task()];
      final cubit = MyTasksCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.tasks, hasLength(1));
    });
  });
}
