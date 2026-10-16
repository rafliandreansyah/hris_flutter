import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_evaluation_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_profile_models.dart';
import 'package:hris_flutter/features/lifecycle/data/models/lifecycle_task_models.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';

void main() {
  group('EvaluationAssignedPage', () {
    test('parse item + meta paginasi', () {
      final page = EvaluationAssignedPage.fromJson({
        'data': [
          {
            'id': 'e1',
            'referenceNumber': 'EVK-1',
            'evaluationType': 'contract_renewal',
            'status': 'draft',
            'employee': {'id': 'x', 'name': 'Budi', 'departmentName': 'IT'},
            'periodEndDate': '2026-12-31',
            'dueDate': '2026-11-15',
            'decisionDeadline': '2026-12-24',
            'isOverdue': true,
            'overallScore': null,
            'bandLabel': null,
          },
        ],
        'meta': {'total': 11, 'page': 2, 'totalPages': 2},
      });
      expect(page.items.single.employee.name, 'Budi');
      expect(page.items.single.isOpen, true);
      expect(page.items.single.isOverdue, true);
      expect(page.items.single.dueDate, DateTime(2026, 11, 15));
      expect(page.total, 11);
      expect(page.totalPages, 2);
    });

    test('tahan terhadap data kosong', () {
      final page = EvaluationAssignedPage.fromJson({'data': null});
      expect(page.items, isEmpty);
      expect(page.totalPages, 1);
    });
  });

  group('EvaluationForm', () {
    test('parse template dinamis, jawaban, metrik', () {
      final f = EvaluationForm.fromJson({
        'id': 'e1',
        'referenceNumber': 'EVK-1',
        'evaluationType': 'contract_renewal',
        'status': 'revision_requested',
        'employee': {'id': 'x', 'name': 'Budi'},
        'canEdit': true,
        'revisionNotes': 'Lengkapi',
        'template': {
          'name': 'PKWT',
          'scaleMin': 1,
          'scaleMax': 5,
          'scaleLabels': {'1': 'Buruk', '5': 'Baik'},
          'allowedProposals': ['extend_contract'],
          'items': [
            {'id': 'i1', 'code': 'p', 'title': 'Kinerja', 'type': 'rating', 'weight': 60, 'isRequired': true},
            {'id': 'i2', 'code': 'n', 'title': 'Catatan', 'type': 'text', 'weight': null, 'isRequired': false},
          ],
        },
        'answers': [
          {'templateItemId': 'i1', 'score': 4, 'textAnswer': null},
        ],
        'supportingMetrics': {'attendanceRate': 92.5, 'totalPresent': 20, 'totalLate': 1, 'activeWarningLetters': 0},
      });
      expect(f.canEdit, true);
      expect(f.revisionNotes, 'Lengkapi');
      expect(f.scaleLabels['5'], 'Baik');
      expect(f.items.first.isRating, true);
      expect(f.items.last.isRating, false);
      expect(f.answers.single.score, 4);
      expect(f.metrics.attendanceRate, 92.5);
      expect(f.allowedProposals, ['extend_contract']);
    });

    test('EvaluationAnswer.toJson', () {
      const a = EvaluationAnswer(templateItemId: 'i1', score: 3);
      expect(a.toJson(), {'templateItemId': 'i1', 'score': 3, 'textAnswer': null});
    });
  });

  group('MyEvaluationDetail', () {
    test('parse hasil + kontrak baru + acknowledge', () {
      final d = MyEvaluationDetail.fromJson({
        'id': 'e9',
        'referenceNumber': 'EVK-9',
        'evaluationType': 'contract_renewal',
        'status': 'decided',
        'decision': 'extend_contract',
        'overallScore': 4.2,
        'bandLabel': 'Memuaskan',
        'acknowledged': false,
        'newContractStartDate': '2027-01-01',
        'newContractEndDate': '2027-12-31',
        'requiresAcknowledgment': true,
      });
      expect(d.summary.overallScore, 4.2);
      expect(d.newContractStartDate, DateTime(2027, 1, 1));
      expect(d.requiresAcknowledgment, true);
      expect(d.acknowledgedAt, isNull);
    });
  });

  group('Kontrak & karier', () {
    test('ContractOverviewModel tanpa kontrak aktif', () {
      final c = ContractOverviewModel.fromJson({
        'activeContract': null,
        'contracts': [],
        'pkwtSummary': {'totalPkwtMonths': 30, 'maxContractMonths': 60, 'pkwtMonthsRemaining': 30},
      });
      expect(c.activeContract, isNull);
      expect(c.pkwtSummary.usedRatio, 0.5);
    });

    test('ContractOverviewModel dengan kontrak aktif', () {
      final c = ContractOverviewModel.fromJson({
        'activeContract': {
          'id': 'c1', 'contractNumber': 'PKWT-1', 'type': 'pkwt', 'startDate': '2026-01-01',
          'endDate': '2026-11-05', 'probationEndDate': null, 'daysUntilExpiry': 20, 'isNearExpiry': true,
        },
        'contracts': [
          {'id': 'c1', 'contractNumber': 'PKWT-1', 'sequence': 1, 'type': 'pkwt', 'status': 'active', 'startDate': '2026-01-01', 'endDate': '2026-11-05'},
        ],
        'pkwtSummary': {'totalPkwtMonths': 10, 'maxContractMonths': 60, 'pkwtMonthsRemaining': 50},
      });
      expect(c.activeContract!.isNearExpiry, true);
      expect(c.activeContract!.daysUntilExpiry, 20);
      expect(c.contracts.single.sequence, 1);
    });

    test('CareerHistoryItem', () {
      final h = CareerHistoryItem.fromJson({
        'id': 'h1', 'changeType': 'promotion', 'effectiveDate': '2026-03-01',
        'companyName': 'PT A', 'departmentName': 'IT', 'positionName': 'Lead', 'levelName': null,
        'prevCompanyName': 'PT A', 'prevDepartmentName': 'IT', 'prevPositionName': 'Staff',
      });
      expect(h.positionName, 'Lead');
      expect(h.prevPositionName, 'Staff');
      expect(h.levelName, isNull);
    });
  });

  group('Task, onboarding, offboarding', () {
    Map<String, dynamic> task({String status = 'pending', String type = 'manual'}) => {
          'id': 't1', 'title': 'Isi data', 'type': type, 'assigneeRole': 'employee',
          'isRequired': true, 'status': status, 'dueDate': '2026-10-20', 'isOverdue': false,
          'subjectName': 'Ani', 'isSubjectMe': true, 'isMine': true, 'canComplete': type != 'system_check',
          'parent': {'kind': 'onboarding', 'id': 'ob1', 'referenceNumber': 'ONB-1'},
        };

    test('LifecycleTaskModel', () {
      final t = LifecycleTaskModel.fromJson(task());
      expect(t.canComplete, true);
      expect(t.isClosed, false);
      expect(t.parentKind, 'onboarding');
      expect(LifecycleTaskModel.fromJson(task(status: 'skipped')).isClosed, true);
      expect(LifecycleTaskModel.fromJson(task(type: 'system_check')).canComplete, false);
    });

    test('OnboardingProgressModel.hasOpenWork', () {
      final o = OnboardingProgressModel.fromJson({
        'id': 'ob1', 'referenceNumber': 'ONB-1', 'status': 'in_progress', 'joinDate': '2026-10-01',
        'isRehire': false,
        'progress': {'done': 2, 'total': 5, 'requiredDone': 2, 'requiredTotal': 4},
        'myTasks': [task()],
      });
      expect(o.hasOpenWork, true);
      expect(o.progress.total, 5);
      expect(o.myTasks, hasLength(1));
      final done = OnboardingProgressModel.fromJson({
        'id': 'ob1', 'referenceNumber': 'x', 'status': 'in_progress',
        'progress': {'done': 5, 'total': 5, 'requiredDone': 4, 'requiredTotal': 4}, 'myTasks': [],
      });
      expect(done.hasOpenWork, false);
    });

    test('OffboardingStatusModel + paklaring', () {
      final o = OffboardingStatusModel.fromJson({
        'id': 'off1', 'referenceNumber': 'OFB-1', 'exitType': 'resignation', 'status': 'settled',
        'lastWorkingDate': '2026-10-30', 'effectiveExitDate': '2026-10-31', 'accessRevokedAt': null,
        'progress': {'done': 1, 'total': 1, 'requiredDone': 1, 'requiredTotal': 1},
        'tasks': [task(status: 'done')],
        'paklaring': {'issued': true, 'number': 'PKL-1', 'url': 'https://f/p.pdf', 'issuedAt': '2026-11-02T00:00:00.000Z'},
      });
      expect(o.paklaring.issued, true);
      expect(o.paklaring.number, 'PKL-1');
      expect(o.lastWorkingDate, DateTime(2026, 10, 30));
      expect(o.tasks.single.isClosed, true);
    });
  });

  group('MyResignationStatusModel — blok offboarding aditif', () {
    test('kompatibel bila blok offboarding tidak ada / null', () {
      final a = MyResignationStatusModel.fromJson({'hasActiveResignation': false});
      expect(a.offboarding, isNull);
      final b = MyResignationStatusModel.fromJson({'hasActiveResignation': true, 'offboarding': null});
      expect(b.offboarding, isNull);
    });

    test('mem-parse blok offboarding bila ada', () {
      final m = MyResignationStatusModel.fromJson({
        'hasActiveResignation': true,
        'offboarding': {
          'id': 'off1', 'referenceNumber': 'OFB-1', 'exitType': 'resignation', 'status': 'in_progress',
          'lastWorkingDate': '2026-10-30', 'effectiveExitDate': '2026-10-31',
          'progress': {'done': 0, 'total': 1, 'requiredDone': 0, 'requiredTotal': 1},
          'tasks': [], 'paklaring': {'issued': false},
        },
      });
      expect(m.offboarding!.referenceNumber, 'OFB-1');
      expect(m.offboarding!.paklaring.issued, false);
    });
  });
}
