import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:hris_flutter/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:hris_flutter/features/overtime/presentation/models/overtime_request_item.dart';
import 'package:image_picker/image_picker.dart';

class _MockOvertimeRemoteDataSource implements OvertimeRemoteDataSource {
  OvertimeRequestListResponse? mockListResponse;
  OvertimeScheduleData? mockScheduleData;
  CreateOvertimeResultModel? mockCreateResult;
  OvertimeDetailData? mockDetailData;

  String? lastApprovedId;
  bool? lastIsApproved;
  String? lastApproverNotes;
  String? lastDeletedId;
  bool shouldThrow = false;

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
    String? statusApprove,
  }) async {
    if (shouldThrow) throw const ApiException(message: 'Error fetching overtime');
    return mockListResponse ??
        const OvertimeRequestListResponse(
          success: true,
          message: 'OK',
          data: [],
          meta: OvertimePaginationMeta(page: 1, limit: 30, total: 0, totalPages: 1),
        );
  }

  @override
  Future<OvertimeScheduleData> getOvertimeSchedule({
    required String dateTimeStart,
  }) async {
    if (shouldThrow) throw const ApiException(message: 'Error fetching schedule');
    return mockScheduleData ??
        const OvertimeScheduleData(
          isGenerated: false,
          isDayOff: false,
          workScheduleId: 'ws-1',
        );
  }

  @override
  Future<CreateOvertimeResultModel> createOvertimeRequest({
    required String startOvertime,
    required String endOvertime,
    required String notes,
    String? workScheduleId,
    required XFile file,
  }) async {
    if (shouldThrow) throw const ApiException(message: 'Error creating overtime');
    return mockCreateResult ??
        const CreateOvertimeResultModel(
          success: true,
          message: 'OK',
          id: 'ot-created-1',
        );
  }

  @override
  Future<OvertimeDetailData> getOvertimeDetail(String id) async {
    if (shouldThrow) throw const ApiException(message: 'Error fetching detail');
    return mockDetailData ??
        OvertimeDetailData(
          id: id,
          status: 'REQUESTED',
          notes: 'Lembur deployment',
          employee: const OvertimeEmployeeModel(id: 'emp-1', firstName: 'Budi'),
        );
  }

  @override
  Future<void> approveOvertime({
    required String id,
    required bool isApproved,
    String? approverNotes,
  }) async {
    lastApprovedId = id;
    lastIsApproved = isApproved;
    lastApproverNotes = approverNotes;
    if (shouldThrow) throw const ApiException(message: 'Error approving overtime');
  }

  @override
  Future<void> deleteOvertime(String id) async {
    lastDeletedId = id;
    if (shouldThrow) throw const ApiException(message: 'Error deleting overtime');
  }
}

void main() {
  group('OvertimeRepositoryImpl Tests', () {
    late _MockOvertimeRemoteDataSource mockRemoteDataSource;
    late OvertimeRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockOvertimeRemoteDataSource();
      repository = OvertimeRepositoryImpl(remoteDataSource: mockRemoteDataSource);
    });

    test('getOvertimeRequests delegates to remoteDataSource', () async {
      mockRemoteDataSource.mockListResponse = const OvertimeRequestListResponse(
        success: true,
        message: 'OK',
        data: [
          OvertimeRequestItem(
            id: 'ot-1',
            name: 'Budi',
            initials: 'BS',
            status: OvertimeStatus.pending,
            timezone: 'WIB',
            notes: 'Pekerjaan akhir kuartal',
          ),
        ],
        meta: OvertimePaginationMeta(page: 1, limit: 30, total: 1, totalPages: 1),
      );

      final result = await repository.getOvertimeRequests(page: 1, size: 30);

      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('ot-1'));
    });

    test('getOvertimeSchedule returns schedule data', () async {
      final schedule = await repository.getOvertimeSchedule(dateTimeStart: '2026-10-15T17:00:00Z');

      expect(schedule.workScheduleId, equals('ws-1'));
      expect(schedule.isDayOff, isFalse);
    });

    test('getOvertimeDetail returns detail data', () async {
      final detail = await repository.getOvertimeDetail('ot-100');

      expect(detail.id, equals('ot-100'));
      expect(detail.notes, equals('Lembur deployment'));
      expect(detail.employee.firstName, equals('Budi'));
    });

    test('approveOvertime passes id, decision, and notes', () async {
      await repository.approveOvertime(
        id: 'ot-100',
        isApproved: true,
        approverNotes: 'Disetujui lembur',
      );

      expect(mockRemoteDataSource.lastApprovedId, equals('ot-100'));
      expect(mockRemoteDataSource.lastIsApproved, isTrue);
      expect(mockRemoteDataSource.lastApproverNotes, equals('Disetujui lembur'));
    });

    test('deleteOvertime passes id to remoteDataSource', () async {
      await repository.deleteOvertime('ot-100');

      expect(mockRemoteDataSource.lastDeletedId, equals('ot-100'));
    });

    test('createOvertimeRequest passes parameters to remoteDataSource', () async {
      final result = await repository.createOvertimeRequest(
        startOvertime: '2026-10-15T18:00:00Z',
        endOvertime: '2026-10-15T21:00:00Z',
        notes: 'Fixing bugs',
        file: XFile('test/sample.jpg'),
      );

      expect(result.id, equals('ot-created-1'));
      expect(result.success, isTrue);
    });
  });
}
