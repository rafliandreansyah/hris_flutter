import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';

void main() {
  group('UserProfileData Tests', () {
    test('parses complete user profile JSON correctly', () {
      final json = {
        "user": {
          "id": "u-123",
          "email": "user@oasish.com",
          "role": "EMPLOYEE",
          "language": "en"
        },
        "dataScope": "DEPARTMENT",
        "accessibleCompanyIds": ["c-1", "c-2"],
        "accessibleDepartmentIds": ["d-1"],
        "permissions": ["attendance:view", "activity:create"],
        "employee": {
          "id": "e-456",
          "employeeNumber": "EMP-001",
          "firstName": "Budi",
          "lastName": "Santoso",
          "company": {"id": "c-1", "name": "PT Oasish Tech"},
          "department": {"id": "d-1", "name": "Engineering"},
          "position": {"id": "p-1", "name": "Staff"}
        }
      };

      final data = UserProfileData.fromJson(json);

      expect(data.user.id, "u-123");
      expect(data.user.email, "user@oasish.com");
      expect(data.user.role, "EMPLOYEE");
      expect(data.user.language, "en");

      expect(data.dataScope, "DEPARTMENT");
      expect(data.permissions, ["attendance:view", "activity:create"]);

      expect(data.employee, isNotNull);
      expect(data.employee!.firstName, "Budi");
      expect(data.employee!.lastName, "Santoso");
      expect(data.employee!.fullName, "Budi Santoso");
      expect(data.employee!.company?.name, "PT Oasish Tech");
      expect(data.employee!.department?.name, "Engineering");
      expect(data.employee!.position?.name, "Staff");
    });

    test('handles null and partial fields in profile JSON', () {
      final json = {
        "user": {
          "id": "u-999",
          "email": "minimal@oasish.com",
        },
        "dataScope": "SELF",
      };

      final data = UserProfileData.fromJson(json);

      expect(data.user.language, isNull);
      expect(data.permissions, isEmpty);
      expect(data.employee, isNull);
    });

    test('UserProfileData toJson and fromJson symmetry', () {
      const original = UserProfileData(
        user: UserModel(id: 'u-1', email: 'a@b.com', language: 'id'),
        dataScope: 'ALL',
        permissions: ['read', 'write'],
      );

      final json = original.toJson();
      final reconstructed = UserProfileData.fromJson(json);

      expect(reconstructed.user.id, original.user.id);
      expect(reconstructed.user.language, 'id');
      expect(reconstructed.dataScope, 'ALL');
      expect(reconstructed.permissions, ['read', 'write']);
    });
  });
}
