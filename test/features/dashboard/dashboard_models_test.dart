import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';

void main() {
  group('DashboardResponseModel Tests', () {
    test('parses sample json from user specification successfully', () {
      final json = {
        "success": true,
        "message": "Data retrieved successfully",
        "data": {
          "id": "123e4567-e89b-12d3-a456-426614174000",
          "firstName": "John",
          "lastName": "Doe",
          "email": "hello@example.com",
          "phone": "+628123456789",
          "idNumber": null,
          "employeeNumber": "EMP-001",
          "timezone": "Asia/Jakarta",
          "company": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "PT Oasish Tech Nusantara"
          },
          "department": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Engineering",
            "code": "ENG"
          },
          "position": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Senior Software Engineer",
            "code": "SWE"
          },
          "employeeDevice": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "deviceId": "device-xyz",
            "deviceName": "iPhone 16",
            "deviceModel": "A3081",
            "osVersion": "iOS 18",
            "appVersion": "1.0.0"
          },
          "todaySchedule": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "workDate": "2026-09-06",
            "shift": {
              "id": "123e4567-e89b-12d3-a456-426614174000",
              "startTime": "08:00",
              "endTime": "17:00",
              "isFlexibleTime": false,
              "isFlexibleBreak": true,
              "breakStart": null,
              "breakEnd": null,
              "isNightShift": false,
              "status": true
            }
          },
          "timeServer": "2026-09-06T08:15:26.594Z",
          "latestAnnouncement": [
            {
              "id": "123e4567-e89b-12d3-a456-426614174000",
              "title": "Townhall Meeting This Friday",
              "imageUrl": null,
              "createdAt": "2026-09-06T07:00:00.000Z"
            }
          ],
          "attendanceSummary": {
            "todayAttendance": {
              "inTime": "08:05",
              "outTime": null,
              "isOnBreak": false,
              "totalBreakMinutes": 0,
              "overbreakMinutes": 0,
              "breaks": []
            },
            "attendanceInfoThisMonth": {
              "totalAttendance": 5,
              "lateDays": 1
            },
            "quotaLeaveBalanceThisYear": {
              "totalQuota": 14,
              "totalUsed": 3
            }
          }
        }
      };

      final response = DashboardResponseModel.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, equals('Data retrieved successfully'));
      expect(response.data, isNotNull);

      final data = response.data!;
      expect(data.firstName, equals('John'));
      expect(data.fullName, equals('John Doe'));
      expect(data.email, equals('hello@example.com'));
      expect(data.timezone, equals('Asia/Jakarta'));
      expect(data.company?.name, equals('PT Oasish Tech Nusantara'));
      expect(data.department?.name, equals('Engineering'));
      expect(data.todaySchedule?.shift?.startTime, equals('08:00'));
      expect(data.timeServer, equals('2026-09-06T08:15:26.594Z'));
      expect(data.latestAnnouncement.length, equals(1));
      expect(data.latestAnnouncement.first.title,
          equals('Townhall Meeting This Friday'));
      expect(data.attendanceSummary?.todayAttendance?.inTime, equals('08:05'));
      expect(data.attendanceSummary?.quotaLeaveBalanceThisYear?.totalQuota,
          equals(14));
      expect(data.attendanceSummary?.quotaLeaveBalanceThisYear?.remaining,
          equals(11));
      expect(data.initials, equals('JD'));

      // Test toJson
      final toJson = response.toJson();
      expect(toJson['success'], isTrue);
      expect(toJson['data'], isA<Map<String, dynamic>>());
    });

    test('DashboardData correctly parses and handles photoUrl and initials', () {
      final jsonWithPhoto = {
        'id': 'emp-123',
        'firstName': 'Sarah',
        'lastName': 'Jenkins',
        'email': 'sarah@example.com',
        'photoUrl': 'https://example.com/sarah.png',
      };

      final data1 = DashboardData.fromJson(jsonWithPhoto);
      expect(data1.photoUrl, equals('https://example.com/sarah.png'));
      expect(data1.fullName, equals('Sarah Jenkins'));
      expect(data1.initials, equals('SJ'));
      expect(data1.toJson()['photoUrl'], equals('https://example.com/sarah.png'));

      final jsonWithoutPhoto = {
        'id': 'emp-456',
        'firstName': 'Budi',
        'lastName': null,
        'email': 'budi@example.com',
        'photoUrl': null,
      };

      final data2 = DashboardData.fromJson(jsonWithoutPhoto);
      expect(data2.photoUrl, isNull);
      expect(data2.fullName, equals('Budi'));
      expect(data2.initials, equals('BU'));
      expect(data2.toJson().containsKey('photoUrl'), isFalse);
    });

    test('parses updated employee dashboard response json from user specification successfully', () {
      final json = {
        "success": true,
        "message": "string",
        "data": {
          "id": "123e4567-e89b-12d3-a456-426614174000",
          "firstName": "string",
          "lastName": null,
          "email": "hello@example.com",
          "phone": "string",
          "idNumber": null,
          "employeeNumber": null,
          "timezone": "string",
          "company": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "string"
          },
          "department": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "string",
            "code": null
          },
          "position": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "string",
            "code": null
          },
          "employeeDevice": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "deviceId": "string",
            "deviceName": null,
            "deviceModel": null,
            "osVersion": null,
            "appVersion": null
          },
          "todaySchedule": {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "workDate": "string",
            "shift": {
              "id": "123e4567-e89b-12d3-a456-426614174000",
              "startTime": null,
              "endTime": null,
              "isFlexibleTime": true,
              "isFlexibleBreak": true,
              "breakStart": null,
              "breakEnd": null,
              "isNightShift": true,
              "status": true
            }
          },
          "timeServer": "string",
          "latestAnnouncement": [
            {
              "id": "123e4567-e89b-12d3-a456-426614174000",
              "title": "string",
              "imageUrl": null,
              "createdAt": "string"
            }
          ],
          "attendanceSummary": {
            "todayAttendance": {
              "inTime": null,
              "outTime": null,
              "isOnBreak": true,
              "totalBreakMinutes": 1,
              "overbreakMinutes": 1,
              "breaks": [
                {
                  "id": "123e4567-e89b-12d3-a456-426614174000",
                  "startTime": "string",
                  "endTime": null,
                  "durationMinutes": null,
                  "note": null
                }
              ]
            }
          }
        }
      };

      final response = DashboardResponseModel.fromJson(json);

      expect(response.success, isTrue);
      expect(response.data, isNotNull);
      final data = response.data!;
      expect(data.firstName, equals('string'));
      expect(data.lastName, isNull);
      expect(data.email, equals('hello@example.com'));
      expect(data.todaySchedule?.shift?.isFlexibleTime, isTrue);
      expect(data.attendanceSummary?.todayAttendance?.isOnBreak, isTrue);
      expect(data.attendanceSummary?.todayAttendance?.totalBreakMinutes, equals(1));
      expect(data.attendanceSummary?.todayAttendance?.overbreakMinutes, equals(1));
      expect(data.attendanceSummary?.todayAttendance?.breaks.length, equals(1));
      expect(data.attendanceSummary?.todayAttendance?.breaks.first.startTime, equals('string'));
      expect(data.attendanceSummary?.quotaLeaveBalanceThisYear, isNull);
    });
  });

  group('MenuResponseModel Tests', () {
    test('parses sample menus json successfully', () {
      final json = {
        "success": true,
        "message": "Menus retrieved",
        "data": [
          {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "Employee Detail",
            "code": "employee",
            "platform": "mobile",
            "description": null,
            "icon": "id-card",
            "path": "/employee-detail",
            "parentId": null,
            "order": 1,
            "status": true,
            "createdAt": "2026-09-06T00:51:26.594Z",
            "updatedAt": "2026-09-06T00:51:26.594Z",
            "deletedAt": null
          },
          {
            "id": "123e4567-e89b-12d3-a456-426614174001",
            "name": "Attendance",
            "code": "attendance",
            "platform": "mobile",
            "description": null,
            "icon": null,
            "path": null,
            "parentId": null,
            "order": 2,
            "status": true,
            "createdAt": "2026-09-06T00:51:26.594Z",
            "updatedAt": "2026-09-06T00:51:26.594Z",
            "deletedAt": null
          }
        ]
      };

      final response = MenuResponseModel.fromJson(json);

      expect(response.success, isTrue);
      expect(response.data.length, equals(2));
      expect(response.data.first.code, equals('employee'));
      expect(response.data.first.name, equals('Employee Detail'));
      expect(response.data.last.code, equals('attendance'));

      final toJson = response.toJson();
      expect(toJson['success'], isTrue);
      expect((toJson['data'] as List).length, equals(2));
    });
  });
}
