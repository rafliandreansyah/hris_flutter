import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/datasources/leave_remote_datasource.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:hris_flutter/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';
import 'package:image_picker/image_picker.dart';

class _MockLeaveRemoteDataSource implements LeaveRemoteDataSource {
  LeaveRequestListResponse? mockListResponse;
  LeaveRequestDetailData? mockDetailData;
  List<LeaveTypeOptionModel>? mockTypes;
  CreateLeaveResultModel? mockCreateResult;

  String? lastApprovedId;
  bool? lastIsApproved;
  String? lastApproverNotes;
  String? lastDeletedId;
  bool shouldThrow = false;

  Map<String, Object?> lastListArgs = {};
  Map<String, Object?> lastCreateArgs = {};

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    lastListArgs = {
      'page': page,
      'size': size,
      'companyId': companyId,
      'departmentId': departmentId,
      'positionId': positionId,
      'search': search,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'approver': approver,
    };
    if (shouldThrow) throw const ApiException(message: 'Error fetching requests');
    return mockListResponse ??
        const LeaveRequestListResponse(
          success: true,
          message: 'OK',
          data: [],
          meta: LeavePaginationMeta(page: 1, limit: 30, total: 0, totalPages: 1),
        );
  }

  @override
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id) async {
    if (shouldThrow) throw const ApiException(message: 'Error fetching detail');
    return mockDetailData ??
        LeaveRequestDetailData(
          id: id,
          startDate: DateTime(2026, 10, 15),
          endDate: DateTime(2026, 10, 16),
          totalDays: 2,
          notes: 'Cuti istirahat',
          status: 'REQUESTED',
          leaveType: const LeaveTypeDetailModel(
            id: 'type-1',
            name: 'Tahunan',
          ),
          employee: const LeaveEmployeeDetailModel(
            id: 'emp-1',
            firstName: 'Budi',
          ),
        );
  }

  @override
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  }) async {
    lastApprovedId = id;
    lastIsApproved = isApproved;
    lastApproverNotes = approverNotes;
    if (shouldThrow) throw const ApiException(message: 'Error approving request');
  }

  @override
  Future<void> deleteLeaveRequest(String id) async {
    lastDeletedId = id;
    if (shouldThrow) throw const ApiException(message: 'Error deleting request');
  }

  @override
  Future<List<LeaveTypeOptionModel>> getLeaveTypes() async {
    if (shouldThrow) throw const ApiException(message: 'Error fetching types');
    return mockTypes ??
        const [
          LeaveTypeOptionModel(id: 't-1', code: 'CT', name: 'Cuti Tahunan'),
        ];
  }

  @override
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  }) async {
    lastCreateArgs = {
      'leaveTypeId': leaveTypeId,
      'startDate': startDate,
      'totalDays': totalDays,
      'notes': notes,
      'file': file,
    };
    if (shouldThrow) throw const ApiException(message: 'Error creating request');
    return mockCreateResult ??
        const CreateLeaveResultModel(
          success: true,
          id: 'created-1',
          message: 'Sukses dibuat',
        );
  }
}

void main() {
  group('LeaveRepositoryImpl Tests', () {
    late _MockLeaveRemoteDataSource mockRemoteDataSource;
    late LeaveRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockLeaveRemoteDataSource();
      repository = LeaveRepositoryImpl(remoteDataSource: mockRemoteDataSource);
    });

    test('getLeaveRequests delegates to remoteDataSource', () async {
      mockRemoteDataSource.mockListResponse = const LeaveRequestListResponse(
        success: true,
        message: 'OK',
        data: [
          LeaveRequestItem(
            id: 'l-1',
            name: 'Budi',
            initials: 'BS',
            leaveType: 'Annual Leave',
            status: LeaveStatus.pending,
            timezone: 'WIB',
            notes: 'Liburan',
          ),
        ],
        meta: LeavePaginationMeta(page: 1, limit: 30, total: 1, totalPages: 1),
      );

      final result = await repository.getLeaveRequests(page: 1, size: 30);

      expect(result.data.length, equals(1));
      expect(result.data.first.id, equals('l-1'));
    });

    test('getLeaveRequests meneruskan seluruh filter & approver ke datasource', () async {
      await repository.getLeaveRequests(
        page: 3,
        size: 15,
        companyId: 'c-1',
        departmentId: 'd-1',
        positionId: 'p-1',
        search: 'budi',
        status: 'REQUESTED',
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        approver: true,
      );

      expect(mockRemoteDataSource.lastListArgs, {
        'page': 3,
        'size': 15,
        'companyId': 'c-1',
        'departmentId': 'd-1',
        'positionId': 'p-1',
        'search': 'budi',
        'status': 'REQUESTED',
        'startDate': '2026-10-01',
        'endDate': '2026-10-31',
        'approver': true,
      });
    });

    test('getLeaveRequests memakai size default 30 dan approver default false', () async {
      await repository.getLeaveRequests(page: 1);

      expect(mockRemoteDataSource.lastListArgs['size'], 30);
      expect(mockRemoteDataSource.lastListArgs['approver'], false);
    });

    test('getLeaveRequests memetakan statusApprove ke status bila status kosong', () async {
      await repository.getLeaveRequests(page: 1, statusApprove: 'APPROVED');
      expect(mockRemoteDataSource.lastListArgs['status'], 'APPROVED');

      await repository.getLeaveRequests(
        page: 1,
        status: 'REJECTED',
        statusApprove: 'APPROVED',
      );
      expect(mockRemoteDataSource.lastListArgs['status'], 'REJECTED');
    });

    test('getLeaveRequests meneruskan ApiException dari datasource', () async {
      mockRemoteDataSource.shouldThrow = true;

      await expectLater(
        repository.getLeaveRequests(page: 1),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Error fetching requests',
          ),
        ),
      );
    });

    test('getLeaveRequestDetail returns detail data', () async {
      final detail = await repository.getLeaveRequestDetail('l-100');

      expect(detail.id, equals('l-100'));
      expect(detail.notes, equals('Cuti istirahat'));
    });

    test('approveLeaveRequest passes approval decision and notes', () async {
      await repository.approveLeaveRequest(
        'l-100',
        isApproved: true,
        approverNotes: 'Setuju, selamat berlibur',
      );

      expect(mockRemoteDataSource.lastApprovedId, equals('l-100'));
      expect(mockRemoteDataSource.lastIsApproved, isTrue);
      expect(mockRemoteDataSource.lastApproverNotes, equals('Setuju, selamat berlibur'));
    });

    test('deleteLeaveRequest passes request id to delete', () async {
      await repository.deleteLeaveRequest('l-100');

      expect(mockRemoteDataSource.lastDeletedId, equals('l-100'));
    });

    test('getLeaveTypes returns list of types', () async {
      final types = await repository.getLeaveTypes();

      expect(types.length, equals(1));
      expect(types.first.name, equals('Cuti Tahunan'));
    });

    test('createLeaveRequest passes all required parameters to remoteDataSource', () async {
      final result = await repository.createLeaveRequest(
        leaveTypeId: 't-1',
        startDate: '2026-10-25',
        totalDays: 3,
        notes: 'Keperluan mendesak',
      );

      expect(result.id, equals('created-1'));
      expect(result.message, equals('Sukses dibuat'));
      expect(mockRemoteDataSource.lastCreateArgs, {
        'leaveTypeId': 't-1',
        'startDate': '2026-10-25',
        'totalDays': 3,
        'notes': 'Keperluan mendesak',
        'file': null,
      });
    });
  });
}
