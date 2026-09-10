import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_list/overtime_list_bloc.dart';
import 'package:hris_flutter/features/overtime/presentation/models/overtime_request_item.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/overtime_requests_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_request_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Mock repository untuk widget test — menyediakan data tanpa network.
class _MockOvertimeRepository implements OvertimeRepository {
  final bool teamForbidden;
  final List<OvertimeRequestItem> myItems;
  final List<OvertimeRequestItem> teamItems;

  _MockOvertimeRepository({
    this.teamForbidden = false,
    this.myItems = const [],
    this.teamItems = const [],
  });

  @override
  Future<OvertimeRequestListResponse> getOvertimeRequests({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
    String? startDate,
    String? endDate,
    bool approver = false,
    String? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (approver && teamForbidden) {
      throw ApiException(
        message: 'Forbidden access to approver overtime requests',
        statusCode: 403,
      );
    }
    final items = approver ? teamItems : myItems;
    return OvertimeRequestListResponse(
      success: true,
      message: 'OK',
      data: items,
      meta: OvertimePaginationMeta(
        page: 1,
        limit: 30,
        total: items.length,
        totalPages: 1,
      ),
    );
  }
}

OvertimeRequestItem _makeItem({
  required String id,
  required String name,
  OvertimeStatus status = OvertimeStatus.pending,
  bool isSelf = false,
}) {
  final start = DateTime(2026, 8, 28, 17, 0);
  final end = DateTime(2026, 8, 28, 21, 0);
  return OvertimeRequestItem(
    id: id,
    name: name,
    role: 'Frontend Engineer',
    department: 'Engineering',
    initials: name.split(' ').map((p) => p.isEmpty ? '' : p[0]).join(),
    startTime: start,
    endTime: end,
    note: 'Assisting operational cutover and database replication verification.',
    status: status,
    isSelf: isSelf,
  );
}

final _testItems = [
  _makeItem(id: 'ot-1', name: 'Sarah Jenkins', status: OvertimeStatus.pending),
  _makeItem(
    id: 'ot-2',
    name: 'Budi Santoso',
    status: OvertimeStatus.approved,
  ),
];

void main() {
  Widget createTestWidget({bool teamForbidden = false}) {
    return MaterialApp(
      home: OvertimeRequestsScreen(
        overtimeRepository: _MockOvertimeRepository(
          teamForbidden: teamForbidden,
          myItems: _testItems,
          teamItems: _testItems,
        ),
      ),
    );
  }

  group('OvertimeRequestsScreen Widget Tests (Google Stitch Specifications)',
      () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize =
          const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('merender AppBar judul Overtime Requests + subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Overtime Requests'), findsOneWidget);
      expect(
        find.text('Team approvals & overtime management'),
        findsOneWidget,
      );
    });

    testWidgets('merender TabBar My Overtime & Team Overtime', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Overtime'), findsOneWidget);
      expect(find.text('Team Overtime'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('tab My Overtime aktif awal (index 0) dan merender card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(OvertimeRequestCard), findsWidgets);
      expect(find.text('Sarah Jenkins'), findsWidgets);
      expect(find.text('Budi Santoso'), findsWidgets);
    });

    testWidgets('merender search bar di bawah TabBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Search by employee name or keyword...'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.search), findsWidgets);
    });

    testWidgets('FAB Tambah Lembur hanya tampil pada tab My Overtime', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tab 0 aktif -> FAB terlihat.
      expect(find.text('Tambah Lembur'), findsOneWidget);

      // Pindah ke tab Team Overtime -> FAB hilang.
      await tester.tap(find.text('Team Overtime'));
      await tester.pumpAndSettle();
      expect(find.text('Tambah Lembur'), findsNothing);
    });

    testWidgets('card memakai EmployeeInfoRow + badge status aktivitas-style',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Identitas via EmployeeInfoRow global (role • department).
      expect(find.text('Frontend Engineer • Engineering'), findsWidgets);

      // Badge status dengan label desain aktivitas (dot + label).
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Approved'), findsWidgets);
    });

    testWidgets('card merender jadwal, durasi, catatan, dan zona waktu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('4 Jam Kerja'), findsWidgets);
      expect(find.textContaining('17:00 - 21:00'), findsWidgets);
      expect(
        find.textContaining('Assisting operational cutover'),
        findsWidgets,
      );
      expect(find.text('WIB'), findsWidgets);
    });

    testWidgets('HTTP 403 Team Overtime menampilkan forbidden state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(teamForbidden: true));
      await tester.pumpAndSettle();

      // Pindah ke tab Team Overtime (index 1).
      await tester.tap(find.text('Team Overtime'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
      expect(
        find.textContaining('otoritas sebagai approver'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Ke Lembur Saya'), findsOneWidget);
    });

    testWidgets('forbidden state tidak merusak tab My Overtime', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(teamForbidden: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Team Overtime'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);

      // Pindah ke tab My Overtime (index 0) via tombol forbidden state.
      await tester.tap(find.text('Ke Lembur Saya'));
      await tester.pumpAndSettle();

      // Data My Overtime tetap ter-render normal.
      expect(find.text('Sarah Jenkins'), findsWidgets);
      expect(find.text('Tidak Memiliki Hak Akses'), findsNothing);
    });

    testWidgets('tombol filter ada di AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
    });

    testWidgets('isSelf menampilkan penanda Your request', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OvertimeRequestsScreen(
            overtimeRepository: _MockOvertimeRepository(
              myItems: [_makeItem(id: 'ot-self', name: 'Sarah Jenkins', isSelf: true)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your request'), findsOneWidget);
    });
  });

  group('OvertimeRequestCard Widget Tests', () {
    Widget wrapCard(OvertimeRequestItem item, {VoidCallback? onViewDetails}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OvertimeRequestCard(
              request: item,
              onViewDetails: onViewDetails,
            ),
          ),
        ),
      );
    }

    testWidgets('badge rejected memakai label dan palette Red', (
      WidgetTester tester,
    ) async {
      final item = _makeItem(
        id: 'ot-rej',
        name: 'Sarah Jenkins',
        status: OvertimeStatus.rejected,
      );
      await tester.pumpWidget(wrapCard(item));
      await tester.pumpAndSettle();

      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('status requested tampil sebagai label Pending', (
      WidgetTester tester,
    ) async {
      final item = _makeItem(
        id: 'ot-req',
        name: 'Sarah Jenkins',
        status: OvertimeStatus.requested,
      );
      await tester.pumpWidget(wrapCard(item));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('View Details hanya tampil jika callback diberikan', (
      WidgetTester tester,
    ) async {
      final item = _makeItem(id: 'ot-d', name: 'Sarah Jenkins');
      await tester.pumpWidget(wrapCard(item));
      await tester.pumpAndSettle();
      expect(find.text('View Details'), findsNothing);

      await tester.pumpWidget(wrapCard(item, onViewDetails: () {}));
      await tester.pumpAndSettle();
      expect(find.text('View Details'), findsOneWidget);
    });
  });

  group('OvertimeRequestsScreen BLoC injection', () {
    testWidgets('menerima bloc kustom via overtimeListBloc', (
      WidgetTester tester,
    ) async {
      final bloc = OvertimeListBloc(
        repository: _MockOvertimeRepository(
          myItems: _testItems,
          teamItems: _testItems,
        ),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: OvertimeRequestsScreen(overtimeListBloc: bloc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overtime Requests'), findsOneWidget);
      expect(find.text('Team Overtime'), findsOneWidget);
    });
  });
}
