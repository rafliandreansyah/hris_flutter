import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';

void main() {
  group('Payroll Detail Models Tests', () {
    test('PayrollCompanyModel fromJson, toJson, and resolvedLogoUrl', () {
      final json = {
        'id': 'comp-10',
        'name': 'PT Oasish Digital Indonesia',
        'address': 'Jl. Jendral Sudirman No. 45, Jakarta',
        'phone': '021-5551234',
        'email': 'hr@oasish.app',
        'website': 'https://oasish.app',
        'taxId': '01.234.567.8-012.000',
        'logoUrl': 'uploads/company_logo.png',
      };

      final comp = PayrollCompanyModel.fromJson(json);
      expect(comp.id, 'comp-10');
      expect(comp.name, 'PT Oasish Digital Indonesia');
      expect(comp.address, 'Jl. Jendral Sudirman No. 45, Jakarta');
      expect(comp.phone, '021-5551234');
      expect(comp.email, 'hr@oasish.app');
      expect(comp.website, 'https://oasish.app');
      expect(comp.taxId, '01.234.567.8-012.000');
      expect(comp.logoUrl, 'uploads/company_logo.png');
      expect(comp.resolvedLogoUrl, isNotNull);

      final out = comp.toJson();
      expect(out['id'], 'comp-10');
      expect(out['name'], 'PT Oasish Digital Indonesia');
      expect(comp.props, contains('comp-10'));
    });

    test('PayrollEmployeeDetailModel fromJson, toJson, and props', () {
      final json = {
        'id': 'emp-55',
        'nik': 'EMP-2026-055',
        'name': 'Andi Pratama',
        'email': 'andi@oasish.app',
        'phone': '08123456789',
        'department': 'Technology',
        'position': 'Senior Flutter Engineer',
        'bankName': 'BCA',
        'accountNumber': '1234567890',
        'taxStatus': 'K/1',
        'taxNumber': '98.765.432.1-012.000',
        'bpjsEmployment': '00012345678',
        'bpjsHealth': '00087654321',
      };

      final emp = PayrollEmployeeDetailModel.fromJson(json);
      expect(emp.id, 'emp-55');
      expect(emp.nik, 'EMP-2026-055');
      expect(emp.name, 'Andi Pratama');
      expect(emp.department, 'Technology');
      expect(emp.position, 'Senior Flutter Engineer');
      expect(emp.bankName, 'BCA');
      expect(emp.accountNumber, '1234567890');
      expect(emp.taxStatus, 'K/1');

      final out = emp.toJson();
      expect(out['nik'], 'EMP-2026-055');
      expect(out['bankName'], 'BCA');
      expect(emp.props, contains('emp-55'));
    });

    test('PayrollAttendanceRecapModel fromJson and toJson', () {
      final json = {
        'workingDays': 22,
        'presentDays': 21,
        'absentDays': 1,
        'lateMinutes': 15,
        'overtimeHours': 6.5,
      };

      final recap = PayrollAttendanceRecapModel.fromJson(json);
      expect(recap.workingDays, 22);
      expect(recap.presentDays, 21);
      expect(recap.absentDays, 1);
      expect(recap.lateMinutes, 15);
      expect(recap.overtimeHours, 6.5);

      final out = recap.toJson();
      expect(out['workingDays'], 22);
      expect(out['overtimeHours'], 6.5);
      expect(recap.props, contains(22));

      // Defaults for empty map
      final emptyRecap = PayrollAttendanceRecapModel.fromJson(const {});
      expect(emptyRecap.workingDays, 0);
      expect(emptyRecap.presentDays, 0);
      expect(emptyRecap.overtimeHours, 0.0);
    });

    test('PayrollEarningItemModel & PayrollDeductionItemModel', () {
      final earnJson = {
        'id': 'earn-01',
        'name': 'Gaji Pokok',
        'category': 'basic',
        'quantity': '1 Bulan',
        'amount': 15000000.0,
        'formula': 'fixed',
      };
      final earn = PayrollEarningItemModel.fromJson(earnJson);
      expect(earn.id, 'earn-01');
      expect(earn.name, 'Gaji Pokok');
      expect(earn.amount, 15000000.0);
      expect(earn.formula, 'fixed');
      expect(earn.toJson()['name'], 'Gaji Pokok');
      expect(earn.props, contains('earn-01'));

      final dedJson = {
        'id': 'ded-01',
        'name': 'BPJS Ketenagakerjaan JHT',
        'category': 'bpjs',
        'description': 'Potongan iuran JHT 2%',
        'amount': 300000.0,
      };
      final ded = PayrollDeductionItemModel.fromJson(dedJson);
      expect(ded.id, 'ded-01');
      expect(ded.name, 'BPJS Ketenagakerjaan JHT');
      expect(ded.amount, 300000.0);
      expect(ded.toJson()['id'], 'ded-01');
      expect(ded.props, contains('ded-01'));
    });

    test('PayrollDetailModel parsing with full nested objects', () {
      final fullJson = {
        'id': 'pyr-999',
        'status': 'paid',
        'basicSalary': 15000000.0,
        'dailySalary': 681818.18,
        'grossSalary': 18500000.0,
        'deductions': 1200000.0,
        'netSalary': 17300000.0,
        'terbilang': 'Tujuh Belas Juta Tiga Ratus Ribu Rupiah',
        'payslipUrl': 'https://storage.googleapis.com/payslips/pyr-999.pdf',
        'paidAt': '2026-10-25T09:00:00Z',
        'generatedAt': '2026-10-24T18:00:00Z',
        'company': {
          'id': 'comp-01',
          'name': 'PT Oasish Tech',
        },
        'employee': {
          'id': 'emp-01',
          'nik': 'EMP-001',
          'name': 'Muhammad Rizky',
          'email': 'rizky@oasish.app',
          'department': 'Engineering',
          'position': 'Staff',
        },
        'period': {
          'id': 'prd-01',
          'month': 10,
          'year': 2026,
          'label': 'Oktober 2026',
          'startDate': '2026-09-26',
          'endDate': '2026-10-25',
          'payDate': '2026-10-25',
          'status': 'closed',
        },
        'attendanceRecap': {
          'workingDays': 22,
          'presentDays': 22,
          'absentDays': 0,
          'lateMinutes': 0,
          'overtimeHours': 10.0,
        },
        'earnings': [
          {
            'id': 'earn-01',
            'name': 'Gaji Pokok',
            'category': 'basic',
            'quantity': '1 Bulan',
            'amount': 15000000.0,
          },
          {
            'id': 'earn-02',
            'name': 'Tunjangan Lembur',
            'category': 'overtime',
            'quantity': '10 Jam',
            'amount': 3500000.0,
          }
        ],
        'deductionsList': [
          {
            'id': 'ded-01',
            'name': 'Pph 21',
            'category': 'tax',
            'description': 'Pajak Penghasilan',
            'amount': 1200000.0,
          }
        ],
      };

      final detail = PayrollDetailModel.fromJson(fullJson);
      expect(detail.id, 'pyr-999');
      expect(detail.status, 'paid');
      expect(detail.basicSalary, 15000000.0);
      expect(detail.dailySalary, 681818.18);
      expect(detail.grossSalary, 18500000.0);
      expect(detail.deductions, 1200000.0);
      expect(detail.netSalary, 17300000.0);
      expect(detail.terbilang, 'Tujuh Belas Juta Tiga Ratus Ribu Rupiah');
      expect(detail.payslipUrl, isNotNull);
      expect(detail.company.name, 'PT Oasish Tech');
      expect(detail.employee.name, 'Muhammad Rizky');
      expect(detail.period.label, 'Oktober 2026');
      expect(detail.attendanceRecap.workingDays, 22);
      expect(detail.earnings.length, 2);
      expect(detail.deductionsList.length, 1);
      expect(detail.props, contains('pyr-999'));

      // Fallback test for missing nested structures
      final fallbackDetail = PayrollDetailModel.fromJson(const {'id': 'pyr-empty'});
      expect(fallbackDetail.id, 'pyr-empty');
      expect(fallbackDetail.status, 'draft');
      expect(fallbackDetail.basicSalary, 0.0);
      expect(fallbackDetail.company.name, '-');
      expect(fallbackDetail.employee.name, '-');
      expect(fallbackDetail.earnings, isEmpty);
      expect(fallbackDetail.deductionsList, isEmpty);
    });

    test('PayrollDownloadResponseModel fromJson and props', () {
      final json = {
        'payrollId': 'pyr-888',
        'payslipUrl': 'https://download.oasish.app/slip.pdf',
        'isNewlyGenerated': true,
      };

      final download = PayrollDownloadResponseModel.fromJson(json);
      expect(download.payrollId, 'pyr-888');
      expect(download.payslipUrl, 'https://download.oasish.app/slip.pdf');
      expect(download.isNewlyGenerated, true);
      expect(download.props, contains('pyr-888'));
    });
  });
}
