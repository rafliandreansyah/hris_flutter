import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/core/localization/bloc/locale_bloc.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/theme/bloc/theme_bloc.dart';
import 'package:hris_flutter/core/widgets/app_name_version_text.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/account_settings_bottom_sheet.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';

class MockAuthRepo implements AuthRepository {
  String language = 'id';
  bool logoutCalled = false;

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
  Future<void> logout() async {
    logoutCalled = true;
  }
}

class MockStorage implements SecureStorageService {
  String? lang;
  String? theme;

  @override
  Future<void> saveUserLanguage(String l) async => lang = l;
  @override
  Future<String?> getUserLanguage() async => lang;

  @override
  Future<void> saveThemeMode(String t) async => theme = t;
  @override
  Future<String?> getThemeMode() async => theme;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createTestWidget({
    LocaleBloc? localeBloc,
    ThemeBloc? themeBloc,
    AuthRepository? authRepository,
    MockStorage? storage,
  }) {
    final effectiveStorage = storage ?? MockStorage();
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleBloc>(
          create: (_) =>
              localeBloc ??
              LocaleBloc(
                authRepository: MockAuthRepo(),
                storageService: effectiveStorage,
              ),
        ),
        BlocProvider<ThemeBloc>(
          create: (_) =>
              themeBloc ??
              ThemeBloc(
                storageService: effectiveStorage,
              ),
        ),
      ],
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, localeState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
                locale: localeState.locale,
                themeMode: themeState.themeMode,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: AccountSettingsBottomSheet(
                    avatarUrl: '',
                    authRepository: authRepository,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget createModalLauncherTestWidget({
    ThemeBloc? themeBloc,
    MockStorage? storage,
  }) {
    final effectiveStorage = storage ?? MockStorage();
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleBloc>(
          create: (_) => LocaleBloc(
            authRepository: MockAuthRepo(),
            storageService: effectiveStorage,
          ),
        ),
        BlocProvider<ThemeBloc>(
          create: (_) =>
              themeBloc ??
              ThemeBloc(
                storageService: effectiveStorage,
              ),
        ),
      ],
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, localeState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
                locale: localeState.locale,
                themeMode: themeState.themeMode,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Builder(
                    builder: (scaffoldCtx) => ElevatedButton(
                      onPressed: () {
                        showAccountSettingsBottomSheet(
                          scaffoldCtx,
                          avatarUrl: '',
                        );
                      },
                      child: const Text('Open Settings'),
                    ),
                  ),
                ),
              );
            },
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
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Sistem'), findsOneWidget);

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Konfirmasi Logout'), findsNothing);
  });

  testWidgets('Tapping Keluar in confirmation dialog calls logout',
      (WidgetTester tester) async {
    final mockAuth = MockAuthRepo();
    await tester.pumpWidget(createTestWidget(authRepository: mockAuth));
    await tester.pumpAndSettle();

    // Tap Logout button
    await tester.tap(find.text('Keluar dari Akun (Logout)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify confirmation dialog
    expect(find.text('Konfirmasi Logout'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // Tap Keluar
    await tester.tap(find.text('Keluar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(mockAuth.logoutCalled, isTrue);
  });

  testWidgets('Tapping Bahasa opens dialog and selects English',
      (WidgetTester tester) async {
    final authRepo = MockAuthRepo();
    final storage = MockStorage();
    final localeBloc = LocaleBloc(authRepository: authRepo, storageService: storage);

    await tester.pumpWidget(createTestWidget(localeBloc: localeBloc, storage: storage));
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

  testWidgets('Tapping Tema opens dialog and selects Mode Gelap',
      (WidgetTester tester) async {
    final storage = MockStorage();
    final themeBloc = ThemeBloc(storageService: storage);

    await tester.pumpWidget(createTestWidget(themeBloc: themeBloc, storage: storage));
    await tester.pumpAndSettle();

    // Initially Sistem
    expect(find.text('Sistem'), findsOneWidget);

    // Tap Tema list tile
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    // Verify dialog opened with options
    expect(find.text('Pilih Tema'), findsOneWidget);
    expect(find.text('Mengikuti Sistem'), findsOneWidget);
    expect(find.text('Mode Terang'), findsOneWidget);
    expect(find.text('Mode Gelap'), findsOneWidget);

    // Tap Mode Gelap
    await tester.tap(find.text('Mode Gelap'));
    await tester.pumpAndSettle();

    // Dialog closed
    expect(find.text('Pilih Tema'), findsNothing);

    // Badge updated to Gelap
    expect(find.text('Gelap'), findsOneWidget);
    expect(themeBloc.state.themeMode, ThemeMode.dark);
    expect(storage.theme, 'dark');
  });

  testWidgets('Tapping Tema opens dialog and selects Mode Terang',
      (WidgetTester tester) async {
    final storage = MockStorage();
    final themeBloc = ThemeBloc(storageService: storage);

    await tester.pumpWidget(createTestWidget(themeBloc: themeBloc, storage: storage));
    await tester.pumpAndSettle();

    // Tap Tema list tile
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    // Tap Mode Terang
    await tester.tap(find.text('Mode Terang'));
    await tester.pumpAndSettle();

    // Badge updated to Terang
    expect(find.text('Terang'), findsOneWidget);
    expect(themeBloc.state.themeMode, ThemeMode.light);
    expect(storage.theme, 'light');
  });

  testWidgets(
      'showAccountSettingsBottomSheet dynamically updates theme from dark to light without closing',
      (WidgetTester tester) async {
    final storage = MockStorage();
    storage.theme = 'dark';
    final themeBloc = ThemeBloc(storageService: storage);
    themeBloc.add(const ThemeChanged(ThemeMode.dark));

    await tester.pumpWidget(createModalLauncherTestWidget(
      themeBloc: themeBloc,
      storage: storage,
    ));
    await tester.pumpAndSettle();

    // Tap button to open modal bottom sheet
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    // Initially Gelap
    expect(find.text('Gelap'), findsOneWidget);

    // Verify initial dark surface decoration
    final darkRootContainerFinder = find.descendant(
      of: find.byType(AccountSettingsBottomSheet),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == AppColors.darkSurfaceContainerLowest &&
              box.borderRadius ==
                  const BorderRadius.vertical(top: Radius.circular(28));
        }
        return false;
      }),
    );
    expect(darkRootContainerFinder, findsOneWidget);

    // Tap Tema -> Tap Mode Terang
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mode Terang'));
    await tester.pumpAndSettle();

    // Bottom sheet is STILL open, and theme badge is now Terang!
    expect(find.text('Terang'), findsOneWidget);
    expect(themeBloc.state.themeMode, ThemeMode.light);

    // Verify light surface decoration updated dynamically while sheet is still open!
    final lightRootContainerFinder = find.descendant(
      of: find.byType(AccountSettingsBottomSheet),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == AppColors.surfaceContainerLowest &&
              box.borderRadius ==
                  const BorderRadius.vertical(top: Radius.circular(28));
        }
        return false;
      }),
    );
    expect(lightRootContainerFinder, findsOneWidget);

    // Now tap Tema -> Tap Mode Gelap again
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mode Gelap'));
    await tester.pumpAndSettle();

    // Bottom sheet updated dynamically back to Gelap!
    expect(find.text('Gelap'), findsOneWidget);
    expect(themeBloc.state.themeMode, ThemeMode.dark);
    expect(darkRootContainerFinder, findsOneWidget);
  });
}
