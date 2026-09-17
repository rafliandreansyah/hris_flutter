import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';

class TestAuthBloc extends AuthBloc {
  TestAuthBloc() : super();

  void emitState(AuthState state) {
    emit(state);
  }
}

void main() {
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
  });

  testWidgets('displays pro_dialog error dialog on AuthFailure and can dismiss it', (
    tester,
  ) async {
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
}
