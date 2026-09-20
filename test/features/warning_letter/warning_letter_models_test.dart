import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_filter_criteria.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';

void main() {
  group('WarningLetterTypeModel Tests', () {
    test('fromJson and toJson map correctly', () {
      final json = {
        'id': 'wl-type-1',
        'name': 'Surat Peringatan I (SP 1)',
        'level': 1,
        'validityPeriodMonths': 6,
      };

      final model = WarningLetterTypeModel.fromJson(json);
      expect(model.id, 'wl-type-1');
      expect(model.name, 'Surat Peringatan I (SP 1)');
      expect(model.level, 1);
      expect(model.validityPeriodMonths, 6);

      final outJson = model.toJson();
      expect(outJson['id'], 'wl-type-1');
      expect(outJson['level'], 1);
    });
  });

  group('WarningLetterItem & Sub-models Tests', () {
    test('WarningLetterEmployee resolves fullName and initials correctly', () {
      final employee = WarningLetterEmployee.fromJson(const {
        'id': 'emp-101',
        'firstName': 'Budi',
        'lastName': 'Santoso',
        'email': 'budi@example.com',
        'phone': '08123456789',
        'idNumber': 'ID-12345',
        'employeeNumber': 'EMP-8492',
        'company': {'id': 'comp-1', 'name': 'PT Muratech'},
        'department': {'id': 'dept-1', 'name': 'Operations', 'code': 'OPS'},
        'position': {'id': 'pos-1', 'name': 'Site Supervisor', 'code': 'SS'},
        'photoUrl': 'https://example.com/avatar.png',
      });

      expect(employee.fullName, 'Budi Santoso');
      expect(employee.initials, 'BS');
      expect(employee.company?.name, 'PT Muratech');
      expect(employee.department?.name, 'Operations');
      expect(employee.position?.name, 'Site Supervisor');
      expect(employee.employeeNumber, 'EMP-8492');
    });

    test('WarningLetterEmployee handles null lastName gracefully', () {
      final employee = WarningLetterEmployee.fromJson(const {
        'id': 'emp-102',
        'firstName': 'Dimas',
        'lastName': null,
      });

      expect(employee.fullName, 'Dimas');
      expect(employee.initials, 'DI');
    });

    test('WarningLetterItem parses complete response and helper getters', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'warningLetterType': {
          'level': 2,
          'name': 'Pelanggaran SOP & Ketidakpatuhan Kerja',
        },
        'employee': {
          'id': 'emp-101',
          'firstName': 'Budi',
          'lastName': 'Santoso',
          'employeeNumber': 'EMP-8492',
          'company': {'id': 'c-1', 'name': 'PT Muratech'},
          'department': {'id': 'd-1', 'name': 'Operations'},
          'position': {'id': 'p-1', 'name': 'Site Supervisor'},
        },
        'isActive': true,
        'createdAt': '2026-08-29T12:47:00.000Z',
        'timezone': 'WIB',
      };

      final item = WarningLetterItem.fromJson(json);
      expect(item.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(item.warningLetterType.level, 2);
      expect(item.warningLetterType.name,
          'Pelanggaran SOP & Ketidakpatuhan Kerja');
      expect(item.levelBadgeLabel, 'SP 2');
      expect(item.isActive, true);
      expect(item.timezone, 'WIB');
      expect(item.formattedCreatedAt, contains('2026'));
      expect(item.formattedCreatedAt, contains('WIB'));
    });
  });

  group('WarningLetterListResponse Tests', () {
    test('parses full API list response correctly', () {
      final json = {
        'success': true,
        'message': 'Data retrieved successfully',
        'data': [
          {
            'id': 'item-1',
            'warningLetterType': {'level': 1, 'name': 'SP 1'},
            'isActive': true,
            'createdAt': '2026-09-19T03:28:34.150Z',
            'timezone': 'WIB',
          }
        ],
        'meta': {
          'page': 1,
          'limit': 10,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = WarningLetterListResponse.fromJson(json);
      expect(response.success, true);
      expect(response.message, 'Data retrieved successfully');
      expect(response.data.length, 1);
      expect(response.data[0].id, 'item-1');
      expect(response.meta.page, 1);
      expect(response.meta.totalPages, 1);
      expect(response.meta.hasNextPage, false);
    });
  });

  group('WarningLetterFilterCriteria Tests', () {
    test('hasActiveFilter and activeFilterCount evaluate correctly', () {
      const defaultCriteria = WarningLetterFilterCriteria();
      expect(defaultCriteria.hasActiveFilter, false);
      expect(defaultCriteria.activeFilterCount, 0);

      final criteriaWithStatus = defaultCriteria.copyWith(status: 'active');
      expect(criteriaWithStatus.hasActiveFilter, true);
      expect(criteriaWithStatus.activeFilterCount, 1);

      final criteriaWithType = criteriaWithStatus.copyWith(
        letterTypeId: 'type-1',
        letterTypeName: 'SP 1',
      );
      expect(criteriaWithType.hasActiveFilter, true);
      expect(criteriaWithType.activeFilterCount, 2);

      final dateRange = DateTimeRange(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 31),
      );
      final criteriaWithDate = criteriaWithType.copyWith(dateRange: dateRange);
      expect(criteriaWithDate.hasActiveFilter, true);
      expect(criteriaWithDate.activeFilterCount, 3);
      expect(criteriaWithDate.startDateParam, '2026-08-01');
      expect(criteriaWithDate.endDateParam, '2026-08-31');
    });
  });
}
