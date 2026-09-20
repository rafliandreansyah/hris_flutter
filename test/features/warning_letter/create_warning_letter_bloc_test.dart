import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/create_warning_letter/create_warning_letter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class _FakeWarningLetterRepository implements WarningLetterRepository {
  List<WarningLetterTypeModel> types = const [
    WarningLetterTypeModel(
      id: 'type-1',
      name: 'SP 1',
      level: 1,
      validityPeriodMonths: 6,
    ),
    WarningLetterTypeModel(
      id: 'type-2',
      name: 'SP 2',
      level: 2,
      validityPeriodMonths: 6,
    ),
  ];

  LastWarningLetterModel? lastLetterToReturn;
  bool shouldThrowOnTypes = false;
  bool shouldThrowOnLastLetter = false;
  bool shouldThrowOnCreate = false;
  String createErrorMessage = 'Gagal membuat SP';
  CreateWarningLetterRequest? lastCreatedRequest;

  @override
  Future<WarningLetterListResponse> getWarningLetters({
    required int page,
    required int size,
    String? letterTypeId,
    String? status,
    String? search,
    required bool approver,
    String? startDate,
    String? endDate,
  }) async {
    return const WarningLetterListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: WarningLetterPaginationMeta(
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() async {
    if (shouldThrowOnTypes) {
      throw const ApiException(message: 'Error fetching types', statusCode: 500);
    }
    return types;
  }

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) async {
    if (shouldThrowOnLastLetter) {
      throw const ApiException(message: 'Error fetching last letter', statusCode: 500);
    }
    return lastLetterToReturn;
  }

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    lastCreatedRequest = request;
    if (shouldThrowOnCreate) {
      throw ApiException(message: createErrorMessage, statusCode: 400);
    }
    return const CreateWarningLetterResponse(
      success: true,
      message: 'Surat peringatan berhasil dibuat',
      data: CreateWarningLetterResponseData(
        id: 'wl-created-1',
        referenceNumber: 'SP/2026/09/001',
      ),
    );
  }

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) async {
    return const WarningLetterDetail(
      id: 'wl-1',
      warningLetterType: WarningLetterTypeSummary(level: 1, name: 'SP 1'),
      timezone: 'WIB',
      isActive: true,
      createdAt: null,
      issuedDate: null,
      expiredDate: null,
    );
  }
}

class _FakeEmployeeRepository implements EmployeeRepository {
  List<EmployeeDirectoryItem> employees = [
    const EmployeeDirectoryItem(
      id: 'emp-101',
      name: 'Budi Santoso',
      role: 'Site Supervisor',
      department: 'Operations',
      company: 'PT Muratech',
      employeeNumber: 'EMP-8492',
      email: 'budi@muratech.com',
      initials: 'BS',
    ),
    const EmployeeDirectoryItem(
      id: 'emp-102',
      name: 'Dimas Anggara',
      role: 'Staff IT',
      department: 'Technology',
      company: 'PT Muratech',
      employeeNumber: 'EMP-9103',
      email: 'dimas@muratech.com',
      initials: 'DA',
    ),
  ];

  bool shouldThrowOnEmployees = false;

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    if (shouldThrowOnEmployees) {
      throw const ApiException(message: 'Error fetching employees', statusCode: 500);
    }
    return EmployeeListResponse(
      success: true,
      message: 'OK',
      data: employees,
      meta: EmployeePaginationMeta(
        page: page,
        limit: size,
        total: employees.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) {
    throw UnimplementedError();
  }

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    return employees;
  }

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWarningLetterRepository wlRepo;
  late _FakeEmployeeRepository empRepo;

  setUp(() {
    wlRepo = _FakeWarningLetterRepository();
    empRepo = _FakeEmployeeRepository();
  });

  group('CreateWarningLetterBloc Tests', () {
    test('initial state has proper defaults', () {
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      expect(bloc.state.status, CreateWarningLetterStatus.initial);
      expect(bloc.state.warningLetterTypes, isEmpty);
      expect(bloc.state.employees, isEmpty);
      expect(bloc.state.selectedEmployee, isNull);
      expect(bloc.state.selectedType, isNull);
      expect(bloc.state.canSubmit, isFalse);
    });

    test('CreateWarningLetterStarted loads types and employees successfully', () async {
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      expect(bloc.state.status, CreateWarningLetterStatus.dataLoaded);
      expect(bloc.state.warningLetterTypes.length, 2);
      expect(bloc.state.employees.length, 2);
      expect(bloc.state.selectedType?.id, 'type-1'); // Defaults to first type
    });

    test('CreateWarningLetterStarted handles API failure gracefully', () async {
      wlRepo.shouldThrowOnTypes = true;
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      expect(bloc.state.status, CreateWarningLetterStatus.failure);
      expect(bloc.state.errorMessage, contains('Error fetching types'));
    });

    test('CreateWarningLetterEmployeeSelected loads previous warning letter', () async {
      final lastLetter = LastWarningLetterModel(
        id: 'wl-prev-1',
        referenceNumber: 'SP/MUR/2026/01/001',
        warningLetterType: const WarningLetterTypeModel(
          id: 'type-1',
          level: 1,
          name: 'SP 1',
          validityPeriodMonths: 6,
        ),
        isActive: true,
        timezone: 'WIB',
        issuedDate: DateTime(2026, 1, 15),
        expiredDate: DateTime(2026, 7, 15),
        infractionReason: 'Sering terlambat',
      );
      wlRepo.lastLetterToReturn = lastLetter;

      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      final targetEmp = empRepo.employees.first;
      bloc.add(CreateWarningLetterEmployeeSelected(targetEmp));
      await pumpEventQueue();

      expect(bloc.state.selectedEmployee, targetEmp);
      expect(bloc.state.lastWarningLetter, lastLetter);
      expect(bloc.state.hasLoadedLastLetter, isTrue);
      expect(bloc.state.isLoadingLastLetter, isFalse);
    });

    test('CreateWarningLetterEmployeeSelected handles null last warning letter (no prior SP)', () async {
      wlRepo.lastLetterToReturn = null;

      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      final targetEmp = empRepo.employees.first;
      bloc.add(CreateWarningLetterEmployeeSelected(targetEmp));
      await pumpEventQueue();

      expect(bloc.state.selectedEmployee, targetEmp);
      expect(bloc.state.lastWarningLetter, isNull);
      expect(bloc.state.hasLoadedLastLetter, isTrue);
      expect(bloc.state.isLoadingLastLetter, isFalse);
    });

    test('CreateWarningLetterTypeSelected updates selectedType and expiration date', () async {
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      final sp2 = wlRepo.types[1];
      bloc.add(CreateWarningLetterTypeSelected(sp2));
      await pumpEventQueue();

      expect(bloc.state.selectedType, sp2);
      expect(bloc.state.calculatedExpiredDate, isNotNull);
    });

    test('CreateWarningLetterIssuedDateChanged recalculates expiration date', () async {
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      final customDate = DateTime(2026, 1, 10);
      bloc.add(CreateWarningLetterIssuedDateChanged(customDate));
      await pumpEventQueue();

      expect(bloc.state.issuedDate, customDate);
      // SP 1 has 6 months validity -> 2026-07-10
      expect(bloc.state.calculatedExpiredDate, DateTime(2026, 7, 10));
    });

    test('Form validation and field changes update canSubmit', () async {
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      expect(bloc.state.canSubmit, isFalse);

      bloc.add(CreateWarningLetterEmployeeSelected(empRepo.employees.first));
      await pumpEventQueue();
      expect(bloc.state.canSubmit, isFalse); // Reason still empty

      bloc.add(const CreateWarningLetterReasonChanged('Pelanggaran kedisiplinan'));
      await pumpEventQueue();
      expect(bloc.state.canSubmit, isTrue);

      bloc.add(const CreateWarningLetterSanctionChanged('Surat teguran resmi'));
      await pumpEventQueue();
      expect(bloc.state.canSubmit, isTrue);
    });

    test('CreateWarningLetterSubmitted fails when validation fails', () async {
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      // Submit without employee and reason
      bloc.add(const CreateWarningLetterSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, CreateWarningLetterStatus.failure);
      expect(bloc.state.errorMessage, contains('Silakan pilih pegawai'));
    });

    test('CreateWarningLetterSubmitted submits successfully to repository', () async {
      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      bloc.add(CreateWarningLetterEmployeeSelected(empRepo.employees.first));
      bloc.add(const CreateWarningLetterReasonChanged('Terlambat 5x berturut-turut'));
      bloc.add(const CreateWarningLetterSanctionChanged('Teguran tertulis'));
      final mockFile = XFile('test/dummy.png');
      bloc.add(CreateWarningLetterFileChanged(file: mockFile));
      await pumpEventQueue();

      bloc.add(const CreateWarningLetterSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, CreateWarningLetterStatus.success);
      expect(bloc.state.createdResponse?.data?.referenceNumber, 'SP/2026/09/001');
      expect(wlRepo.lastCreatedRequest?.employeeId, 'emp-101');
      expect(wlRepo.lastCreatedRequest?.reason, 'Terlambat 5x berturut-turut');
      expect(wlRepo.lastCreatedRequest?.file?.path, 'test/dummy.png');
    });

    test('CreateWarningLetterSubmitted handles backend error properly', () async {
      wlRepo.shouldThrowOnCreate = true;
      wlRepo.createErrorMessage = 'Pegawai sudah memiliki SP aktif dengan tingkat yang sama';

      final bloc = CreateWarningLetterBloc(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      );

      bloc.add(const CreateWarningLetterStarted());
      await pumpEventQueue();

      bloc.add(CreateWarningLetterEmployeeSelected(empRepo.employees.first));
      bloc.add(const CreateWarningLetterReasonChanged('Alasan'));
      await pumpEventQueue();

      bloc.add(const CreateWarningLetterSubmitted());
      await pumpEventQueue();

      expect(bloc.state.status, CreateWarningLetterStatus.failure);
      expect(
        bloc.state.errorMessage,
        'Pegawai sudah memiliki SP aktif dengan tingkat yang sama',
      );
    });
  });
}
