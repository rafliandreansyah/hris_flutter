import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:hris_flutter/features/resignation/data/models/resignation_initial_form_model.dart';
import 'package:hris_flutter/features/resignation/data/models/submit_resignation_request_model.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';

void main() {
  group('MyResignationStatusModel & ResignationDetailModel Tests', () {
    final sampleDetailJson = {
      'id': 'res-001',
      'companyId': 'comp-101',
      'employeeId': 'emp-202',
      'resignationDate': '2026-10-01T08:00:00.000Z',
      'effectiveDate': '2026-10-31T08:00:00.000Z',
      'actualResignDate': '2026-10-31T08:00:00.000Z',
      'requiredNoticePeriodDays': 30,
      'actualNoticePeriodDays': 30,
      'isEarlyNotice': false,
      'earlyNoticeReason': null,
      'isEarlyNoticeApproved': false,
      'reasonCategory': 'CAREER_GROWTH',
      'reason': 'Mendapatkan kesempatan karier baru',
      'resignationLetterUrl': '/docs/letter.pdf',
      'handoverToEmployeeId': 'emp-303',
      'handoverTo': {
        'id': 'emp-303',
        'firstName': 'Budi',
        'lastName': 'Santoso',
        'email': 'budi@example.com',
        'employeeNumber': 'EMP-303',
      },
      'handoverNotes': 'Serah terima repositori dan dokumentasi',
      'handoverDocumentUrl': '/docs/handover.pdf',
      'remainingLeaveDays': 4,
      'leaveEncashmentStatus': 'PENDING',
      'isLeaveEncashed': true,
      'encashedLeaveDays': 4,
      'encashedLeaveAmount': 2000000.0,
      'status': 'submitted',
      'rejectionReason': null,
      'managerApprover': {
        'id': 'app-1',
        'firstName': 'Manager',
        'lastName': 'One',
        'email': 'manager@example.com',
      },
      'managerNotes': 'Disetujui untuk proses berikutnya',
      'managerApprovedAt': '2026-10-02T10:00:00.000Z',
      'hrApprover': null,
      'hrNotes': null,
      'hrApprovedAt': null,
      'isPayrollHold': false,
      'paklaringNumber': 'PKL-2026-001',
      'paklaringUrl': '/docs/pkl.pdf',
      'paklaringIssuedAt': '2026-10-31T12:00:00.000Z',
      'createdAt': '2026-10-01T08:00:00.000Z',
      'updatedAt': '2026-10-02T10:00:00.000Z',
      'employee': {
        'id': 'emp-202',
        'firstName': 'Siti',
        'lastName': 'Aminah',
        'email': 'siti@example.com',
        'employeeNumber': 'EMP-202',
        'company': {'id': 'comp-101', 'name': 'PT Oasish Tech'},
        'department': {'id': 'dept-1', 'name': 'Engineering'},
        'position': {'id': 'pos-1', 'name': 'Senior Engineer'},
      },
      'timeline': [
        {
          'title': 'Pengajuan Diterima',
          'description': 'Menunggu review atasan',
          'timestamp': '2026-10-01T08:00:00.000Z',
          'isDone': true,
        }
      ],
      'hasExitInterview': true,
    };

    test('MyResignationStatusModel fromJson parses active resignation successfully', () {
      final json = {
        'hasActiveResignation': true,
        'daysRemaining': 20,
        'resignation': sampleDetailJson,
        'canCancel': true,
        'canSubmitExitInterview': true,
        'hasSubmittedExitInterview': false,
      };

      final model = MyResignationStatusModel.fromJson(json);

      expect(model.hasActiveResignation, isTrue);
      expect(model.daysRemaining, 20);
      expect(model.canCancel, isTrue);
      expect(model.canSubmitExitInterview, isTrue);
      expect(model.hasSubmittedExitInterview, isFalse);
      expect(model.resignation, isNotNull);
      expect(model.resignation!.id, 'res-001');
      expect(model.resignation!.reasonCategory, 'CAREER_GROWTH');
      expect(model.resignation!.employee?.fullName, 'Siti Aminah');
      expect(model.resignation!.handoverTo?.fullName, 'Budi Santoso');
      expect(model.resignation!.timeline.length, 1);
      expect(model.props, contains(20));
    });

    test('MyResignationStatusModel fromJson handles null/empty safely', () {
      final model = MyResignationStatusModel.fromJson(const {});

      expect(model.hasActiveResignation, isFalse);
      expect(model.daysRemaining, 0);
      expect(model.resignation, isNull);
      expect(model.canCancel, isFalse);
      expect(model.canSubmitExitInterview, isFalse);
      expect(model.hasSubmittedExitInterview, isFalse);
    });

    test('ResignationDetailModel helper getters work correctly', () {
      final detail = ResignationDetailModel.fromJson(sampleDetailJson);

      expect(detail.id, 'res-001');
      expect(detail.requiredNoticePeriodDays, 30);
      expect(detail.actualNoticePeriodDays, 30);
      expect(detail.isEarlyNotice, isFalse);
      expect(detail.isLeaveEncashed, isTrue);
      expect(detail.encashedLeaveAmount, 2000000.0);
      expect(detail.paklaringNumber, 'PKL-2026-001');
      expect(detail.managerApprover?.name, 'Manager');
      expect(detail.employee?.departmentName, 'Engineering');
      expect(detail.employee?.positionName, 'Senior Engineer');
    });
  });

  group('ResignationInitialFormModel Tests', () {
    test('fromJson parses companyPolicy and form employee correctly', () {
      final json = {
        'companyPolicy': {
          'isNoticePeriodRequired': true,
          'defaultNoticePeriodDays': 30,
          'useLevelNoticePeriodPolicy': false,
          'allowEarlyNoticeWaiver': true,
          'allowLeaveEncashmentOnResign': true,
          'enableExitInterview': true,
          'isExitInterviewMandatory': true,
          'effectiveNoticePeriodDays': 30,
        },
        'employee': {
          'id': 'emp-01',
          'name': 'Ahmad Fauzi',
          'employeeNumber': 'EMP-001',
          'department': 'Product',
          'position': 'UI/UX Designer',
          'remainingLeaveDays': 6,
        },
        'minSuggestedDate': '2026-11-12',
        'colleagues': [
          {
            'id': 'col-1',
            'name': 'Rian Pratama',
            'email': 'rian@example.com',
            'position': 'Graphic Designer',
          }
        ],
      };

      final formModel = ResignationInitialFormModel.fromJson(json);

      expect(formModel.companyPolicy.defaultNoticePeriodDays, 30);
      expect(formModel.companyPolicy.allowEarlyNoticeWaiver, isTrue);
      expect(formModel.companyPolicy.isExitInterviewMandatory, isTrue);
      expect(formModel.employee.id, 'emp-01');
      expect(formModel.employee.name, 'Ahmad Fauzi');
      expect(formModel.employee.remainingLeaveDays, 6);
      expect(formModel.minSuggestedDate, '2026-11-12');
      expect(formModel.colleagues.length, 1);
      expect(formModel.colleagues.first.name, 'Rian Pratama');
      expect(formModel.props, contains('2026-11-12'));
    });

    test('ResignationInitialFormModel handles null values safely', () {
      final formModel = ResignationInitialFormModel.fromJson(const {});

      expect(formModel.companyPolicy.defaultNoticePeriodDays, 30);
      expect(formModel.employee.id, '');
      expect(formModel.minSuggestedDate, '');
      expect(formModel.colleagues, isEmpty);
    });
  });

  group('SubmitResignationRequestModel Tests', () {
    test('toFormData builds multipart map with optional fields correctly', () async {
      const request = SubmitResignationRequestModel(
        effectiveDate: '2026-11-01',
        reasonCategory: 'RELOCATION',
        reasonNotes: 'Pindah domisili ke luar kota',
        isEarlyNotice: true,
        earlyNoticeReason: 'Keluarga membutuhkan perawatan',
        handoverToEmployeeId: 'emp-99',
        handoverNotes: 'Sudah diserahkan akun ke emp-99',
        resignationLetterUrl: 'https://example.com/surat.pdf',
      );

      final formData = await request.toFormData();

      final fieldsMap = Map.fromEntries(formData.fields);
      expect(fieldsMap['effectiveDate'], '2026-11-01');
      expect(fieldsMap['reasonCategory'], 'RELOCATION');
      expect(fieldsMap['reasonNotes'], 'Pindah domisili ke luar kota');
      expect(fieldsMap['isEarlyNotice'], 'true');
      expect(fieldsMap['earlyNoticeReason'], 'Keluarga membutuhkan perawatan');
      expect(fieldsMap['handoverToEmployeeId'], 'emp-99');
      expect(fieldsMap['handoverNotes'], 'Sudah diserahkan akun ke emp-99');
      expect(fieldsMap['resignationLetterUrl'], 'https://example.com/surat.pdf');
    });
  });

  group('SubordinateResignationResponseModel Tests', () {
    test('fromJson parses list and pagination meta correctly', () {
      final json = {
        'success': true,
        'message': 'Data permohonan resign bawahan dimuat',
        'data': [
          {
            'id': 'sub-res-01',
            'companyId': 'comp-1',
            'employeeId': 'emp-10',
            'employeeName': 'Andi Wijaya',
            'employeeNik': 'EMP-010',
            'departmentName': 'Finance',
            'positionName': 'Accountant',
            'avatarUrl': null,
            'submittedDate': '2026-10-10T08:00:00.000Z',
            'effectiveDate': '2026-11-10T08:00:00.000Z',
            'actualResignDate': '2026-11-10T08:00:00.000Z',
            'requiredNoticePeriodDays': 30,
            'actualNoticePeriodDays': 30,
            'isEarlyNotice': false,
            'earlyNoticeReason': null,
            'reasonCategory': 'HEALTH',
            'reason': 'Alasan kesehatan keluarga',
            'status': 'submitted',
            'managerNotes': null,
            'handoverToEmployeeName': 'Budi Santoso',
            'createdAt': '2026-10-10T08:00:00.000Z',
          }
        ],
        'meta': {
          'page': 1,
          'size': 10,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = SubordinateResignationResponseModel.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, 'Data permohonan resign bawahan dimuat');
      expect(response.data.length, 1);
      expect(response.meta.total, 1);
      expect(response.meta.totalPages, 1);

      final item = response.data.first;
      expect(item.id, 'sub-res-01');
      expect(item.employeeName, 'Andi Wijaya');
      expect(item.departmentName, 'Finance');
      expect(item.positionName, 'Accountant');
      expect(item.reasonCategory, 'HEALTH');
      expect(item.handoverToName, 'Budi Santoso');
      expect(item.status, 'submitted');
    });

    test('SubordinateResignationResponseModel handles empty list safely', () {
      final response = SubordinateResignationResponseModel.fromJson(const {
        'success': true,
        'message': 'OK',
        'data': [],
        'meta': {'page': 1, 'size': 10, 'total': 0, 'totalPages': 0},
      });

      expect(response.data, isEmpty);
      expect(response.meta.total, 0);
    });
  });
}
