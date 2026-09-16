import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_requests_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_type_selection_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _MockAttendanceRequestRepository implements AttendanceRequestRepository {
  final bool teamForbidden;
  final List<AttendanceRequestItem> myItems;
  final List<AttendanceRequestItem> teamItems;

  _MockAttendanceRequestRepository({
    this.teamForbidden = false,
    this.myItems = const [],
    this.teamItems = const [],
  });

  @override
  Future<AttendanceRequestListResponse> getAttendanceRequests({
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
    await Future.delayed(const Duration(milliseconds: 10));
    if (approver && teamForbidden) {
      throw ApiException(
        message: 'Tidak memiliki hak akses approver',
        statusCode: 403,
      );
    }
    final items = approver ? teamItems : myItems;
    return AttendanceRequestListResponse(
      success: true,
      message: 'OK',
      data: items,
      meta: AttendanceRequestPaginationMeta(
        page: 1,
        limit: 20,
        total: items.length,
        totalPages: 1,
      ),
    );
  }
}

final _testItems = [
  AttendanceRequestItem(
    id: 'req-1',
    employeeId: 'emp-1',
    name: 'Budi Santoso',
    role: 'Senior Backend Engineer',
    department: 'Engineering',
    company: 'Muratech',
    initials: 'BS',
    date: DateTime(2026, 8, 29),
    startTime: '08:30',
    endTime: '17:00',
    notes: 'Presentasi implementasi integrasi payment gateway ke klien di Menara Sudirman.',
    status: AttendanceRequestStatus.requested,
    createdAt: DateTime(2026, 8, 29, 13, 35),
    isSelf: true,
  ),
  AttendanceRequestItem(
    id: 'req-2',
    employeeId: 'emp-2',
    name: 'Dimas Anggara',
    role: 'Field Operations Supervisor',
    department: 'Operations',
    company: 'Muratech',
    initials: 'DA',
    date: DateTime(2026, 8, 28),
    startTime: '09:00',
    endTime: '18:00',
    notes: 'Site visit dan inspeksi gudang logistik cabang Cikarang.',
    status: AttendanceRequestStatus.approved,
    createdAt: DateTime(2026, 8, 27, 9, 15),
    isSelf: false,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required AttendanceRequestRepository repository,
  }) {
    return MaterialApp(
      home: AttendanceRequestsScreen(repository: repository),
    );
  }

  group('AttendanceRequestsScreen Widget Tests', () {
    testWidgets('merender AppBar judul Presensi Luar Kantor dan subtitle',
        (tester) async {
      final repo = _MockAttendanceRequestRepository(myItems: _testItems);
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Presensi Luar Kantor'), findsOneWidget);
      expect(
        find.text('Verifikasi & persetujuan presensi tim luar kantor'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
    });

    testWidgets('merender TabBar Pengajuan Saya dan Persetujuan Tim',
        (tester) async {
      final repo = _MockAttendanceRequestRepository(myItems: _testItems);
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('Persetujuan Tim'), findsOneWidget);
    });

    testWidgets(
        'di Tab Pengajuan Saya (Tab 0), search bar tidak muncul dan FAB tampil',
        (tester) async {
      final repo = _MockAttendanceRequestRepository(myItems: _testItems);
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      // Search bar tidak boleh muncul pada Tab 0 (height 0)
      final searchBoxFinder = find.byType(TextField);
      expect(searchBoxFinder, findsOneWidget);
      final searchBox = tester.widget<TextField>(searchBoxFinder);
      expect(searchBox.decoration?.hintText, contains('Cari nama pegawai'));

      // AnimatedContainer wrapper search bar tingginya 0 saat Tab 0
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final searchContainer = animatedContainers.firstWhere(
        (c) => c.constraints?.maxHeight == 0 || c.child is AnimatedOpacity,
      );
      expect(searchContainer, isNotNull);

      // FAB tampil dengan teks "Ajukan Presensi"
      expect(find.byKey(const ValueKey('add_attendance_request_fab')),
          findsOneWidget);
      expect(find.text('Ajukan Presensi'), findsOneWidget);
    });

    testWidgets(
        'klik FAB di Tab Pengajuan Saya memunculkan AttendanceTypeSelectionBottomSheet',
        (tester) async {
      final repo = _MockAttendanceRequestRepository(myItems: _testItems);
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      final fab = find.byKey(const ValueKey('add_attendance_request_fab'));
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Modal Bottom Sheet Stitch Screen 2
      expect(find.text('Pilih Metode Presensi Luar'), findsOneWidget);
      expect(find.text('Live Attendance (Real-Time)'), findsOneWidget);
      expect(find.text('Schedule Attendance (Terencana)'), findsOneWidget);
      expect(find.text('Instant Check-In / Out'), findsOneWidget);
      expect(find.text('Custom Date & Time'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Tap Batal menutup modal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih Metode Presensi Luar'), findsNothing);
    });

    testWidgets(
        'pindah ke Tab Persetujuan Tim memunculkan search bar dan menyembunyikan FAB',
        (tester) async {
      final repo = _MockAttendanceRequestRepository(
        myItems: _testItems,
        teamItems: _testItems,
      );
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      // Pindah ke tab 1 (Persetujuan Tim)
      await tester.tap(find.text('Persetujuan Tim'));
      await tester.pumpAndSettle();

      // FAB disembunyikan (SizedBox.shrink atau opacity 0)
      final fabFinder = find.byKey(const ValueKey('add_attendance_request_fab'));
      expect(fabFinder, findsNothing);

      // Tidak ada horizontal chip filter di bawah search
      expect(find.text('Semua Departemen'), findsNothing);
      expect(find.text('Engineering'), findsNothing);
    });

    testWidgets('HTTP 403 pada Persetujuan Tim merender Forbidden State',
        (tester) async {
      final repo = _MockAttendanceRequestRepository(
        teamForbidden: true,
        myItems: _testItems,
        teamItems: const [],
      );
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      // Pindah ke tab tim
      await tester.tap(find.text('Persetujuan Tim'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Ke Pengajuan Saya'), findsOneWidget);

      // Klik 'Ke Pengajuan Saya' kembali ke Tab 0
      await tester.tap(find.text('Ke Pengajuan Saya'));
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('AttendanceRequestCard merender data lengkap sesuai Stitch Screen 1',
        (tester) async {
      final item = _testItems[0];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceRequestCard(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Senior Backend Engineer'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('29 Agustus 2026'), findsOneWidget);
      expect(
        find.text('Jam Kerja: Masuk 08:30 WIB s/d Pulang 17:00 WIB'),
        findsOneWidget,
      );
      expect(
        find.text(
          '"Presentasi implementasi integrasi payment gateway ke klien di Menara Sudirman."',
        ),
        findsOneWidget,
      );
      expect(find.text('Tinjau Pengajuan'), findsOneWidget);
      expect(find.text('Diajukan: 29 Agustus 2026, 13:35 WIB'), findsOneWidget);
    });

    testWidgets('AttendanceTypeSelectionBottomSheet memilih Live Attendance',
        (tester) async {
      AttendanceOutsideMethod? chosenMethod;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  chosenMethod =
                      await showAttendanceTypeSelectionBottomSheet(ctx);
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Live Attendance (Real-Time)'));
      await tester.pumpAndSettle();

      expect(chosenMethod, AttendanceOutsideMethod.live);
    });
  });
}
