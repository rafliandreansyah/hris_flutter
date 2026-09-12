import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_api_models.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/pages/create_leave_screen.dart';
import 'package:image_picker/image_picker.dart';

class _FakeLeaveRepository implements LeaveRepository {
  List<LeaveTypeOptionModel> types = [
    const LeaveTypeOptionModel(
      id: 'type-sick',
      code: 'SICK',
      name: 'Cuti Sakit',
      requiresFile: true,
      fixedDays: null,
      maxDays: 5,
    ),
    const LeaveTypeOptionModel(
      id: 'type-annual',
      code: 'ANNUAL',
      name: 'Cuti Tahunan',
      requiresFile: false,
      isDeducted: true,
      maxDays: 12,
    ),
  ];

  @override
  Future<LeaveRequestListResponse> getLeaveRequests({
    required int page,
    int size = 30,
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
  }) async {}

  @override
  Future<void> deleteLeaveRequest(String id) async {}

  @override
  Future<List<LeaveTypeOptionModel>> getLeaveTypes() async {
    return types;
  }

  @override
  Future<CreateLeaveResultModel> createLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required int totalDays,
    required String notes,
    XFile? file,
  }) async {
    return const CreateLeaveResultModel(
      success: true,
      message: 'Leave request created',
      id: 'created-id-123',
    );
  }
}

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('CreateLeaveScreen Widget Tests', () {
    late _FakeLeaveRepository repository;

    setUp(() {
      repository = _FakeLeaveRepository();
    });

    testWidgets('renders all form sections and submit button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          CreateLeaveScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('Ajukan Cuti / Izin'), findsOneWidget);
      expect(find.text('Formulir permohonan cuti & izin karyawan'), findsOneWidget);

      // Verify Sections
      expect(find.text('JENIS CUTI / IZIN'), findsOneWidget);
      expect(find.text('PERIODE & DURASI CUTI'), findsOneWidget);
      expect(find.text('ALASAN / CATATAN'), findsOneWidget);
      expect(find.text('DOKUMEN PENDUKUNG'), findsOneWidget);

      // Verify initial days counter & submit button
      final counter = tester.widget<Text>(find.byKey(const ValueKey('days_counter_text')));
      expect(counter.data, '1 Hari');
      expect(find.text('Kirim Pengajuan Cuti'), findsOneWidget);
    });

    testWidgets('increment, decrement, and 30 days max selection limit work correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          CreateLeaveScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      final decrementFinder = find.byKey(const ValueKey('decrement_days_btn'));
      final incrementFinder = find.byKey(const ValueKey('increment_days_btn'));

      // Initially at 1 day
      final decBtn = tester.widget<IconButton>(decrementFinder);
      expect(decBtn.onPressed, isNull); // Disabled at min 1 day

      // Increment to 2 days
      await tester.tap(incrementFinder);
      await tester.pumpAndSettle();
      final counterAt2 = tester.widget<Text>(find.byKey(const ValueKey('days_counter_text')));
      expect(counterAt2.data, '2 Hari');

      // Decrement back to 1 day
      await tester.tap(decrementFinder);
      await tester.pumpAndSettle();
      final counterAt1 = tester.widget<Text>(find.byKey(const ValueKey('days_counter_text')));
      expect(counterAt1.data, '1 Hari');

      // Tap quick chip for 30 Hari
      final chip30Finder = find.widgetWithText(ChoiceChip, '30 Hari');
      expect(chip30Finder, findsOneWidget);
      await tester.tap(chip30Finder);
      await tester.pumpAndSettle();

      // Counter should now show 30 Hari
      final counterAt30 = tester.widget<Text>(find.byKey(const ValueKey('days_counter_text')));
      expect(counterAt30.data, '30 Hari');

      // At 30 days, increment button must be disabled
      final incBtnAt30 = tester.widget<IconButton>(incrementFinder);
      expect(incBtnAt30.onPressed, isNull);
    });

    testWidgets('shows warning when submitting without selecting leave type',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          CreateLeaveScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const ValueKey('submit_leave_btn'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Silakan pilih jenis cuti/izin terlebih dahulu.'),
        findsOneWidget,
      );
    });

    testWidgets('selecting leave type from bottom sheet updates UI',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          CreateLeaveScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Tap leave type selector
      final selector = find.byKey(const ValueKey('leave_type_selector'));
      await tester.tap(selector);
      await tester.pumpAndSettle();

      // Bottom sheet should show leave types
      expect(find.text('Pilih Jenis Cuti / Izin'), findsNWidgets(2));
      expect(find.text('Cuti Sakit'), findsOneWidget);
      expect(find.text('Cuti Tahunan'), findsOneWidget);

      // Select Cuti Sakit
      await tester.tap(find.text('Cuti Sakit'));
      await tester.pumpAndSettle();

      // Form should now display Cuti Sakit and show mandatory document tag
      expect(find.text('Cuti Sakit'), findsOneWidget);
      expect(find.text('Wajib Dokumen/Foto'), findsOneWidget);
    });

    testWidgets('shows warning when submitting without notes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          CreateLeaveScreen(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Select leave type
      final selector = find.byKey(const ValueKey('leave_type_selector'));
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuti Tahunan'));
      await tester.pumpAndSettle();

      // Submit without notes
      final submitBtn = find.byKey(const ValueKey('submit_leave_btn'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Alasan pengajuan cuti/izin wajib diisi.'),
        findsOneWidget,
      );
    });
  });
}
