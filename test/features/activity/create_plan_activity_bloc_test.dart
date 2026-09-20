import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_plan_activity/create_plan_activity_bloc.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:image_picker/image_picker.dart';

class _MockPlanActivityRepository implements ActivityRepository {
  bool getTypesShouldFail;
  bool createPlanShouldFail;
  String? lastEmployeeId;
  String? lastActivityTypeId;
  double? lastLatitude;
  double? lastLongitude;

  _MockPlanActivityRepository({
    this.getTypesShouldFail = false,
    this.createPlanShouldFail = false,
  });

  @override
  Future<ActivityListResponse> getActivities({
    required int page,
    required int size,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? status,
    String? startDate,
    String? endDate,
    bool approver = false,
  }) async {
    return const ActivityListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: ActivityPaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1),
    );
  }

  @override
  Future<ActivityDetailResponse> getActivityDetail(String id) async {
    return ActivityDetailResponse(
      success: true,
      message: 'OK',
      data: {'id': id},
    );
  }

  @override
  Future<ActivityActionResponse> finishActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'OK');
  }

  @override
  Future<ActivityActionResponse> cancelActivity({
    required String id,
    required String notes,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'OK');
  }

  @override
  Future<ActivityTypesResponse> getActivityTypes() async {
    if (getTypesShouldFail) {
      throw const ApiException(message: 'Gagal memuat tipe aktivitas');
    }
    return const ActivityTypesResponse(
      success: true,
      message: 'OK',
      data: [
        ActivityTypeModel(id: 'type-01', name: 'Meeting Client'),
        ActivityTypeModel(id: 'type-02', name: 'Site Visit'),
      ],
    );
  }

  @override
  Future<CreateActivityResponse> createActivity({
    required String activityTypeId,
    required double latitude,
    required double longitude,
    required String locationName,
    required String locationAddress,
    required String description,
    String status = 'ongoing',
    XFile? file,
  }) async {
    return const CreateActivityResponse(success: true, message: 'OK', data: {});
  }

  @override
  Future<CreateActivityResponse> createPlanActivity({
    required String employeeId,
    required String activityTypeId,
    required String startTime,
    required String locationName,
    required String locationAddress,
    required String description,
    double latitude = 0,
    double longitude = 0,
    XFile? file,
  }) async {
    if (createPlanShouldFail) {
      throw const ApiException(message: 'Gagal membuat rencana aktivitas');
    }
    lastEmployeeId = employeeId;
    lastActivityTypeId = activityTypeId;
    lastLatitude = latitude;
    lastLongitude = longitude;

    return const CreateActivityResponse(
      success: true,
      message: 'Rencana aktivitas berhasil dibuat!',
      data: {
        'id': 'plan-act-101',
        'status': 'plan',
        'employeeId': 'emp-01',
      },
    );
  }

  @override
  Future<ActivityActionResponse> startActivity({
    required String id,
    required double latitude,
    required double longitude,
    required String locationAddress,
    XFile? file,
  }) async {
    return const ActivityActionResponse(success: true, message: 'OK');
  }
}

class _MockPlanEmployeeRepository implements EmployeeRepository {
  bool getEmployeesShouldFail;

  _MockPlanEmployeeRepository({this.getEmployeesShouldFail = false});

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    if (getEmployeesShouldFail) {
      throw const ApiException(message: 'Gagal memuat daftar pegawai');
    }
    return const EmployeeListResponse(
      success: true,
      message: 'OK',
      data: [
        EmployeeDirectoryItem(
          id: 'emp-01',
          name: 'Budi Santoso',
          email: 'budi@example.com',
          role: 'Mobile Developer',
          department: 'Engineering',
          initials: 'BS',
        ),
        EmployeeDirectoryItem(
          id: 'emp-02',
          name: 'Siti Aminah',
          email: 'siti@example.com',
          role: 'UI/UX Designer',
          department: 'Design',
          initials: 'SA',
        ),
      ],
      meta: EmployeePaginationMeta(page: 1, limit: 30, total: 2, totalPages: 1),
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) {
    throw UnimplementedError();
  }

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    return [];
  }

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return 'Password berhasil diperbarui';
  }
}

void main() {
  group('CreatePlanActivityBloc Unit Tests', () {
    test('initial state is correctly set', () {
      final activityRepo = _MockPlanActivityRepository();
      final employeeRepo = _MockPlanEmployeeRepository();
      final bloc = CreatePlanActivityBloc(
        activityRepository: activityRepo,
        employeeRepository: employeeRepo,
      );

      expect(bloc.state.status, CreatePlanActivityStatus.initial);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.activityTypes, isEmpty);
      expect(bloc.state.employees, isEmpty);
      expect(bloc.state.errorMessage, isEmpty);

      bloc.close();
    });

    test('CreatePlanActivityStarted loads types and employees successfully', () async {
      final activityRepo = _MockPlanActivityRepository();
      final employeeRepo = _MockPlanEmployeeRepository();
      final bloc = CreatePlanActivityBloc(
        activityRepository: activityRepo,
        employeeRepository: employeeRepo,
      );

      bloc.add(const CreatePlanActivityStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreatePlanActivityStatus.dataLoaded);
      expect(bloc.state.activityTypes.length, 2);
      expect(bloc.state.activityTypes.first.name, 'Meeting Client');
      expect(bloc.state.employees.length, 2);
      expect(bloc.state.employees.first.name, 'Budi Santoso');

      bloc.close();
    });

    test('CreatePlanActivityStarted emits failure if loading fails', () async {
      final activityRepo = _MockPlanActivityRepository(getTypesShouldFail: true);
      final employeeRepo = _MockPlanEmployeeRepository();
      final bloc = CreatePlanActivityBloc(
        activityRepository: activityRepo,
        employeeRepository: employeeRepo,
      );

      bloc.add(const CreatePlanActivityStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreatePlanActivityStatus.failure);
      expect(bloc.state.errorMessage, 'Gagal memuat tipe aktivitas');

      bloc.close();
    });

    test('CreatePlanActivityStarted emits failure if loading employees fails', () async {
      final activityRepo = _MockPlanActivityRepository();
      final employeeRepo = _MockPlanEmployeeRepository(getEmployeesShouldFail: true);
      final bloc = CreatePlanActivityBloc(
        activityRepository: activityRepo,
        employeeRepository: employeeRepo,
      );

      bloc.add(const CreatePlanActivityStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreatePlanActivityStatus.failure);
      expect(bloc.state.errorMessage, 'Gagal memuat daftar pegawai');

      bloc.close();
    });

    test('CreatePlanActivitySubmitted sends correct payload with lat/lon 0 and emits success', () async {
      final activityRepo = _MockPlanActivityRepository();
      final employeeRepo = _MockPlanEmployeeRepository();
      final bloc = CreatePlanActivityBloc(
        activityRepository: activityRepo,
        employeeRepository: employeeRepo,
      );

      bloc.add(const CreatePlanActivitySubmitted(
        employeeId: 'emp-01',
        activityTypeId: 'type-01',
        startTime: '2026-09-14T09:00:00.000Z',
        locationName: 'Kantor Klien A',
        locationAddress: 'Jl. Sudirman No. 10, Jakarta Pusat',
        description: 'Meeting pembahasan milestone 2 dengan klien A.',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreatePlanActivityStatus.success);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.createdActivity, isNotNull);
      expect(bloc.state.createdActivity?.id, 'plan-act-101');
      expect(bloc.state.createdActivity?.status, ActivityStatus.planned);
      expect(activityRepo.lastEmployeeId, 'emp-01');
      expect(activityRepo.lastActivityTypeId, 'type-01');
      expect(activityRepo.lastLatitude, 0);
      expect(activityRepo.lastLongitude, 0);

      bloc.close();
    });

    test('CreatePlanActivitySubmitted emits failure on API error', () async {
      final activityRepo = _MockPlanActivityRepository(createPlanShouldFail: true);
      final employeeRepo = _MockPlanEmployeeRepository();
      final bloc = CreatePlanActivityBloc(
        activityRepository: activityRepo,
        employeeRepository: employeeRepo,
      );

      bloc.add(const CreatePlanActivitySubmitted(
        employeeId: 'emp-01',
        activityTypeId: 'type-01',
        startTime: '2026-09-14T09:00:00.000Z',
        locationName: 'Kantor Klien B',
        locationAddress: 'Jl. Gatot Subroto No. 5',
        description: 'Deskripsi rencana',
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, CreatePlanActivityStatus.failure);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.errorMessage, 'Gagal membuat rencana aktivitas');

      bloc.close();
    });
  });
}
