import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/localization/bloc/locale_bloc.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/account_settings_bottom_sheet.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';

class MockAuthRepo implements AuthRepository {
  String language = 'id';
  @override
  Future<String> updateLanguage(String lang) async {
    language = lang;
    return lang;
  }

  @override
  Future<UserProfileData> getProfile() async => throw UnimplementedError();
  @override
  Future<LoginResponseData> login(LoginRequestModel request) =>
      throw UnimplementedError();
  @override
  Future<String?> getSavedToken() async => null;
  @override
  Future<bool> hasActiveSession() async => true;
  @override
  Future<void> logout() async {}
}

class MockStorage implements SecureStorageService {
  String? lang;
  @override
  Future<void> saveUserLanguage(String l) async => lang = l;
  @override
  Future<String?> getUserLanguage() async => lang;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createTestWidget({LocaleBloc? bloc}) {
    return BlocProvider<LocaleBloc>(
      create: (_) =>
          bloc ??
          LocaleBloc(
            authRepository: MockAuthRepo(),
            storageService: MockStorage(),
          ),
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, state) {
          return MaterialApp(
            locale: state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AccountSettingsBottomSheet(avatarUrl: ''),
            ),
          );
        },
      ),
    );
  }

  testWidgets(
      'AccountSettingsBottomSheet renders profile, menu, and version footer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Title (Default ID locale will render Account Settings or Pengaturan Akun)
    expect(find.byType(AccountSettingsBottomSheet), findsOneWidget);

    // Verify Profile Info
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Senior Frontend Engineer'), findsOneWidget);
    expect(find.text('EMP-2024-019'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // Verify Settings Section
    expect(find.text('PENGATURAN & PREFERENSI'), findsOneWidget);
    expect(find.text('Ganti Password'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.text('ID (Bahasa)'), findsOneWidget);

    // Verify Logout card
    expect(find.text('Keluar dari Akun (Logout)'), findsOneWidget);

    // Verify Version Component is rendered
    expect(find.byType(AppNameVersionText), findsOneWidget);
  });

  testWidgets('Tapping Logout shows confirmation dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap Logout button
    await tester.tap(find.text('Keluar dari Akun (Logout)'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Konfirmasi Logout'), findsOneWidget);
    expect(
      find.text('Apakah Anda yakin ingin keluar dari sesi akun ini?'),
      findsOneWidget,
    );
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // Tap Batal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Logout'), findsNothing);
  });

  testWidgets('Tapping Bahasa opens dialog and selects English',
      (WidgetTester tester) async {
    final authRepo = MockAuthRepo();
    final storage = MockStorage();
    final bloc = LocaleBloc(authRepository: authRepo, storageService: storage);

    await tester.pumpWidget(createTestWidget(bloc: bloc));
    await tester.pumpAndSettle();

    // Initially ID
    expect(find.text('ID (Bahasa)'), findsOneWidget);

    // Tap Bahasa list tile
    await tester.tap(find.text('Bahasa'));
    await tester.pumpAndSettle();

    // Verify dialog opened with options
    expect(find.text('Pilih Bahasa'), findsOneWidget);
    expect(find.text('Bahasa Indonesia (ID)'), findsOneWidget);
    expect(find.text('English (EN)'), findsOneWidget);

    // Tap English (EN)
    await tester.tap(find.text('English (EN)'));
    await tester.pumpAndSettle();

    // Dialog closed
    expect(find.text('Pilih Bahasa'), findsNothing);

    // Badge updated to EN (English)
    expect(find.text('EN (English)'), findsOneWidget);
    expect(authRepo.language, 'en');
    expect(storage.lang, 'en');
  });
}
