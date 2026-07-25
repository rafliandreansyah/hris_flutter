import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/login/presentation/pages/login_screen.dart';
import 'package:hris_flutter/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.SPLASH,
    routes: [
      GoRoute(
        path: Routes.SPLASH,
        name: Routes.SPLASH,
        builder: (context, state) {
          return SplashScreenPage();
        },
        routes: [
          GoRoute(
            path: Routes.LOGIN,
            name: Routes.LOGIN,
            builder: (context, state) {
              return const LoginScreen();
            },
          ),
        ],
      ),
      // Contoh Nested/Shell Route atau Route lainnya
    ],
    // Logika Redirect/Guard berdasarkan state authentication
    redirect: (context, state) {
      // Misal mengecek auth status
      return null;
    },
  );
}
