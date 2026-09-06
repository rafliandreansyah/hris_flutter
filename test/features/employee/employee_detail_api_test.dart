import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MockEmployeeDetailRepository implements EmployeeRepository {
  String? lastDetailId;
  EmployeeDetailData? mockDetail;

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    return const EmployeeListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: EmployeePaginationMeta(page: 1, limit: 30, total: 0, totalPages: 1),
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async {
    lastDetailId = employeeId;
    if (mockDetail != null) {
      return mockDetail!;
    }
    throw Exception('Detail not found');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleDetailJson = {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "userId": "usr-uuid-1",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phone": "+628123456789",
    "emergencyContact": "+628987654321",
    "idNumber": "3171012345670001",
    "employeeNumber": "EMP-2024-777",
    "address": "Jl. Sudirman No. 10",
    "contractExpiryDate": null,
    "joinDate": "2023-01-15",
    "resignDate": null,
    "dob": "1992-05-12",
    "placeOfBirth": "Jakarta",
    "gender": "Laki-laki",
    "maritalStatus": "Menikah",
    "religion": "Islam",
    "nationality": "WNI",
    "postalCode": "10220",
    "photoUrl": "https://example.com/photo.jpg",
    "notes": null,
    "bloodType": "A+",
    "height": 175,
    "weight": 70,
    "wearingGlasses": false,
    "bankName": "Bank Mandiri",
    "bankAccount": "John Doe",
    "bankNumber": "123-00-9876543-2",
    "expectedSalary": 25000000,
    "employmentType": "Permanent",
    "taxNumber": "09.123.456.7-012.000",
    "bpjsNumber": "00012345678",
    "bpjsEmploymentNumber": "00098765432",
    "status": true,
    "timezone": "Asia/Jakarta",
    "company": {
      "id": "comp-1",
      "name": "PT Oasish Tech Nusantara",
      "address": "SCBD Lot 28",
      "phone": null,
      "email": null,
      "website": null,
      "taxId": null,
      "logoUrl": null
    },
    "department": {
      "id": "dept-1",
      "name": "Technology",
      "description": null,
      "code": "TECH",
      "companyId": null
    },
    "position": {
      "id": "pos-1",
      "name": "Principal Architect",
      "code": "PA",
      "description": null,
      "companyId": null
    },
    "level": {
      "id": "lvl-1",
      "name": "Level Principal (L6)",
      "code": null,
      "levelPower": 6,
      "description": null,
      "companyId": null
    },
    "manager": {
      "id": "mgr-1",
      "userId": "usr-mgr-1",
      "firstName": "Robert",
      "lastName": "Smith",
      "email": "robert@example.com",
      "phone": "+628111222333",
      "photoUrl": null,
      "employeeNumber": "EMP-2020-001",
      "idNumber": null
    },
    "country": {"id": "cnt-1", "name": "Indonesia"},
    "province": {"id": "prv-1", "name": "DKI Jakarta"},
    "city": {"id": "cty-1", "name": "Jakarta Selatan"},
    "district": {"id": "dst-1", "name": "Setiabudi"},
    "village": {"id": "vlg-1", "name": "Karet Semanggi"},
    "employeeWorkLocation": [
      {
        "id": "loc-1",
        "name": "HQ Office Sudirman",
        "address": "SCBD Lot 28 Floor 14, Jakarta Selatan",
        "radius": 100,
        "latitude": -6.225,
        "longitude": 106.809,
        "isAnyWhere": false,
        "isDefault": true
      }
    ],
    "coworkers": [
      {
        "id": "cw-1",
        "firstName": "Alice",
        "lastName": "Wong",
        "email": "alice@example.com",
        "phone": "+62812334455",
        "photoUrl": null,
        "employeeNumber": "EMP-2024-002",
        "idNumber": null
      }
    ],
    "lastWarningLetter": null,
    "leaveBalances": [
      {
        "id": "lb-1",
        "leaveTypeId": "lt-1",
        "periodYear": 2026,
        "entitlement": 12,
        "used": 4,
        "remaining": 8,
        "effectiveDate": null,
        "expiredDate": null,
        "source": null,
        "notes": null,
        "leaveType": {
          "id": "lt-1",
          "name": "Cuti Tahunan",
          "code": "AL",
          "description": null
        }
      }
    ],
    "totalOvertime": 6,
    "totalLeaveRequest": 2
  };

  group('EmployeeDetailModel Serialization Tests', () {
    test('EmployeeDetailData.fromJson parses full detail payload accurately', () {
      final detail = EmployeeDetailData.fromJson(sampleDetailJson);

      expect(detail.id, "123e4567-e89b-12d3-a456-426614174000");
      expect(detail.fullName, "John Doe");
      expect(detail.initials, "JD");
      expect(detail.employeeNumber, "EMP-2024-777");
      expect(detail.email, "john.doe@example.com");
      expect(detail.phone, "+628123456789");
      expect(detail.company?.name, "PT Oasish Tech Nusantara");
      expect(detail.department?.name, "Technology");
      expect(detail.position?.name, "Principal Architect");
      expect(detail.level?.name, "Level Principal (L6)");
      expect(detail.manager?.fullName, "Robert Smith");
      expect(detail.manager?.employeeNumber, "EMP-2020-001");
      expect(detail.city?.name, "Jakarta Selatan");
      expect(detail.employeeWorkLocation.length, 1);
      expect(detail.employeeWorkLocation.first.name, "HQ Office Sudirman");
      expect(detail.coworkers.length, 1);
      expect(detail.coworkers.first.fullName, "Alice Wong");
      expect(detail.leaveBalances.length, 1);
      expect(detail.leaveBalances.first.leaveType?.name, "Cuti Tahunan");
      expect(detail.totalOvertime, 6);
      expect(detail.totalLeaveRequest, 2);
    });
  });

  group('EmployeeDetailScreen API Loading Tests', () {
    late MockEmployeeDetailRepository mockRepo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      mockRepo = MockEmployeeDetailRepository();
      mockRepo.mockDetail = EmployeeDetailData.fromJson(sampleDetailJson);
    });

    testWidgets('Loads detail using item ID when opened from Employee Directory', (
      WidgetTester tester,
    ) async {
      const item = EmployeeDirectoryItem(
        id: 'EMP-2024-777',
        rawId: '123e4567-e89b-12d3-a456-426614174000',
        name: 'John Doe',
        role: 'Principal Architect',
        department: 'Technology',
        email: 'john.doe@example.com',
        initials: 'JD',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDetailScreen(
            employee: item,
            repository: mockRepo,
          ),
        ),
      );

      // Initial pump
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.lastDetailId, '123e4567-e89b-12d3-a456-426614174000');
      expect(find.text('John Doe'), findsWidgets);
      expect(find.textContaining('Principal Architect'), findsWidgets);
      expect(find.textContaining('Technology'), findsWidgets);
      expect(find.text('Robert Smith'), findsOneWidget); // Manager
      expect(find.text('Alice Wong'), findsOneWidget); // Coworker
      // Edit icon must be hidden when opened from Employee Directory
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
    });

    testWidgets('Loads detail using local storage employee ID when opened from profile', (
      WidgetTester tester,
    ) async {
      // Save local employee ID
      await SecureStorageService.instance.saveEmployeeId('123e4567-e89b-12d3-a456-426614174000');

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDetailScreen(
            repository: mockRepo,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.lastDetailId, '123e4567-e89b-12d3-a456-426614174000');
      expect(find.text('John Doe'), findsWidgets);
      expect(find.text('EMP-2024-777 • Technology'), findsOneWidget);
      // Edit icon must be visible when opened from user profile
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });

    testWidgets('Displays empty info when manager is null and coworkers is empty', (
      WidgetTester tester,
    ) async {
      final jsonWithoutManagerAndCoworkers = Map<String, dynamic>.from(sampleDetailJson);
      jsonWithoutManagerAndCoworkers['manager'] = null;
      jsonWithoutManagerAndCoworkers['coworkers'] = [];

      mockRepo.mockDetail = EmployeeDetailData.fromJson(jsonWithoutManagerAndCoworkers);

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDetailScreen(
            employeeId: '123e4567-e89b-12d3-a456-426614174000',
            repository: mockRepo,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Belum Ada Atasan Langsung'), findsOneWidget);
      expect(find.text('Belum Ada Rekan Kerja'), findsOneWidget);
    });
  });
}
