import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/login/presentation/pages/login_screen.dart';
import 'package:hris_flutter/features/reset_password/presentation/pages/reset_password_screen.dart';
import 'package:hris_flutter/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.SPLASH,
    routes: [
      // 1. Splash Screen
      GoRoute(
        path: Routes.SPLASH,
        name: Routes.SPLASH,
        builder: (context, state) => const SplashScreenPage(),
      ),

      // 2. Login Screen (Sejajar dengan Splash)
      GoRoute(
        path: Routes.LOGIN,
        name: Routes.LOGIN,
        builder: (context, state) => const LoginScreen(),
      ),

      // 3. Reset Password Screen (Sejajar dengan Login)
      GoRoute(
        path: Routes.RESET,
        name: Routes.RESET,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Jika nanti ada Main/Dashboard dengan BottomNavBar, baru pakai ShellRoute di sini
    ],
    redirect: (context, state) {
      return null;
    },
  );
}
