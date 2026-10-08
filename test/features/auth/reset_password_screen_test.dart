import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/auth/presentation/pages/reset_password_screen.dart';

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
      expect(find.text('Back to Login'), findsOneWidget);
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

    testWidgets('submits valid email, displays loading and shows success SnackBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump(); // Start async process

      // Verify button shows loading
      final appButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(appButton.isLoading, isTrue);

      // Advance clock past the 1-second simulated delay
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.text('Tautan reset kata sandi telah dikirim ke email Anda!'),
        findsOneWidget,
      );
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
      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      // Successfully popped back to LOGIN screen
      expect(find.text('Go to Reset'), findsOneWidget);
      expect(find.text('Reset Password'), findsNothing);
    });
  });
}
