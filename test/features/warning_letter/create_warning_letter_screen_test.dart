import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:hris_flutter/features/warning_letter/presentation/pages/create_warning_letter_screen.dart';

class _FakeWLRepo implements WarningLetterRepository {
  LastWarningLetterModel? lastLetter;
  bool createCalled = false;

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
    return const [
      WarningLetterTypeModel(
        id: 't-1',
        name: 'SP 1 - Teguran Pertama',
        level: 1,
        validityPeriodMonths: 6,
      ),
      WarningLetterTypeModel(
        id: 't-2',
        name: 'SP 2 - Teguran Kedua',
        level: 2,
        validityPeriodMonths: 6,
      ),
    ];
  }

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) async {
    return lastLetter;
  }

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    createCalled = true;
    return const CreateWarningLetterResponse(
      success: true,
      message: 'Surat peringatan berhasil diterbitkan',
      data: CreateWarningLetterResponseData(
        id: 'new-sp-1',
        referenceNumber: 'SP/MUR/2026/09/009',
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

class _FakeEmpRepo implements EmployeeRepository {
  final List<EmployeeDirectoryItem> employees = [
    const EmployeeDirectoryItem(
      id: 'emp-1',
      name: 'Budi Santoso',
      role: 'Site Supervisor',
      department: 'Operations',
      company: 'PT Muratech',
      employeeNumber: 'EMP-8492',
      email: 'budi@muratech.com',
      initials: 'BS',
    ),
    const EmployeeDirectoryItem(
      id: 'emp-2',
      name: 'Dimas Anggara',
      role: 'Staff IT',
      department: 'Technology',
      company: 'PT Muratech',
      employeeNumber: 'EMP-9103',
      email: 'dimas@muratech.com',
      initials: 'DA',
    ),
  ];

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
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

  late _FakeWLRepo wlRepo;
  late _FakeEmpRepo empRepo;

  setUp(() {
    wlRepo = _FakeWLRepo();
    empRepo = _FakeEmpRepo();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: CreateWarningLetterScreen(
        warningLetterRepository: wlRepo,
        employeeRepository: empRepo,
      ),
    );
  }

  group('CreateWarningLetterScreen Widget Tests', () {
    testWidgets('renders screen title, sections, and empty employee picker', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Buat Surat Peringatan'), findsOneWidget);
      expect(find.text('Pilih Pegawai'), findsOneWidget);
      expect(find.text('Ketuk untuk memilih pegawai yang akan diberikan SP'), findsOneWidget);
      expect(find.text('TIPE SURAT & TANGGAL PENERBITAN'), findsOneWidget);
      expect(find.text('DETAIL PELANGGARAN & BUKTI'), findsOneWidget);
      expect(find.text('Terbitkan Surat Peringatan'), findsOneWidget);
    });

    testWidgets('selecting employee opens sheet and loads last warning letter banner', (tester) async {
      wlRepo.lastLetter = LastWarningLetterModel(
        id: 'last-sp-1',
        referenceNumber: 'SP/MUR/2026/02/012',
        warningLetterType: const WarningLetterTypeModel(
          id: 't-1',
          level: 1,
          name: 'Surat Peringatan I (SP 1)',
          validityPeriodMonths: 6,
        ),
        isActive: true,
        timezone: 'WIB',
        issuedDate: DateTime(2026, 2, 10),
        expiredDate: DateTime(2026, 8, 10),
        infractionReason: 'Terlambat berulang',
      );

      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on employee picker card
      final pickerCard =
          find.text('Ketuk untuk memilih pegawai yang akan diberikan SP');
      expect(pickerCard, findsOneWidget);
      await tester.tap(pickerCard);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with employees
      expect(find.text('Pilih Pegawai Penerima SP'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Dimas Anggara'), findsOneWidget);

      // Select Budi Santoso
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();

      // Verify employee card is displayed
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Site Supervisor • Operations'), findsOneWidget);

      // Verify previous warning letter banner appears
      expect(find.text('Surat Peringatan Terakhir'), findsOneWidget);
      expect(find.text('Ref: SP/MUR/2026/02/012'), findsOneWidget);
    });

    testWidgets('displays neutral card when employee has no previous warning letter', (tester) async {
      wlRepo.lastLetter = null; // No prior SP

      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on employee picker card
      await tester.tap(
        find.text('Ketuk untuk memilih pegawai yang akan diberikan SP'),
      );
      await tester.pumpAndSettle();

      // Select Dimas Anggara
      await tester.tap(find.text('Dimas Anggara'));
      await tester.pumpAndSettle();

      // Verify neutral card is displayed
      expect(find.text('Belum Ada Riwayat Surat Peringatan'), findsOneWidget);
      expect(
        find.text('Pegawai ini belum pernah menerima surat peringatan sebelumnya.'),
        findsOneWidget,
      );
    });

    testWidgets('can enter reason, sanction, and submit form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select employee
      await tester.tap(
        find.text('Ketuk untuk memilih pegawai yang akan diberikan SP'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();

      // Enter Reason
      final reasonFields = find.byType(TextFormField);
      expect(reasonFields, findsAtLeastNWidgets(2));
      await tester.enterText(reasonFields.first, 'Pelanggaran disiplin berat');
      await tester.enterText(reasonFields.last, 'Skorsing kerja 3 hari');
      await tester.pumpAndSettle();

      // Tap submit button
      final submitButton = find.text('Terbitkan Surat Peringatan');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify repository createWarningLetter was called
      expect(wlRepo.createCalled, isTrue);

      // Verify success dialog appears
      expect(find.text('Surat Peringatan Diterbitkan'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });
  });
}
