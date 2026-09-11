import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/create_leave/create_leave_bloc.dart';
import 'package:image_picker/image_picker.dart';

class _MockLeaveRepository implements LeaveRepository {
  List<LeaveTypeOptionModel> mockLeaveTypes = [];
  CreateLeaveResultModel? mockCreateResult;
  ApiException? errorToThrow;

  String? lastSubmittedTypeId;
  String? lastSubmittedStartDate;
  int? lastSubmittedTotalDays;
  String? lastSubmittedNotes;
  XFile? lastSubmittedFile;

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? statusApprove,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LeaveRequestDetailData> getLeaveRequestDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> approveLeaveRequest(
    String id, {
    required bool isApproved,
    String? approverNotes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteLeaveRequest(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<LeaveTypeOptionModel>> getLeaveTypes() async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockLeaveTypes;
  }

  @override
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastSubmittedTypeId = leaveTypeId;
    lastSubmittedStartDate = startDate;
    lastSubmittedTotalDays = totalDays;
    lastSubmittedNotes = notes;
    lastSubmittedFile = file;

    return mockCreateResult ??
        const CreateLeaveResultModel(
          success: true,
          message: 'Leave request created successfully',
          id: 'new-leave-id-123',
        );
  }
}

void main() {
  late _MockLeaveRepository repository;
  late CreateLeaveBloc bloc;

  final sampleLeaveTypes = [
    const LeaveTypeOptionModel(
      id: 'type-1',
      code: 'SICK',
      name: 'Cuti Sakit',
      requiresFile: true,
      fixedDays: null,
      maxDays: 5,
    ),
    const LeaveTypeOptionModel(
      id: 'type-2',
      code: 'ANNUAL',
      name: 'Cuti Tahunan',
      requiresFile: false,
      isDeducted: true,
      maxDays: 12,
    ),
    const LeaveTypeOptionModel(
      id: 'type-3',
      code: 'MARRIAGE',
      name: 'Izin Menikah',
      fixedDays: 3,
      requiresFile: false,
    ),
  ];

  setUp(() {
    repository = _MockLeaveRepository();
    bloc = CreateLeaveBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state has correct default values', () {
    expect(bloc.state.status, CreateLeaveStatus.initial);
    expect(bloc.state.leaveTypes, isEmpty);
    expect(bloc.state.selectedType, isNull);
    expect(bloc.state.createdId, isNull);
    expect(bloc.state.errorMessage, isEmpty);
  });

  group('CreateLeaveStarted', () {
    test('emits loadingTypes then typesLoaded on success', () async {
      repository.mockLeaveTypes = sampleLeaveTypes;
      final states = <CreateLeaveState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateLeaveStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, CreateLeaveStatus.loadingTypes);
      expect(states[1].status, CreateLeaveStatus.typesLoaded);
      expect(states[1].leaveTypes, sampleLeaveTypes);
      expect(states[1].errorMessage, isEmpty);
    });

    test('emits loadingTypes then typesLoaded with error on ApiException',
        () async {
      repository.errorToThrow = ApiException(
        message: 'Gagal mengambil jenis cuti dari server.',
        statusCode: 500,
      );
      final states = <CreateLeaveState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateLeaveStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, CreateLeaveStatus.loadingTypes);
      expect(states[1].status, CreateLeaveStatus.typesLoaded);
      expect(states[1].leaveTypes, isEmpty);
      expect(
        states[1].errorMessage,
        'Gagal mengambil jenis cuti dari server.',
      );
      expect(states[1].statusCode, 500);
    });
  });

  group('CreateLeaveTypeChanged', () {
    test('updates selectedType in state', () async {
      final states = <CreateLeaveState>[];
      bloc.stream.listen(states.add);

      final chosen = sampleLeaveTypes[0];
      bloc.add(CreateLeaveTypeChanged(chosen));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 1);
      expect(states[0].selectedType, chosen);
    });

    test('clears selectedType when passed null', () async {
      final states = <CreateLeaveState>[];
      bloc.stream.listen(states.add);

      bloc.add(CreateLeaveTypeChanged(sampleLeaveTypes[0]));
      await Future.delayed(const Duration(milliseconds: 20));
      bloc.add(const CreateLeaveTypeChanged(null));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[1].selectedType, isNull);
    });
  });

  group('CreateLeaveSubmitted', () {
    test('emits submitting then success with createdId on success', () async {
      repository.mockCreateResult = const CreateLeaveResultModel(
        success: true,
        message: 'Pengajuan cuti berhasil dibuat!',
        id: 'leave-uuid-999',
      );

      final states = <CreateLeaveState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateLeaveSubmitted(
        leaveTypeId: 'type-1',
        startDate: '2026-09-11',
        totalDays: 2,
        notes: 'Sakit flu dan demam',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, CreateLeaveStatus.submitting);
      expect(states[1].status, CreateLeaveStatus.success);
      expect(states[1].createdId, 'leave-uuid-999');
      expect(states[1].successMessage, 'Pengajuan cuti berhasil dibuat!');

      expect(repository.lastSubmittedTypeId, 'type-1');
      expect(repository.lastSubmittedStartDate, '2026-09-11');
      expect(repository.lastSubmittedTotalDays, 2);
      expect(repository.lastSubmittedNotes, 'Sakit flu dan demam');
    });

    test('emits submitting then failure on ApiException', () async {
      repository.errorToThrow = ApiException(
        message: 'Kuota cuti tidak mencukupi.',
        statusCode: 422,
      );

      final states = <CreateLeaveState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateLeaveSubmitted(
        leaveTypeId: 'type-2',
        startDate: '2026-09-15',
        totalDays: 10,
        notes: 'Liburan keluarga',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0].status, CreateLeaveStatus.submitting);
      expect(states[1].status, CreateLeaveStatus.failure);
      expect(states[1].errorMessage, 'Kuota cuti tidak mencukupi.');
      expect(states[1].statusCode, 422);
    });
  });
}
