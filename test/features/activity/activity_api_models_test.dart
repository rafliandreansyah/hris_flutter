import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';

void main() {
  group('Activity API Models & Status Tests', () {
    test('ActivityDetailResponse parses complete API response correctly', () {
      final json = {
        'success': true,
        'message': 'Detail aktivitas berhasil dimuat',
        'data': {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'employeeId': 'emp-uuid-001',
          'activityTypeId': 'act-type-uuid',
          'locationName': 'Kantor Pusat SCBD',
          'startTime': '2026-09-07T03:53:00.234Z',
          'endTime': '2026-09-07T06:30:00.234Z',
          'description': 'Aktivitas pengujian sistem',
          'status': 'ongoing',
          'filePath': '/uploads/start.png',
          'filePath2': null,
          'notes': null,
          'createdAt': '2026-09-07T03:53:00.234Z',
          'updatedAt': '2026-09-07T03:53:00.234Z',
          'employee': {
            'id': 'emp-uuid-001',
            'userId': 'user-uuid-001',
            'firstName': 'Budi',
            'lastName': 'Santoso',
            'email': 'budi@example.com',
            'photoUrl': '/uploads/avatar.png',
            'company': {'id': 'c1', 'name': 'PT Oasish Tech Nusantara'},
            'department': {'id': 'd1', 'name': 'Operations'},
            'position': {'id': 'p1', 'name': 'Site Supervisor'},
            'level': {'id': 'l1', 'name': 'Senior'},
          },
        },
      };

      final response = ActivityDetailResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.message, 'Detail aktivitas berhasil dimuat');

      final item = response.toActivityItem(currentEmployeeId: 'emp-uuid-001');
      expect(item.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(item.employeeId, 'emp-uuid-001');
      expect(item.isMyActivity, isTrue);
      expect(item.userName, 'Budi Santoso');
      expect(item.userRole, 'Site Supervisor');
      expect(item.department, 'Operations');
      expect(item.company, 'PT Oasish Tech Nusantara');
      expect(item.status, ActivityStatus.ongoing);
      expect(item.location, 'Kantor Pusat SCBD');
      expect(item.filePath, 'https://apidev.hroasish.com/uploads/start.png');
      expect(item.avatarUrl, 'https://apidev.hroasish.com/uploads/avatar.png');
    });

    test('Maps backend status strings to StatusEmployeeActivity enum correctly', () {
      final jsonPlanned = {'status': 'planned'};
      final jsonOngoing = {'status': 'ongoing'};
      final jsonCompleted = {'status': 'completed'};
      final jsonCanceled = {'status': 'canceled'};

      expect(activityItemFromApiJson(jsonPlanned).status, ActivityStatus.planned);
      expect(activityItemFromApiJson(jsonOngoing).status, ActivityStatus.ongoing);
      expect(activityItemFromApiJson(jsonCompleted).status, ActivityStatus.completed);
      expect(activityItemFromApiJson(jsonCanceled).status, ActivityStatus.canceled);
    });

    test('resolveFileUrl handles absolute, relative, and null URLs cleanly', () {
      expect(resolveFileUrl(null), isNull);
      expect(resolveFileUrl(''), isNull);
      expect(
        resolveFileUrl('https://cdn.example.com/photo.jpg'),
        'https://cdn.example.com/photo.jpg',
      );
      expect(
        resolveFileUrl('uploads/photo.jpg'),
        'https://apidev.hroasish.com/uploads/photo.jpg',
      );
      expect(
        resolveFileUrl('/uploads/photo.jpg'),
        'https://apidev.hroasish.com/uploads/photo.jpg',
      );
    });

    test('ActivityActionResponse parses response correctly', () {
      final json = {'success': true, 'message': 'Aktivitas berhasil diselesaikan.'};
      final action = ActivityActionResponse.fromJson(json);
      expect(action.success, isTrue);
      expect(action.message, 'Aktivitas berhasil diselesaikan.');
    });

    test('ActivityFilterCriteria defaults to ongoing status and handles active filter count', () {
      const defaultCriteria = ActivityFilterCriteria();
      expect(defaultCriteria.status, 'ongoing');
      expect(defaultCriteria.hasActiveFilter, isFalse);
      expect(defaultCriteria.activeFilterCount, 0);

      final filteredCriteria = defaultCriteria.copyWith(status: 'completed');
      expect(filteredCriteria.status, 'completed');
      expect(filteredCriteria.hasActiveFilter, isTrue);
      expect(filteredCriteria.activeFilterCount, 1);
    });
  });
}
