import 'package:go_router/go_router.dart';
import 'package:hris_flutter/splash_screen_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash_screen',
    routes: [
      GoRoute(
        path: '/splash_screen',
        name: 'splash_screen',
        builder: (context, state) {
          return SplashScreenPage();
        },
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
