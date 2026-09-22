import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';

void main() {
  group('ExpensesFeedModel Tests', () {
    test('ExpensesPaginationMeta parses json correctly', () {
      final json = {
        'page': 2,
        'limit': 15,
        'total': 45,
        'totalPages': 3,
      };

      final meta = ExpensesPaginationMeta.fromJson(json);

      expect(meta.page, 2);
      expect(meta.limit, 15);
      expect(meta.total, 45);
      expect(meta.totalPages, 3);
    });

    test('ExpensesPaginationMeta fallback with empty json', () {
      final meta = ExpensesPaginationMeta.fromJson({});
      expect(meta.page, 1);
      expect(meta.limit, 10);
      expect(meta.total, 0);
      expect(meta.totalPages, 1);
    });

    test('ExpenseEmployeeModel parses full json & getters work', () {
      final json = {
        'id': 'emp-101',
        'employeeId': 'NIP-001',
        'firstName': 'Budi',
        'lastName': 'Santoso',
        'email': 'budi@example.com',
        'photoUrl': 'uploads/budi.jpg',
        'jobPosition': 'Senior Engineer',
        'department': 'Technology',
        'company': 'PT Muratech',
      };

      final emp = ExpenseEmployeeModel.fromJson(json);

      expect(emp.id, 'emp-101');
      expect(emp.employeeId, 'NIP-001');
      expect(emp.firstName, 'Budi');
      expect(emp.lastName, 'Santoso');
      expect(emp.fullName, 'Budi Santoso');
      expect(emp.position, 'Senior Engineer');
      expect(emp.department, 'Technology');
      expect(emp.company, 'PT Muratech');
      expect(emp.resolvedPhotoUrl, contains('uploads/budi.jpg'));
    });

    test('ExpenseEmployeeModel handles single name correctly', () {
      final json = {
        'id': 'emp-102',
        'firstName': 'Prabowo',
        'lastName': null,
        'email': 'prabowo@example.com',
      };

      final emp = ExpenseEmployeeModel.fromJson(json);
      expect(emp.fullName, 'Prabowo');
      expect(emp.position, isNull);
    });

    test('ExpenseFeedItemModel parses reimbursement item correctly', () {
      final json = {
        'id': 'claim-1',
        'referenceNumber': 'CLM-2026-001',
        'expenseType': 'reimbursement',
        'title': 'Beli Monitor 4K',
        'description': 'Kebutuhan display programming',
        'requestedAmount': 3500000.0,
        'approvedAmount': 3500000.0,
        'status': 'approved',
        'createdAt': '2026-09-20T10:00:00.000Z',
        'employee': {
          'id': 'emp-1',
          'firstName': 'Sarah',
          'email': 'sarah@example.com',
        },
      };

      final item = ExpenseFeedItemModel.fromJson(json);

      expect(item.id, 'claim-1');
      expect(item.referenceNumber, 'CLM-2026-001');
      expect(item.expenseType, 'reimbursement');
      expect(item.isReimbursement, isTrue);
      expect(item.isCashAdvance, isFalse);
      expect(item.requestedAmount, 3500000.0);
      expect(item.approvedAmount, 3500000.0);
      expect(item.status, 'approved');
      expect(item.employee.fullName, 'Sarah');
      expect(parseExpenseStatus(item.status), ExpenseStatus.approved);
    });

    test('ExpenseFeedItemModel parses cash advance item correctly', () {
      final json = {
        'id': 'adv-1',
        'referenceNumber': 'CSH-2026-001',
        'expenseType': 'cash_advance',
        'title': 'Kasbon Operasional Kantor',
        'requestedAmount': 5000000.0,
        'status': 'disbursed',
        'createdAt': '2026-09-18T08:00:00.000Z',
        'settlementStatus': 'unsettled',
        'employee': {
          'id': 'emp-2',
          'firstName': 'Budi',
          'email': 'budi@example.com',
        },
      };

      final item = ExpenseFeedItemModel.fromJson(json);

      expect(item.isCashAdvance, isTrue);
      expect(item.isReimbursement, isFalse);
      expect(item.settlementStatus, 'unsettled');
      expect(parseExpenseStatus(item.status), ExpenseStatus.disbursed);
    });

    test('ExpensesFeedResponseModel parses complete list response', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': [
          {
            'id': 'claim-1',
            'referenceNumber': 'CLM-001',
            'expenseType': 'reimbursement',
            'title': 'Biaya Grab',
            'requestedAmount': 50000.0,
            'status': 'requested',
            'createdAt': '2026-09-22T00:00:00.000Z',
            'employee': {'id': '1', 'firstName': 'Ali', 'email': 'a@a.com'},
          }
        ],
        'meta': {
          'page': 1,
          'limit': 10,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = ExpensesFeedResponseModel.fromJson(json);

      expect(response.items.length, 1);
      expect(response.data.length, 1);
      expect(response.meta.total, 1);
      expect(response.data.first.title, 'Biaya Grab');
    });
  });
}
