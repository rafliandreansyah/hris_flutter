import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _MockAuthRepoForScreen implements AuthRepository {
  @override
  Future<LoginResponseData> login(LoginRequestModel request) async =>
      const LoginResponseData(token: 'mock-token');
  @override
  Future<String?> getSavedToken() async => null;
  @override
  Future<bool> hasActiveSession() async => false;
  @override
  Future<void> logout() async {}
  @override
  Future<UserProfileData> getProfile() async => throw UnimplementedError();
  @override
  Future<String> updateLanguage(String language) async => language;
}

class TestAuthBloc extends AuthBloc {
  final List<AuthEvent> dispatchedEvents = [];

  TestAuthBloc() : super(authRepository: _MockAuthRepoForScreen());

  void emitState(AuthState state) {
    emit(state);
  }

  @override
  void add(AuthEvent event) {
    dispatchedEvents.add(event);
  }
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders login screen elements correctly', (tester) async {
      final authBloc = TestAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authBloc: authBloc),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.textContaining("Don't have an account?"), findsOneWidget);
      expect(find.textContaining('Contact HR'), findsOneWidget);
    });

    testWidgets('validates empty email and password on submit (AUTH-03)', (tester) async {
      final authBloc = TestAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authBloc: authBloc),
        ),
      );

      // Tap Login button directly without filling fields
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(find.text('Password tidak boleh kosong'), findsOneWidget);
      expect(authBloc.dispatchedEvents, isEmpty);
    });

    testWidgets('validates invalid email format and short password (AUTH-03)', (tester) async {
      final authBloc = TestAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authBloc: authBloc),
        ),
      );

      // Enter invalid email and short password
      await tester.enterText(find.byType(TextField).first, 'invalidemail');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(find.text('Password minimal 6 karakter'), findsOneWidget);
      expect(authBloc.dispatchedEvents, isEmpty);
    });

    testWidgets('submits valid credentials and dispatches AuthLoginSubmitted (AUTH-01 & AUTH-02)', (tester) async {
      final authBloc = TestAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authBloc: authBloc),
        ),
      );

      // Enter valid email and password
      await tester.enterText(find.byType(TextField).first, 'user@gmail.com');
      await tester.enterText(find.byType(TextField).last, 'amaterasu');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(authBloc.dispatchedEvents, contains(
        const AuthLoginSubmitted(
          email: 'user@gmail.com',
          password: 'amaterasu',
        ),
      ));
    });

    testWidgets('toggles password visibility with eye icon (AUTH-05)', (tester) async {
      final authBloc = TestAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authBloc: authBloc),
        ),
      );

      // Initially obscure icon is eye
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
      expect(find.byIcon(LucideIcons.eyeOff), findsNothing);

      // Tap eye icon to un-obscure password
      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();

      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(find.byIcon(LucideIcons.eye), findsNothing);

      // Tap again to re-obscure
      await tester.tap(find.byIcon(LucideIcons.eyeOff));
      await tester.pump();

      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    });

    testWidgets('displays loading state on AppButton during AuthLoading', (tester) async {
      final authBloc = TestAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authBloc: authBloc),
        ),
      );

      // Emit AuthLoading
      authBloc.emitState(const AuthLoading());
      await tester.pump();

      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);
      final appButton = tester.widget<AppButton>(buttonFinder);
      expect(appButton.isLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays pro_dialog error dialog on AuthFailure and can dismiss it (AUTH-04)', (tester) async {
      final authBloc = TestAuthBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authBloc: authBloc),
        ),
      );

      // Emit AuthFailure
      authBloc.emitState(const AuthFailure(message: 'Kombinasi email atau password salah'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify pro_dialog error elements
      expect(find.text('Login Gagal'), findsOneWidget);
      expect(find.text('Kombinasi email atau password salah'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      // Tap Tutup to dismiss error dialog
      await tester.tap(find.text('Tutup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog should be gone
      expect(find.text('Login Gagal'), findsNothing);
    });

    testWidgets('displays SnackBar on AuthSuccess', (tester) async {
      final authBloc = TestAuthBloc();

      final router = GoRouter(
        initialLocation: Routes.LOGIN,
        routes: [
          GoRoute(
            path: Routes.LOGIN,
            builder: (context, state) => LoginScreen(authBloc: authBloc),
          ),
          GoRoute(
            path: Routes.DASHBOARD,
            builder: (context, state) => const Scaffold(body: Text('Dashboard Screen Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      authBloc.emitState(const AuthSuccess(token: 'jwt-success-token', message: 'Selamat datang!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Selamat datang!'), findsOneWidget);
      expect(find.text('Dashboard Screen Mock'), findsOneWidget);
    });

    testWidgets('tapping Forgot Password? navigates to RESET route (AUTH-06)', (tester) async {
      final authBloc = TestAuthBloc();

      final router = GoRouter(
        initialLocation: Routes.LOGIN,
        routes: [
          GoRoute(
            path: Routes.LOGIN,
            builder: (context, state) => LoginScreen(authBloc: authBloc),
          ),
          GoRoute(
            path: Routes.RESET,
            builder: (context, state) => const Scaffold(body: Text('Reset Password Mock Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password Mock Screen'), findsOneWidget);
    });
  });
}
