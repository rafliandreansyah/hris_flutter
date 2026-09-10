import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_list/leave_list_bloc.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';
import 'package:hris_flutter/features/leave/presentation/pages/leave_screen.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_request_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Mock repository untuk widget test — menyediakan data tanpa network.
class _MockLeaveRepository implements LeaveRepository {
  final bool teamForbidden;
  final List<LeaveRequestItem> myItems;
  final List<LeaveRequestItem> teamItems;

  _MockLeaveRepository({
    this.teamForbidden = false,
    this.myItems = const [],
    this.teamItems = const [],
  });

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
    await Future.delayed(const Duration(milliseconds: 10));
    if (approver && teamForbidden) {
      throw ApiException(
        message: 'Forbidden access to approver leave requests',
        statusCode: 403,
      );
    }
    final items = approver ? teamItems : myItems;
    return LeaveRequestListResponse(
      success: true,
      message: 'OK',
      data: items,
      meta: LeavePaginationMeta(
        page: 1,
        limit: 30,
        total: items.length,
        totalPages: 1,
      ),
    );
  }
}

final _testItems = [
  LeaveRequestItem(
    id: 'lr-1',
    name: 'Sarah Jenkins',
    role: 'Frontend Engineer',
    department: 'Engineering',
    initials: 'SJ',
    leaveType: 'Annual Leave',
    days: 3,
    startDate: DateTime(2026, 8, 28),
    endDate: DateTime(2026, 8, 30),
    note: 'Attending technical conference out of town.',
    status: LeaveStatus.pending,
  ),
  LeaveRequestItem(
    id: 'lr-2',
    name: 'Budi Santoso',
    role: 'Site Supervisor',
    department: 'Operations',
    initials: 'BS',
    leaveType: 'Sick Leave',
    days: 1,
    startDate: DateTime(2026, 8, 27),
    endDate: DateTime(2026, 8, 27),
    note: 'Doctor appointment for regular health checkup.',
    status: LeaveStatus.approved,
  ),
];

void main() {
  Widget createTestWidget({bool teamForbidden = false}) {
    return MaterialApp(
      home: LeaveScreen(
        leaveRepository: _MockLeaveRepository(
          teamForbidden: teamForbidden,
          myItems: _testItems,
          teamItems: _testItems,
        ),
      ),
    );
  }

  group('LeaveScreen Widget Tests (Google Stitch Specifications)', () {
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

    testWidgets('merender AppBar judul Leave & Time Off + subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Leave & Time Off'), findsOneWidget);
      expect(find.text('Team approvals & time-off management'), findsOneWidget);
    });

    testWidgets('merender TabBar My Requests & Team Requests', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Requests'), findsOneWidget);
      expect(find.text('Team Requests'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
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

    testWidgets('tanpa chip filter horizontal (sesuai instruksi desain)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Depts'), findsNothing);
      expect(find.text('All Status'), findsNothing);
      expect(find.text('All Types'), findsNothing);
    });

    testWidgets('tab Team Requests aktif awal dan merender LeaveRequestCard', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LeaveRequestCard), findsWidgets);
      expect(find.text('Sarah Jenkins'), findsWidgets);
      expect(find.text('Budi Santoso'), findsWidgets);
    });

    testWidgets('card memakai EmployeeInfoRow + badge status aktivitas-style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Identitas via EmployeeInfoRow global (nama + role • department).
      expect(find.text('Frontend Engineer • Engineering'), findsWidgets);

      // Badge status dengan label desain aktivitas (dot + label).
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Approved'), findsWidgets);
    });

    testWidgets('card merender detail leave type, durasi, tanggal, dan note', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Annual Leave'), findsWidgets);
      expect(find.text('3 Days'), findsWidgets);
      expect(find.text('28 Agu 2026 - 30 Agu 2026'), findsWidgets);
      expect(
        find.textContaining('Attending technical conference'),
        findsWidgets,
      );
      expect(find.textContaining('Submitted with Timezone'), findsWidgets);
    });

    testWidgets('HTTP 403 Team Requests menampilkan forbidden state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(teamForbidden: true));
      await tester.pumpAndSettle();

      // Pindah ke tab Team Requests (index 1)
      await tester.tap(find.text('Team Requests'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
      expect(find.textContaining('otoritas sebagai approver'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Ke Pengajuan Saya'), findsOneWidget);
    });

    testWidgets('forbidden state tidak merusak tab My Requests', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(teamForbidden: true));
      await tester.pumpAndSettle();

      // Pindah ke tab Team Requests (index 1)
      await tester.tap(find.text('Team Requests'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);

      // Pindah ke tab My Requests (index 0) via tombol forbidden state.
      await tester.tap(find.text('Ke Pengajuan Saya'));
      await tester.pumpAndSettle();

      // Data My Requests tetap ter-render normal.
      expect(find.text('Sarah Jenkins'), findsWidgets);
      expect(find.text('Tidak Memiliki Hak Akses'), findsNothing);
    });

    testWidgets('tombol filter ada di AppBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
    });

    testWidgets('pindah tab ke My Requests merender request milik sendiri', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Requests'));
      await tester.pumpAndSettle();

      // My Requests memakai data yang sama dari mock repo (isSelf=false
      // pada fixture, jadi tidak ada penanda "Your request").
      expect(find.byType(LeaveRequestCard), findsWidgets);
      expect(find.text('Sarah Jenkins'), findsWidgets);
    });
  });

  group('LeaveRequestCard Widget Tests', () {
    Widget wrapCard(LeaveRequestItem item, {VoidCallback? onViewDetails}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LeaveRequestCard(item: item, onViewDetails: onViewDetails),
          ),
        ),
      );
    }

    testWidgets('badge rejected memakai label dan palette Red', (
      WidgetTester tester,
    ) async {
      final item = _testItems.first.copyWith(
        id: 'lr-rej',
        status: LeaveStatus.rejected,
      );
      await tester.pumpWidget(wrapCard(item));
      await tester.pumpAndSettle();

      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('status requested tampil sebagai label Pending', (
      WidgetTester tester,
    ) async {
      final item = _testItems.first.copyWith(
        id: 'lr-req',
        status: LeaveStatus.requested,
      );
      await tester.pumpWidget(wrapCard(item));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('View Details hanya tampil jika callback diberikan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapCard(_testItems.first));
      await tester.pumpAndSettle();
      expect(find.text('View Details'), findsNothing);

      await tester.pumpWidget(wrapCard(_testItems.first, onViewDetails: () {}));
      await tester.pumpAndSettle();
      expect(find.text('View Details'), findsOneWidget);
    });

    testWidgets('isSelf menampilkan penanda Your request', (
      WidgetTester tester,
    ) async {
      final item = _testItems.first.copyWith(id: 'lr-self', isSelf: true);
      await tester.pumpWidget(wrapCard(item));
      await tester.pumpAndSettle();

      expect(find.text('Your request'), findsOneWidget);
    });
  });

  group('LeaveScreen BLoC injection', () {
    testWidgets('menerima bloc kustom via leaveListBloc', (
      WidgetTester tester,
    ) async {
      final bloc = LeaveListBloc(
        repository: _MockLeaveRepository(
          myItems: _testItems,
          teamItems: _testItems,
        ),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(MaterialApp(home: LeaveScreen(leaveListBloc: bloc)));
      await tester.pumpAndSettle();

      expect(find.text('Leave & Time Off'), findsOneWidget);
      expect(find.text('Team Requests'), findsOneWidget);
    });
  });
}
