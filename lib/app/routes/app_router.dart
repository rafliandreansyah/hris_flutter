import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';
import 'package:hris_flutter/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';
import 'package:hris_flutter/features/splash/presentation/pages/splash_screen.dart';

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

      // 2. Login Screen
      GoRoute(
        path: Routes.LOGIN,
        name: Routes.LOGIN,
        builder: (context, state) => const LoginScreen(),
      ),

      // 3. Reset Password Screen
      GoRoute(
        path: Routes.RESET,
        name: Routes.RESET,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // 4. Dashboard / Home Screen
      GoRoute(
        path: Routes.DASHBOARD,
        name: Routes.DASHBOARD,
        builder: (context, state) => const DashboardScreen(),
      ),

      // 5. Employee Directory Screen
      GoRoute(
        path: Routes.EMPLOYEE_DIRECTORY,
        name: Routes.EMPLOYEE_DIRECTORY,
        builder: (context, state) => const EmployeeDirectoryScreen(),
      ),

      // 6. Employee Detail Screen
      GoRoute(
        path: Routes.EMPLOYEE_DETAIL,
        name: Routes.EMPLOYEE_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is EmployeeDirectoryItem) {
            return EmployeeDetailScreen(
              employee: extra,
              employeeId: extra.rawId ?? extra.id,
              isFromDirectory: true,
            );
          } else if (extra is String) {
            return EmployeeDetailScreen(
              employeeId: extra,
              isFromDirectory: true,
            );
          }
          return const EmployeeDetailScreen(
            isFromDirectory: false,
          );
        },
      ),
    ],
    redirect: (context, state) {
      return null;
    },
  );
}
