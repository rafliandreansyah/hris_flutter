import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_category_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';

void main() {
  group('ReimbursementDetailModel Tests', () {
    test('ReimbursementCategoryModel parses json correctly', () {
      final json = {
        'id': 'cat-1',
        'companyId': 'comp-1',
        'code': 'MED',
        'name': 'Kesehatan / Medis',
        'description': 'Klaim rawat jalan dan resep dokter',
        'limitType': 'fixed',
        'defaultLimit': 2000000.0,
        'receiptMaxAgeDays': 30,
        'isActive': true,
      };

      final cat = ReimbursementCategoryModel.fromJson(json);

      expect(cat.id, 'cat-1');
      expect(cat.companyId, 'comp-1');
      expect(cat.code, 'MED');
      expect(cat.name, 'Kesehatan / Medis');
      expect(cat.defaultLimit, 2000000.0);
      expect(cat.receiptMaxAgeDays, 30);
      expect(cat.isActive, isTrue);
    });

    test('ReimbursementAttachmentModel parses json and resolves URL', () {
      final json = {
        'id': 'att-1',
        'fileName': 'receipt_lunch.png',
        'fileUrl': 'uploads/receipt_lunch.png',
        'fileSize': 102400,
        'mimeType': 'image/png',
        'createdAt': '2026-09-20T12:00:00.000Z',
      };

      final att = ReimbursementAttachmentModel.fromJson(json);

      expect(att.id, 'att-1');
      expect(att.fileName, 'receipt_lunch.png');
      expect(att.fileSize, 102400);
      expect(att.mimeType, 'image/png');
      expect(att.resolvedFileUrl, isNotNull);
      expect(att.resolvedFileUrl, contains('receipt_lunch.png'));
    });

    test('ReimbursementLineItemModel parses line items correctly', () {
      final json = {
        'id': 'item-1',
        'categoryId': 'cat-1',
        'category': {
          'name': 'Transportasi',
          'code': 'TRN',
        },
        'transactionDate': '2026-09-15T09:30:00.000Z',
        'merchantName': 'Bluebird Taxi',
        'description': 'Taksi dari kantor ke client',
        'requestedAmount': 120000.0,
        'approvedAmount': 120000.0,
        'status': 'approved',
        'attachments': [
          {
            'id': 'att-1',
            'fileName': 'receipt.jpg',
            'fileUrl': 'uploads/receipt.jpg',
          }
        ],
      };

      final item = ReimbursementLineItemModel.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.categoryName, 'Transportasi');
      expect(item.categoryCode, 'TRN');
      expect(item.merchant, 'Bluebird Taxi');
      expect(item.requestedAmount, 120000.0);
      expect(item.attachments.length, 1);
      expect(item.formattedDate, '15/09/2026');
    });

    test('ReimbursementApprovalHistoryModel parses json correctly', () {
      final json = {
        'id': 'hist-1',
        'stepRole': 'manager',
        'action': 'approved',
        'notes': 'Disetujui sesuai plafon',
        'createdAt': '2026-09-21T10:00:00.000Z',
        'approver': {
          'id': 'app-1',
          'firstName': 'Manager',
          'lastName': 'Satu',
          'email': 'manager@example.com',
        },
      };

      final history = ReimbursementApprovalHistoryModel.fromJson(json);

      expect(history.id, 'hist-1');
      expect(history.stepRole, 'manager');
      expect(history.action, 'approved');
      expect(history.notes, 'Disetujui sesuai plafon');
      expect(history.approver.fullName, 'Manager Satu');
    });

    test('ReimbursementDetailModel parses complete details & getters', () {
      final json = {
        'id': 'clm-100',
        'claimNumber': 'CLM-2026-0099',
        'title': 'Klaim Operasional Tim',
        'description': 'Makan siang rapat dan transport',
        'totalRequestedAmount': 500000.0,
        'totalApprovedAmount': 500000.0,
        'status': 'approved',
        'type': 'out_of_pocket',
        'bankName': 'BCA',
        'bankAccountNumber': '1234567890',
        'bankAccountHolder': 'Budi Santoso',
        'createdAt': '2026-09-20T10:00:00.000Z',
        'employee': {
          'id': 'emp-1',
          'firstName': 'Budi',
          'lastName': 'Santoso',
          'email': 'budi@example.com',
        },
        'items': [
          {
            'id': 'item-1',
            'categoryId': 'cat-1',
            'category': {'name': 'Makan', 'code': 'FNB'},
            'transactionDate': '2026-09-20T00:00:00.000Z',
            'merchantName': 'Restoran Solaria',
            'description': 'Lunch meeting',
            'requestedAmount': 500000.0,
            'status': 'approved',
            'attachments': [
              {
                'id': 'att-1',
                'fileName': 'solaria.jpg',
                'fileUrl': 'uploads/solaria.jpg',
              }
            ],
          }
        ],
        'approvalHistories': [
          {
            'id': 'hist-1',
            'stepRole': 'manager',
            'action': 'approved',
            'notes': 'Acc',
            'createdAt': '2026-09-21T00:00:00.000Z',
            'approver': {
              'id': 'app-1',
              'firstName': 'Atasan',
              'email': 'atasan@example.com',
            }
          }
        ],
      };

      final detail = ReimbursementDetailModel.fromJson(json);

      expect(detail.id, 'clm-100');
      expect(detail.claimNumber, 'CLM-2026-0099');
      expect(detail.requestedAmount, 500000.0);
      expect(detail.approvedAmount, 500000.0);
      expect(detail.bankName, 'BCA');
      expect(detail.bankAccountNumber, '1234567890');
      expect(detail.bankAccountHolder, 'Budi Santoso');
      expect(detail.submittedAt, isNotNull);
      expect(detail.items.length, 1);
      expect(detail.approvalHistories.length, 1);
      expect(detail.attachments.length, 1);
      expect(detail.approverNotes, 'Acc');
    });
  });
}
