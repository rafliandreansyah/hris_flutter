import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_action_dialog.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_action_dialog.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_action_dialog.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/reimbursement_action_dialog.dart';

typedef _Show = Future<String?> Function(
  BuildContext context, {
  required bool isApproved,
});

/// Dialog approve/reject di seluruh modul pengajuan memakai kontrak yang sama:
/// "Batal" -> null, "Setujui"/"Tolak" -> catatan ter-trim.
void main() {
  final dialogs = <String, _Show>{
    'LeaveActionDialog': (c, {required isApproved}) =>
        LeaveActionDialog.show(c, isApproved: isApproved),
    'OvertimeActionDialog': (c, {required isApproved}) =>
        OvertimeActionDialog.show(c, isApproved: isApproved),
    'ReimbursementActionDialog': (c, {required isApproved}) =>
        ReimbursementActionDialog.show(c, isApproved: isApproved),
    'AttendanceRequestActionDialog': (c, {required isApproved}) =>
        AttendanceRequestActionDialog.show(c, isApproved: isApproved),
  };

  for (final entry in dialogs.entries) {
    group(entry.key, () {
      late String? result;
      var resolved = false;

      Future<void> openDialog(
        WidgetTester tester, {
        required bool isApproved,
      }) async {
        result = 'belum-selesai';
        resolved = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await entry.value(context, isApproved: isApproved);
                      resolved = true;
                    },
                    child: const Text('buka'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('buka'));
        await tester.pumpAndSettle();
      }

      testWidgets('mode setuju menampilkan tombol Setujui & Batal', (tester) async {
        await openDialog(tester, isApproved: true);

        expect(find.widgetWithText(AppButton, 'Setujui'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Batal'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Tolak'), findsNothing);
      });

      testWidgets('mode tolak menampilkan tombol Tolak & Batal', (tester) async {
        await openDialog(tester, isApproved: false);

        expect(find.widgetWithText(AppButton, 'Tolak'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Batal'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Setujui'), findsNothing);
      });

      testWidgets('Batal menutup dialog dan mengembalikan null', (tester) async {
        await openDialog(tester, isApproved: true);

        await tester.tap(find.widgetWithText(AppButton, 'Batal'));
        await tester.pumpAndSettle();

        expect(resolved, isTrue);
        expect(result, isNull);
        expect(find.byType(Dialog), findsNothing);
      });

      testWidgets('Setujui tanpa catatan mengembalikan string kosong', (tester) async {
        await openDialog(tester, isApproved: true);

        await tester.tap(find.widgetWithText(AppButton, 'Setujui'));
        await tester.pumpAndSettle();

        expect(resolved, isTrue);
        expect(result, '');
      });

      testWidgets('Tolak mengembalikan catatan yang sudah di-trim', (tester) async {
        await openDialog(tester, isApproved: false);

        await tester.enterText(find.byType(TextField), '   Dokumen kurang lengkap  ');
        await tester.pump();
        await tester.tap(find.widgetWithText(AppButton, 'Tolak'));
        await tester.pumpAndSettle();

        expect(resolved, isTrue);
        expect(result, 'Dokumen kurang lengkap');
      });
    });
  }
}
