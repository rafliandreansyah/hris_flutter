import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/models/employee_detail_model.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/change_password/change_password_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/pages/change_password_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakePasswordRepo implements EmployeeRepository {
  @override
  Future<String> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return 'Password berhasil diperbarui';
  }

  @override
  Future<List<EmployeeDirectoryItem>> getCoworkers() async => [];

  @override
  Future<EmployeeDetailData> getEmployeeDetail(String employeeId) async =>
      throw UnimplementedError();

  @override
  Future<EmployeeListResponse> getEmployees({
    required int page,
    int size = 30,
    String? companyId,
    String? departmentId,
    String? positionId,
    String? search,
  }) async =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWidget({ChangePasswordBloc? bloc}) {
    return MaterialApp(
      home: ChangePasswordScreen(
        repository: _FakePasswordRepo(),
        bloc: bloc,
      ),
    );
  }

  group('ChangePasswordScreen Widget Tests', () {
    testWidgets('renders all Stitch M3 Teal Oasis elements properly',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 1. AppBar
      expect(find.text('Ganti Password'), findsOneWidget);
      expect(find.text('Perbarui kata sandi akun keamanan Anda'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);

      // 2. Tips Keamanan Akun
      expect(find.text('Tips Keamanan Akun'), findsOneWidget);
      expect(
        find.textContaining('Gunakan kombinasi minimal 8 karakter'),
        findsOneWidget,
      );

      // 3. Form Input Fields
      expect(find.text('Password Saat Ini *'), findsOneWidget);
      expect(find.text('Lupa Password?'), findsOneWidget);
      expect(find.text('Password Baru *'), findsOneWidget);
      expect(find.text('Konfirmasi Password Baru *'), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(3));

      // 4. Kriteria Kelayakan Password
      expect(find.text('KRITERIA KELAYAKAN PASSWORD'), findsOneWidget);
      expect(find.text('Minimal 8 karakter'), findsOneWidget);
      expect(find.text('Mengandung huruf besar & kecil'), findsOneWidget);
      expect(find.text('Mengandung angka (0-9)'), findsOneWidget);
      expect(find.text('Mengandung simbol (contoh: !@#\$%)'), findsOneWidget);

      // 5. Submit Button
      expect(find.text('Simpan & Perbarui Password'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('typing valid password updates criteria checkmarks',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially, 4 criteria are unfulfilled (4 LucideIcons.circle)
      // Note: 1 LucideIcons.circleCheck is present as prefix icon in Confirm Password field
      expect(find.byIcon(LucideIcons.circle), findsNWidgets(4));
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);

      // Find password baru input (the second AppTextField)
      final passwordBaruFinder = find.byType(TextField).at(1);

      // Type partial: only lowercase
      await tester.enterText(passwordBaruFinder, 'abcd');
      await tester.pumpAndSettle();
      // Still all 4 criteria unfulfilled
      expect(find.byIcon(LucideIcons.circle), findsNWidgets(4));

      // Type 8 characters, upper & lower, number, and symbol
      await tester.enterText(passwordBaruFinder, 'Abcdef1!');
      await tester.pumpAndSettle();

      // All 4 criteria are now met (4 in criteria card + 1 prefix icon = 5)
      expect(find.byIcon(LucideIcons.circleCheck), findsNWidgets(5));
      expect(find.byIcon(LucideIcons.circle), findsNothing);
    });

    testWidgets('tapping submit with empty inputs triggers validation errors',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap submit button directly
      await tester.tap(find.text('Simpan & Perbarui Password'));
      await tester.pumpAndSettle();

      // Form validation errors shown
      expect(find.text('Password saat ini wajib diisi'), findsOneWidget);
      expect(find.text('Password baru wajib diisi'), findsOneWidget);
      expect(find.text('Konfirmasi password baru wajib diisi'), findsOneWidget);
    });
  });
}
