import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_employee_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_period_model.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';

void main() {
  group('Payroll Models JSON Serialization Tests', () {
    test('PayrollPeriodModel fromJson and toJson', () {
      final json = {
        'id': 'prd-01',
        'month': 10,
        'year': 2026,
        'label': 'Oktober 2026',
        'startDate': '2026-09-26',
        'endDate': '2026-10-25',
        'payDate': '2026-10-25',
        'status': 'open',
      };

      final model = PayrollPeriodModel.fromJson(json);
      expect(model.id, 'prd-01');
      expect(model.month, 10);
      expect(model.year, 2026);
      expect(model.label, 'Oktober 2026');
      expect(model.status, 'open');

      final outputJson = model.toJson();
      expect(outputJson['id'], 'prd-01');
      expect(outputJson['label'], 'Oktober 2026');
    });

    test('PayrollEmployeeItemModel fromJson and toJson', () {
      final json = {
        'id': 'emp-101',
        'name': 'Ahmad Dahlan',
        'firstName': 'Ahmad',
        'lastName': 'Dahlan',
        'employeeNumber': 'EMP-101',
        'email': 'ahmad@example.com',
        'phone': '08123456789',
        'photoUrl': 'https://example.com/avatar.jpg',
        'status': true,
        'company': {'id': 'comp-1', 'name': 'PT Muratech'},
        'department': {'id': 'dept-1', 'name': 'IT Engineering'},
        'position': {'id': 'pos-1', 'name': 'Tech Lead'},
      };

      final model = PayrollEmployeeItemModel.fromJson(json);
      expect(model.id, 'emp-101');
      expect(model.displayName, 'Ahmad Dahlan');
      expect(model.departmentName, 'IT Engineering');
      expect(model.positionName, 'Tech Lead');
      expect(model.company.name, 'PT Muratech');

      final output = model.toJson();
      expect(output['name'], 'Ahmad Dahlan');
      expect(output['company']['name'], 'PT Muratech');
    });

    test('PayrollSlipModel and PayrollListResponseModel fromJson', () {
      final json = {
        'data': [
          {
            'id': 'slip-01',
            'employeeId': 'emp-01',
            'employee': {
              'id': 'emp-01',
              'firstName': 'John',
              'lastName': 'Doe',
              'employeeNumber': 'EMP-001',
            },
            'period': {
              'id': 'prd-01',
              'month': 10,
              'year': 2026,
              'label': 'Oktober 2026',
              'startDate': '2026-09-26',
              'endDate': '2026-10-25',
              'payDate': '2026-10-25',
              'status': 'open',
            },
            'grossSalary': 15000000.0,
            'deductions': 1500000.0,
            'netSalary': 13500000.0,
            'status': 'paid',
            'payslipUrl': 'https://storage.googleapis.com/test.pdf',
            'paidAt': '2026-10-25T08:00:00.000Z',
            'createdAt': '2026-10-25T00:00:00.000Z',
          }
        ],
        'meta': {
          'page': 1,
          'size': 10,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = PayrollListResponseModel.fromJson(json);
      expect(response.data.length, 1);
      expect(response.meta.total, 1);

      final slip = response.data.first;
      expect(slip.id, 'slip-01');
      expect(slip.employee.fullName, 'John Doe');
      expect(slip.grossSalary, 15000000.0);
      expect(slip.deductions, 1500000.0);
      expect(slip.netSalary, 13500000.0);
      expect(slip.status, 'paid');
    });
  });
}
