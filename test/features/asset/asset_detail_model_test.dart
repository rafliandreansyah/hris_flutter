import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:hris_flutter/features/asset/data/models/create_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/direct_transfer_asset_payload.dart';
import 'package:hris_flutter/features/asset/data/models/handover_asset_payload.dart';

void main() {
  group('AssetDetailModel Tests', () {
    test('AssetDetailResponse and AssetDetailData fromJson & toJson parse correctly', () {
      final json = {
        'success': true,
        'message': 'Detail aset berhasil dimuat',
        'data': {
          'id': 'ast-001',
          'companyId': 'comp-1',
          'categoryId': 'cat-1',
          'assetCode': 'AST-2024-001',
          'name': 'MacBook Pro M3 Max 16"',
          'brand': 'Apple',
          'model': 'A2991',
          'serialNumber': 'C02G1234MD6R',
          'purchaseDate': '2024-01-15T00:00:00.000Z',
          'purchaseCost': 45000000.0,
          'warrantyExpiry': '2026-01-15T00:00:00.000Z',
          'vendor': 'iBox Indonesia',
          'location': 'Gudang IT Lt. 2, Rak B-03',
          'condition': 'GOOD',
          'status': 'AVAILABLE',
          'photoUrl': 'https://storage.googleapis.com/assets/macbook.png',
          'notes': 'Unit baru garansi resmi',
          'createdAt': '2024-01-15T10:00:00.000Z',
          'updatedAt': '2024-01-15T10:00:00.000Z',
          'category': {
            'id': 'cat-1',
            'companyId': 'comp-1',
            'name': 'Laptop & Komputer',
            'code': 'LAPTOP',
            'description': 'Laptop kerja operasional',
          },
          'assignments': [
            {
              'id': 'asg-001',
              'assetId': 'ast-001',
              'employeeId': 'emp-101',
              'transferredFromId': null,
              'assignedDate': '2024-02-01T08:00:00.000Z',
              'expectedReturnDate': '2025-02-01T08:00:00.000Z',
              'returnedDate': null,
              'conditionOnCheckout': 'GOOD',
              'conditionOnCheckin': null,
              'checkoutNotes': 'Diserahkan dalam kondisi lengkap',
              'checkinNotes': null,
              'status': 'ACTIVE',
              'acceptedAt': '2024-02-01T08:30:00.000Z',
              'rejectedAt': null,
              'rejectionReason': null,
              'signatureUrl': 'https://storage/signature.png',
              'handoverPhotoUrl': 'https://storage/handover.jpg',
              'createdAt': '2024-02-01T08:00:00.000Z',
              'employee': {
                'id': 'emp-101',
                'employeeNumber': 'EMP-2024-001',
                'firstName': 'Budi',
                'lastName': 'Santoso',
                'email': 'budi@example.com',
                'position': 'Senior Engineer',
                'department': 'Engineering',
                'company': 'PT Muratech',
              },
              'transferredFrom': null,
            }
          ]
        }
      };

      final response = AssetDetailResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.message, 'Detail aset berhasil dimuat');
      expect(response.data.id, 'ast-001');
      expect(response.data.assetCode, 'AST-2024-001');
      expect(response.data.name, 'MacBook Pro M3 Max 16"');
      expect(response.data.brand, 'Apple');
      expect(response.data.purchaseCost, 45000000.0);
      expect(response.data.category?.name, 'Laptop & Komputer');
      expect(response.data.assignments.length, 1);

      // Verify activeAssignment helper
      final active = response.data.activeAssignment;
      expect(active, isNotNull);
      expect(active?.employeeId, 'emp-101');
      expect(active?.employee?.fullName, 'Budi Santoso');
      expect(active?.employee?.initials, 'BS');

      // Verify toJson
      final exportedJson = response.toJson();
      expect(exportedJson['success'], isTrue);
      expect(exportedJson['data']['id'], 'ast-001');
    });

    test('AssetAssigneeEmployeeModel handles single name and missing employee fields', () {
      const emp = AssetAssigneeEmployeeModel(
        id: 'emp-102',
        firstName: 'Siti',
        employeeNumber: 'EMP-002',
      );
      expect(emp.fullName, 'Siti');
      expect(emp.initials, 'S');

      final json = emp.toJson();
      final parsed = AssetAssigneeEmployeeModel.fromJson(json);
      expect(parsed.fullName, 'Siti');
      expect(parsed.initials, 'S');
    });

    test('AssetTransferredFromModel handles initials and name resolution', () {
      const transfer = AssetTransferredFromModel(
        id: 'trf-001',
        employee: AssetAssigneeEmployeeModel(
          id: 'emp-103',
          firstName: 'Agus',
          lastName: 'Pratama',
        ),
      );
      expect(transfer.employeeName, 'Agus Pratama');
      expect(transfer.employeeInitials, 'AP');

      const transferNoEmp = AssetTransferredFromModel(id: 'trf-002');
      expect(transferNoEmp.employeeName, '-');
      expect(transferNoEmp.employeeInitials, 'AS');
    });

    test('AssetAssignmentItemModel status helpers work accurately', () {
      final activeItem = AssetAssignmentItemModel.fromJson(const {
        'id': 'asg-1',
        'status': 'ACTIVE',
      });
      expect(activeItem.isActive, isTrue);
      expect(activeItem.isPending, isFalse);

      final pendingItem = AssetAssignmentItemModel.fromJson(const {
        'id': 'asg-2',
        'status': 'PENDING_ACCEPTANCE',
      });
      expect(pendingItem.isPending, isTrue);
      expect(pendingItem.isActive, isFalse);
    });

    test('CreateAssetPayload toJson converts fields accurately', () {
      final payload = CreateAssetPayload(
        categoryId: 'cat-1',
        assetCode: 'AST-099',
        name: 'Dell XPS 15',
        brand: 'Dell',
        model: '9530',
        serialNumber: 'SN12345',
        purchaseDate: DateTime(2024, 5, 10),
        purchaseCost: 28000000,
        warrantyExpiry: DateTime(2027, 5, 10),
        vendor: 'Dell Official Store',
        location: 'Gudang IT Lt. 2',
        condition: 'NEW',
        notes: 'Daftar unit baru',
        assignedToEmployeeId: 'emp-501',
      );

      final json = payload.toJson();
      expect(json['categoryId'], 'cat-1');
      expect(json['assetCode'], 'AST-099');
      expect(json['name'], 'Dell XPS 15');
      expect(json['purchaseCost'], 28000000);
      expect(json['assignedToEmployeeId'], 'emp-501');
      expect(json['purchaseDate'], contains('2024-05-10'));
    });

    test('HandoverAssetPayload toJson converts fields accurately', () {
      final payload = HandoverAssetPayload(
        employeeId: 'emp-201',
        assignedDate: DateTime(2024, 6, 1),
        expectedReturnDate: DateTime(2025, 6, 1),
        conditionOnCheckout: 'GOOD',
        checkoutNotes: 'Lengkap dengan tas laptop',
      );

      final json = payload.toJson();
      expect(json['employeeId'], 'emp-201');
      expect(json['conditionOnCheckout'], 'GOOD');
      expect(json['checkoutNotes'], 'Lengkap dengan tas laptop');
      expect(json['assignedDate'], contains('2024-06-01'));
      expect(json['expectedReturnDate'], contains('2025-06-01'));
    });

    test('DirectTransferAssetPayload toJson converts fields accurately', () {
      final payload = DirectTransferAssetPayload(
        targetEmployeeId: 'emp-301',
        assignedDate: DateTime(2024, 7, 1),
        conditionOnCheckout: 'GOOD',
        checkoutNotes: 'Oper ke rekan',
        requireApproval: true,
      );

      final json = payload.toJson();
      expect(json['targetEmployeeId'], 'emp-301');
      expect(json['conditionOnCheckout'], 'GOOD');
      expect(json['checkoutNotes'], 'Oper ke rekan');
      expect(json['requireApproval'], isTrue);
    });
  });
}
