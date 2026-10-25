import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_employee_picker_modal.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeEmployeeRepository implements EmployeeRepository {
  List<EmployeeDirectoryItem> coworkers = [];
  Object? error;
  Object? directoryError;
  final List<String?> searches = [];
  final List<int> pages = [];
  List<List<EmployeeDirectoryItem>> directoryPages = [];

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async {
    if (error != null) throw error!;
    return coworkers;
  }

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async {
    searches.add(search);
    pages.add(page);
    if (directoryError != null) throw directoryError!;
    final index = (page - 1).clamp(0, directoryPages.length - 1);
    return EmployeeListResponse(
      success: true,
      message: 'ok',
      data: directoryPages[index],
      meta: EmployeePaginationMeta(
        page: page,
        limit: size,
        total: 100,
        totalPages: directoryPages.length,
      ),
    );
  }

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) =>
      throw UnimplementedError();

  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      throw UnimplementedError();
}

EmployeeDirectoryItem _emp(String id, String name,
        {String role = '', String department = '', String? number}) =>
    EmployeeDirectoryItem(
      id: id,
      rawId: id,
      name: name,
      role: role,
      department: department,
      email: '-',
      initials: name.substring(0, 2).toUpperCase(),
      employeeNumber: number,
    );

void main() {
  late _FakeEmployeeRepository repo;

  setUp(() {
    repo = _FakeEmployeeRepository();
    SecureStorageService.instance.setEmployeeIdInMemory('me');
  });

  Future<void> pumpPicker(
    WidgetTester tester, {
    String? exclude,
    String? selected,
    AssetPickerSource source = AssetPickerSource.coworkers,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AssetEmployeePickerModal(
          repository: repo,
          excludeEmployeeId: exclude,
          selectedEmployeeId: selected,
          source: source,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('pemegang saat ini dan diri sendiri tidak muncul sebagai penerima',
      (tester) async {
    repo.coworkers = [
      _emp('me', 'Saya Sendiri'),
      _emp('holder', 'Pemegang Lama'),
      _emp('x', 'Rekan Baru', role: 'QA', department: 'Ops', number: 'EMP-9'),
    ];

    await pumpPicker(tester, exclude: 'holder');

    expect(find.text('Rekan Baru'), findsOneWidget);
    expect(find.text('Saya Sendiri'), findsNothing);
    expect(find.text('Pemegang Lama'), findsNothing);
  });

  testWidgets('data kosong tidak dikarang: jabatan/departemen kosong tidak tampil',
      (tester) async {
    repo.coworkers = [_emp('x', 'Rekan Baru')];

    await pumpPicker(tester);

    expect(find.text('Rekan Baru'), findsOneWidget);
    expect(find.text('Staff'), findsNothing);
    expect(find.text('Umum'), findsNothing);
  });

  testWidgets('error menampilkan pesan dari API dan bisa dicoba ulang',
      (tester) async {
    repo.error = const ApiException(message: 'Akses ditolak oleh server');

    await pumpPicker(tester);

    expect(find.text('Akses ditolak oleh server'), findsOneWidget);

    repo.error = null;
    repo.coworkers = [_emp('x', 'Rekan Baru')];
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Rekan Baru'), findsOneWidget);
  });

  testWidgets('pencarian mencakup jabatan dan karyawan terpilih diberi centang',
      (tester) async {
    repo.coworkers = [
      _emp('a', 'Ani', role: 'Akuntan'),
      _emp('b', 'Budi', role: 'Teknisi'),
    ];

    await pumpPicker(tester, selected: 'a');
    // Hanya karyawan terpilih (Ani) yang bertanda centang.
    expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'teknisi');
    await tester.pumpAndSettle();

    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Ani'), findsNothing);
  });

  group('sumber direktori (admin aset)', () {
    testWidgets('pencarian dikirim ke server dengan debounce', (tester) async {
      repo.directoryPages = [
        [_emp('a', 'Ani', number: 'EMP-1')],
      ];

      await pumpPicker(tester, source: AssetPickerSource.directory);
      expect(repo.searches, [null]);
      expect(repo.pages, [1]);

      await tester.enterText(find.byType(TextField), 'ani');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repo.searches, [null, 'ani']);
      expect(repo.pages, [1, 1]);
      expect(find.text('Ani'), findsOneWidget);
    });

    testWidgets('halaman berikutnya dimuat otomatis bila layar belum penuh', (tester) async {
      repo.directoryPages = [
        List.generate(3, (i) => _emp('p1-$i', 'Pegawai Satu $i')),
        [_emp('p2-0', 'Pegawai Dua')],
      ];

      await pumpPicker(tester, source: AssetPickerSource.directory);

      // Halaman pertama belum memenuhi layar, jadi halaman berikutnya dimuat otomatis.
      expect(repo.pages, [1, 2]);
      expect(find.text('Pegawai Dua'), findsOneWidget);
    });

    testWidgets('403 pada direktori jatuh ke daftar rekan kerja', (tester) async {
      repo.directoryError =
          const ApiException(message: 'Tidak berwenang', statusCode: 403);
      repo.coworkers = [_emp('x', 'Rekan Kerja')];

      await pumpPicker(tester, source: AssetPickerSource.directory);

      expect(find.text('Rekan Kerja'), findsOneWidget);
      expect(find.text('Tidak berwenang'), findsNothing);
    });
  });
}
