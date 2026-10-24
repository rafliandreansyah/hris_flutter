import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';

void main() {
  group('Employee API & Directory Item Models Tests', () {
    final sampleDirectoryItemJson = {
      'id': 'emp-001',
      'firstName': 'Budi',
      'lastName': 'Santoso',
      'email': 'budi.santoso@oasish.com',
      'phone': '081234567890',
      'photoUrl': 'https://example.com/budi.jpg',
      'employeeNumber': 'EMP-001',
      'idNumber': '3171012345670001',
      'company': {'id': 'comp-1', 'name': 'PT Oasish Nusantara'},
      'department': {'id': 'dept-1', 'name': 'Engineering'},
      'position': {'id': 'pos-1', 'name': 'Lead Flutter Engineer'},
    };

    test('EmployeeDirectoryItem fromJson parses fullName, role, department, and displayId correctly', () {
      final item = EmployeeDirectoryItem.fromJson(sampleDirectoryItemJson);

      expect(item.id, 'emp-001');
      expect(item.name, 'Budi Santoso');
      expect(item.role, 'Lead Flutter Engineer');
      expect(item.department, 'Engineering');
      expect(item.email, 'budi.santoso@oasish.com');
      expect(item.phone, '081234567890');
      expect(item.company, 'PT Oasish Nusantara');
      expect(item.initials, 'BS');
      expect(item.displayId, 'EMP-001');
    });

    test('EmployeeDirectoryItem fallback displayId and single-word initials', () {
      final singleNameJson = {
        'id': 'emp-002',
        'firstName': 'Joko',
        'position': 'Staff',
        'department': 'Operations',
      };
      final item = EmployeeDirectoryItem.fromJson(singleNameJson);

      expect(item.name, 'Joko');
      expect(item.initials, 'JO');
      expect(item.displayId, 'emp-002');

      const emptyIdItem = EmployeeDirectoryItem(
        id: '',
        name: 'Guest',
        role: 'Unknown',
        department: 'None',
        email: 'guest@example.com',
        initials: 'G',
      );
      expect(emptyIdItem.displayId, 'EMP-000');
    });

    test('EmployeeListResponse fromJson and toJson maps list and meta correctly', () {
      final json = {
        'success': true,
        'message': 'Data pegawai berhasil dimuat',
        'data': [sampleDirectoryItemJson],
        'meta': {
          'page': 1,
          'limit': 15,
          'total': 1,
          'totalPages': 1,
        },
      };

      final response = EmployeeListResponse.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, 'Data pegawai berhasil dimuat');
      expect(response.data.length, 1);
      expect(response.meta.page, 1);
      expect(response.meta.total, 1);

      final serializedMeta = response.meta.toJson();
      expect(serializedMeta['total'], 1);
      expect(serializedMeta['limit'], 15);
    });
  });

  group('EmployeeDetailData Models Tests', () {
    final sampleDetailJson = {
      'id': 'emp-detail-101',
      'userId': 'usr-101',
      'firstName': 'Dewi',
      'lastName': 'Sartika',
      'email': 'dewi.sartika@oasish.com',
      'phone': '08987654321',
      'idNumber': '3271012345670002',
      'employeeNumber': 'EMP-101',
      'gender': 'FEMALE',
      'maritalStatus': 'SINGLE',
      'photoUrl': 'https://example.com/dewi.png',
      'bankName': 'BCA',
      'bankAccount': 'Dewi Sartika',
      'bankNumber': '1234567890',
      'status': true,
      'company': {
        'id': 'comp-1',
        'name': 'PT Oasish Nusantara',
        'address': 'SCBD Lot 8, Jakarta',
      },
      'department': {'id': 'dept-2', 'name': 'Human Resources'},
      'position': {'id': 'pos-2', 'name': 'HR Specialist'},
      'level': {'id': 'lvl-2', 'name': 'Senior Officer'},
      'manager': {
        'id': 'mgr-01',
        'firstName': 'Gunawan',
        'lastName': 'Wibowo',
        'email': 'gunawan@oasish.com',
      },
      'employeeWorkLocation': [
        {
          'id': 'loc-1',
          'name': 'Head Office SCBD',
          'address': 'SCBD Lot 8, Jakarta',
          'latitude': -6.225,
          'longitude': 106.808,
          'radius': 100,
          'isDefault': true,
        }
      ],
      'coworkers': [
        {
          'id': 'cw-1',
          'firstName': 'Rina',
          'lastName': 'Novianti',
          'photoUrl': null,
          'position': {'name': 'HR Admin'},
        }
      ],
      'leaveBalances': [
        {
          'id': 'lb-1',
          'leaveTypeId': 'lt-1',
          'periodYear': 2026,
          'entitlement': 12,
          'used': 3,
          'remaining': 9,
          'leaveType': {
            'id': 'lt-1',
            'name': 'Cuti Tahunan',
          }
        }
      ],
    };

    test('EmployeeDetailData memakai totalOvertimeMinutes (menit) dan menjaga saldo cuti pecahan', () {
      final json = Map<String, dynamic>.from(sampleDetailJson)
        ..['totalOvertime'] = 1
        ..['totalOvertimeMinutes'] = 360
        ..['totalLeaveRequest'] = 3
        ..['leaveBalances'] = [
          {
            'id': 'lb-1',
            'periodYear': 2026,
            'entitlement': 12,
            'used': 2.5,
            'remaining': 9.5,
            'expiredDate': '2026-12-31T00:00:00.000Z',
            'leaveType': {'id': 'lt-1', 'name': 'Cuti Tahunan', 'code': 'ANNUAL'},
          },
        ];
      final detail = EmployeeDetailData.fromJson(json);

      expect(detail.totalOvertime, 360);
      expect(detail.totalLeaveRequest, 3);
      expect(detail.leaveBalances.single.remaining, 9.5);
      expect(detail.leaveBalances.single.used, 2.5);
    });

    test('EmployeeDetailData tetap membaca totalOvertime lama bila totalOvertimeMinutes tidak ada', () {
      final json = Map<String, dynamic>.from(sampleDetailJson)
        ..remove('totalOvertimeMinutes')
        ..['totalOvertime'] = 150;

      expect(EmployeeDetailData.fromJson(json).totalOvertime, 150);
    });

    test('EmployeeDetailData fromJson parses all nested sections correctly', () {
      final detail = EmployeeDetailData.fromJson(sampleDetailJson);

      expect(detail.id, 'emp-detail-101');
      expect(detail.fullName, 'Dewi Sartika');
      expect(detail.initials, 'DS');
      expect(detail.bankName, 'BCA');
      expect(detail.company?.name, 'PT Oasish Nusantara');
      expect(detail.department?.name, 'Human Resources');
      expect(detail.position?.name, 'HR Specialist');
      expect(detail.manager?.fullName, 'Gunawan Wibowo');
      expect(detail.employeeWorkLocation.length, 1);
      expect(detail.employeeWorkLocation.first.name, 'Head Office SCBD');
      expect(detail.coworkers.length, 1);
      expect(detail.coworkers.first.fullName, 'Rina Novianti');
      expect(detail.leaveBalances.length, 1);
      expect(detail.leaveBalances.first.remaining, 9);
      expect(detail.leaveBalances.first.leaveType?.name, 'Cuti Tahunan');
    });

    test('EmployeeDetailData handles single-name and empty initial fallbacks', () {
      final singleNameJson = {
        'id': 'emp-102',
        'firstName': 'Mega',
        'email': 'mega@example.com',
      };
      final detail = EmployeeDetailData.fromJson(singleNameJson);
      expect(detail.fullName, 'Mega');
      expect(detail.initials, 'ME');

      const emptyDetail = EmployeeDetailData(
        id: 'emp-103',
        firstName: '',
        email: '',
      );
      expect(emptyDetail.fullName, '');
      expect(emptyDetail.initials, 'EP');
    });
  });

  group('OrganizationFilter Models Serialization Tests', () {
    test('CompanyItem, DepartmentItem, and PositionItem fromJson and toJson work correctly', () {
      final companyJson = {
        'id': 'comp-101',
        'name': 'PT Oasish Global',
        'address': 'Jakarta Selatan',
        'phone': '021-123456',
        'email': 'info@oasish.com',
      };
      final company = CompanyItem.fromJson(companyJson);
      expect(company.id, 'comp-101');
      expect(company.name, 'PT Oasish Global');
      expect(company.toJson()['id'], 'comp-101');

      final departmentJson = {
        'id': 'dept-201',
        'name': 'Teknologi Informasi',
        'code': 'IT',
        'companyId': 'comp-101',
        'company': {'name': 'PT Oasish Global'},
      };
      final department = DepartmentItem.fromJson(departmentJson);
      expect(department.id, 'dept-201');
      expect(department.name, 'Teknologi Informasi');
      expect(department.companyName, 'PT Oasish Global');
      expect(department.toJson()['code'], 'IT');

      final positionJson = {
        'id': 'pos-301',
        'name': 'Mobile Architect',
        'code': 'MA',
        'companyId': 'comp-101',
        'departmentId': 'dept-201',
        'company': {'name': 'PT Oasish Global'},
        'department': {'name': 'Teknologi Informasi'},
      };
      final position = PositionItem.fromJson(positionJson);
      expect(position.id, 'pos-301');
      expect(position.name, 'Mobile Architect');
      expect(position.companyName, 'PT Oasish Global');
      expect(position.departmentName, 'Teknologi Informasi');
      expect(position.toJson()['companyId'], 'comp-101');
    });
  });
}
