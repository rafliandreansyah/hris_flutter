import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/warning_letter/data/models/create_warning_letter_models.dart';
import 'package:hris_flutter/features/warning_letter/data/models/last_warning_letter_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_item_model.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_list_response.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_type_model.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/pages/warning_letter_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _MockWarningLetterRepo implements WarningLetterRepository {
  final bool simulateForbiddenOnTeam;

  _MockWarningLetterRepo({this.simulateForbiddenOnTeam = false});

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
    if (approver && simulateForbiddenOnTeam) {
      throw const ApiException(
        message: 'Tidak memiliki hak akses',
        statusCode: 403,
      );
    }

    return WarningLetterListResponse(
      success: true,
      message: 'OK',
      data: [
        WarningLetterItem(
          id: approver ? 'team-item-1' : 'my-item-1',
          warningLetterType: WarningLetterTypeSummary(
            level: approver ? 2 : 1,
            name: approver
                ? 'Pelanggaran SOP & Ketidakpatuhan Kerja'
                : 'Teguran Indisipliner Kehadiran',
          ),
          employee: WarningLetterEmployee(
            id: 'emp-101',
            firstName: approver ? 'Budi' : 'Dimas',
            lastName: approver ? 'Santoso' : 'Anggara',
            employeeNumber: approver ? 'EMP-8492' : 'EMP-9103',
            company: const WarningLetterOrgUnit(id: 'c1', name: 'PT Muratech'),
            department: const WarningLetterOrgUnit(id: 'd1', name: 'Operations'),
            position: const WarningLetterOrgUnit(id: 'p1', name: 'Supervisor'),
          ),
          isActive: true,
          createdAt: DateTime(2026, 8, 29, 12, 47),
          timezone: 'WIB',
        ),
      ],
      meta: const WarningLetterPaginationMeta(
        page: 1,
        limit: 10,
        total: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<List<WarningLetterTypeModel>> getWarningLetterTypes() async {
    return const [
      WarningLetterTypeModel(
        id: 't-1',
        name: 'SP 1',
        level: 1,
        validityPeriodMonths: 6,
      ),
      WarningLetterTypeModel(
        id: 't-2',
        name: 'SP 2',
        level: 2,
        validityPeriodMonths: 6,
      ),
    ];
  }

  @override
  Future<LastWarningLetterModel?> getLastWarningLetter(String employeeId) async {
    return null;
  }

  @override
  Future<CreateWarningLetterResponse> createWarningLetter(
    CreateWarningLetterRequest request,
  ) async {
    return const CreateWarningLetterResponse(
      success: true,
      message: 'OK',
    );
  }

  @override
  Future<WarningLetterDetail> getWarningLetterDetail(String id) async {
    return const WarningLetterDetail(
      id: 'my-item-1',
      warningLetterType: WarningLetterTypeSummary(
        level: 1,
        name: 'Teguran Indisipliner Kehadiran',
      ),
      timezone: 'WIB',
      isActive: true,
      createdAt: null,
      issuedDate: null,
      expiredDate: null,
    );
  }
}

void main() {
  Widget createWidgetUnderTest({bool simulateForbiddenOnTeam = false}) {
    return MaterialApp(
      home: WarningLetterScreen(
        repository: _MockWarningLetterRepo(
          simulateForbiddenOnTeam: simulateForbiddenOnTeam,
        ),
      ),
    );
  }

  group('WarningLetterScreen Widget Tests', () {
    testWidgets(
        'renders Tab 0 (Surat Diterima) with items, no FAB and no search bar',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Surat Peringatan'), findsOneWidget);
      expect(find.text('Surat Diterima'), findsOneWidget);
      expect(find.text('Diterbitkan'), findsOneWidget);

      // Tab 0 list has item Dimas Anggara
      expect(find.text('Dimas Anggara'), findsOneWidget);
      expect(find.text('Teguran Indisipliner Kehadiran'), findsOneWidget);
      expect(find.text('SP 1'), findsOneWidget);

      // On Tab 0, FAB should NOT be visible
      final fab = find.byKey(const ValueKey('add_warning_letter_fab'));
      expect(fab, findsNothing);
    });

    testWidgets(
        'switching to Tab 1 (Diterbitkan) reveals search bar and FAB when authorized',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(simulateForbiddenOnTeam: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Tab 1: "Diterbitkan"
      await tester.tap(find.text('Diterbitkan'));
      await tester.pumpAndSettle();

      // Item in Tab 1 (Budi Santoso) should be visible
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Pelanggaran SOP & Ketidakpatuhan Kerja'), findsOneWidget);
      expect(find.text('SP 2'), findsOneWidget);

      // Search bar hint is visible
      expect(find.byType(TextField), findsOneWidget);

      // FAB is visible
      expect(find.text('Buat Surat Peringatan'), findsOneWidget);
    });

    testWidgets(
        'Tab 1 with 403 Forbidden shows Tidak Memiliki Hak Akses and hides FAB',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(simulateForbiddenOnTeam: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Tab 1: "Diterbitkan"
      await tester.tap(find.text('Diterbitkan'));
      await tester.pumpAndSettle();

      // Error 403 Forbidden card should appear
      expect(find.text('Tidak Memiliki Hak Akses'), findsOneWidget);
      expect(
        find.textContaining('tidak memiliki otoritas untuk melihat atau menerbitkan'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);

      // FAB must be hidden!
      expect(find.byKey(const ValueKey('add_warning_letter_fab')), findsNothing);
    });

    testWidgets('tapping filter button opens WarningLetterFilterBottomSheet',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final filterBtn = find.byIcon(LucideIcons.slidersHorizontal);
      expect(filterBtn, findsOneWidget);
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      // Bottom sheet header & fields
      expect(find.text('Filter Surat Peringatan'), findsOneWidget);
      expect(find.text('Reset Filter'), findsOneWidget);
      expect(find.text('Rentang Tanggal'), findsOneWidget);
      expect(find.text('Tipe Surat Peringatan'), findsOneWidget);
      expect(find.text('Status Surat Peringatan'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}
