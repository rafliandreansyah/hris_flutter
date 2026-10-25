import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/auth/data/repositories/password_reset_repository.dart';
import 'package:hris_flutter/features/auth/presentation/pages/reset_password_screen.dart';

class _FakePasswordResetRepository implements PasswordResetRepository {
  final String result;
  final ApiException? error;
  final Completer<String>? pending;
  final List<String> requestedEmails = [];

  _FakePasswordResetRepository({
    this.result = 'OK',
    this.error,
    this.pending,
  });

  @override
  Future<String> requestPasswordReset(String email) async {
    requestedEmails.add(email);
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return result;
  }
}

void main() {
  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('renders reset password screen elements correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email to receive a reset link'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.textContaining('Tautan reset kata sandi akan dikirimkan'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Kembali ke Login'), findsOneWidget);
    });

    testWidgets('validates empty email on submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('validates invalid email format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'notanemail');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('submit email valid memanggil API dan menampilkan dialog sukses berisi pesan backend', (tester) async {
      final repo = _FakePasswordResetRepository(
        result: 'Link reset sudah dikirim ke user@example.com',
      );
      await tester.pumpWidget(
        MaterialApp(home: ResetPasswordScreen(repository: repo)),
      );

      await tester.enterText(find.byType(TextField), '  user@example.com ');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(repo.requestedEmails, ['  user@example.com ']);
      expect(find.text('Link reset sudah dikirim ke user@example.com'), findsOneWidget);
    });

    testWidgets('tombol menampilkan loading dan mengabaikan tap ganda selama request', (tester) async {
      final completer = Completer<String>();
      final repo = _FakePasswordResetRepository(pending: completer);
      await tester.pumpWidget(
        MaterialApp(home: ResetPasswordScreen(repository: repo)),
      );

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(repo.requestedEmails, hasLength(1));

      completer.complete('OK');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('error API menampilkan pesan dari backend pada dialog error', (tester) async {
      final repo = _FakePasswordResetRepository(
        error: const ApiException(
          message: 'Terlalu banyak percobaan, coba lagi nanti',
          statusCode: 429,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: ResetPasswordScreen(repository: repo)),
      );

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Terlalu banyak percobaan, coba lagi nanti'), findsOneWidget);
      expect(find.text('Link reset sudah dikirim'), findsNothing);
    });

    testWidgets('tapping Back to Login pops back to previous route', (tester) async {
      final router = GoRouter(
        initialLocation: Routes.LOGIN,
        routes: [
          GoRoute(
            path: Routes.LOGIN,
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push(Routes.RESET),
                child: const Text('Go to Reset'),
              ),
            ),
          ),
          GoRoute(
            path: Routes.RESET,
            builder: (context, state) => const ResetPasswordScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Navigate from LOGIN to RESET
      await tester.tap(find.text('Go to Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);

      // Tap Back to Login
      await tester.tap(find.text('Kembali ke Login'));
      await tester.pumpAndSettle();

      // Successfully popped back to LOGIN screen
      expect(find.text('Go to Reset'), findsOneWidget);
      expect(find.text('Reset Password'), findsNothing);
    });
  });
}
