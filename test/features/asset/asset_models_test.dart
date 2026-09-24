import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_filter_criteria.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('AssetCategoryModel Tests', () {
    test('fromJson & toJson berfungsi dengan benar', () {
      final json = {
        'id': 'cat-1',
        'companyId': 'comp-1',
        'name': 'Laptop & Komputer',
        'code': 'LAPTOP',
        'description': 'Perangkat laptop kerja',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
      };

      final model = AssetCategoryModel.fromJson(json);
      expect(model.id, 'cat-1');
      expect(model.companyId, 'comp-1');
      expect(model.name, 'Laptop & Komputer');
      expect(model.code, 'LAPTOP');
      expect(model.description, 'Perangkat laptop kerja');

      final serialized = model.toJson();
      expect(serialized['id'], 'cat-1');
      expect(serialized['code'], 'LAPTOP');
    });
  });

  group('AssetFilterCriteria Tests', () {
    test('initial values', () {
      final filter = AssetFilterCriteria.initial();
      expect(filter.status, 'all');
      expect(filter.categoryId, isNull);
      expect(filter.sortBy, 'newest');
      expect(filter.hasActiveFilter, isFalse);
      expect(filter.activeFilterCount, 0);
    });

    test('hasActiveFilter dan activeFilterCount saat filter terisi', () {
      const filter = AssetFilterCriteria(
        status: 'PENDING_ACCEPTANCE',
        categoryId: 'cat-1',
        categoryName: 'Laptop',
        sortBy: 'name_asc',
        search: 'MacBook',
      );

      expect(filter.hasActiveFilter, isTrue);
      expect(filter.activeFilterCount, 4);
    });

    test('copyWith bekerja dengan benar', () {
      final initial = AssetFilterCriteria.initial();
      final updated = initial.copyWith(
        status: 'ACTIVE',
        categoryId: 'cat-2',
        sortBy: 'oldest',
      );

      expect(updated.status, 'ACTIVE');
      expect(updated.categoryId, 'cat-2');
      expect(updated.sortBy, 'oldest');

      final cleared = updated.copyWith(clearCategory: true);
      expect(cleared.categoryId, isNull);
    });
  });

  group('AssetListItem Model & Response Tests', () {
    test('fromJson mem-parse respon backend API secara lengkap', () {
      final json = {
        'id': 'asset-001',
        'assignmentId': 'assign-001',
        'assetCode': 'AST-LPT-012',
        'name': 'Dell XPS 15 (2024)',
        'brand': 'Dell',
        'model': 'XPS 15',
        'serialNumber': 'Seri 2024',
        'status': 'PENDING_ACCEPTANCE',
        'condition': 'GOOD',
        'location': 'Jakarta Office',
        'assignedDate': '2025-01-15T09:00:00.000Z',
        'category': {
          'id': 'cat-1',
          'name': 'Laptop',
          'code': 'LPT',
        },
        'isPendingTransfer': true,
        'pendingTransferTo': {
          'assignmentId': 'assign-002',
          'employeeId': 'emp-002',
          'employeeName': 'Budi Santoso',
          'requestedAt': '2025-01-16T10:00:00.000Z',
        },
        'transferredFrom': {
          'assignmentId': 'assign-000',
          'employeeId': 'emp-001',
          'employeeName': 'Rina Sari',
          'conditionOnCheckout': 'GOOD',
          'checkoutNotes': 'Kondisi mulus',
          'department': 'Marketing',
        },
      };

      final item = AssetListItem.fromJson(json);

      expect(item.id, 'asset-001');
      expect(item.assignmentId, 'assign-001');
      expect(item.assetCode, 'AST-LPT-012');
      expect(item.name, 'Dell XPS 15 (2024)');
      expect(item.isPendingAcceptance, isTrue);
      expect(item.statusLabel, 'Menunggu');
      expect(item.category?.name, 'Laptop');
      expect(item.categoryIcon, LucideIcons.laptop);
      expect(item.transferredFrom?.initials, 'RS');
      expect(item.transferredFrom?.shortName, 'Rina S.');
      expect(item.pendingTransferTo?.employeeName, 'Budi Santoso');
    });

    test('TransferredFromModel initials dengan satu kata atau banyak kata', () {
      const model1 = TransferredFromModel(
        assignmentId: '1',
        employeeId: '1',
        employeeName: 'Rafli',
      );
      expect(model1.initials, 'RA');
      expect(model1.shortName, 'Rafli');

      const model2 = TransferredFromModel(
        assignmentId: '2',
        employeeId: '2',
        employeeName: 'Doni Pratama',
      );
      expect(model2.initials, 'DP');
      expect(model2.shortName, 'Doni P.');
    });

    test('categoryIcon mendeteksi smartphone, mobil, dan monitor dengan benar', () {
      const phoneItem = AssetListItem(
        id: '1',
        assetCode: 'AST-PHN-001',
        name: 'Samsung Galaxy S24 Ultra',
        status: 'ACTIVE',
      );
      expect(phoneItem.categoryIcon, LucideIcons.smartphone);

      const carItem = AssetListItem(
        id: '2',
        assetCode: 'AST-VCL-001',
        name: 'Innova Zenix Q Hybrid',
        status: 'ACTIVE',
      );
      expect(carItem.categoryIcon, LucideIcons.car);

      const monitorItem = AssetListItem(
        id: '3',
        assetCode: 'AST-MON-001',
        name: 'LG 27 Inch 4K Monitor',
        status: 'ACTIVE',
      );
      expect(monitorItem.categoryIcon, LucideIcons.monitor);
    });

    test('AssetListResponse mem-parse data list dan meta pagination', () {
      final json = {
        'success': true,
        'message': 'Berhasil memuat data',
        'data': [
          {
            'id': '1',
            'assetCode': 'AST-001',
            'name': 'MacBook Pro',
            'status': 'ACTIVE',
          }
        ],
        'meta': {
          'page': 1,
          'limit': 10,
          'total': 1,
          'totalPages': 1,
        }
      };

      final response = AssetListResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.data.length, 1);
      expect(response.data.first.name, 'MacBook Pro');
      expect(response.meta?.total, 1);
      expect(response.meta?.totalPages, 1);
    });
  });
}
