import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_detail_screen.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_screen.dart';
import 'package:hris_flutter/features/activity/presentation/pages/create_activity_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';
import 'package:hris_flutter/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';
import 'package:hris_flutter/features/splash/presentation/pages/splash_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
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

      // 7. Activity Screen (Activity Reports / Team Activity Feed)
      GoRoute(
        path: Routes.ACTIVITY,
        name: Routes.ACTIVITY,
        builder: (context, state) => const ActivityScreen(),
      ),

      // 8. Activity Detail Screen (Activity Detail & Verification)
      GoRoute(
        path: Routes.ACTIVITY_DETAIL,
        name: Routes.ACTIVITY_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ActivityItem) {
            return ActivityDetailScreen(activity: extra);
          } else if (extra is String) {
            return ActivityDetailScreen(activityId: extra);
          }
          return const ActivityDetailScreen();
        },
      ),

      // 9. Create Activity Form Screen
      GoRoute(
        path: Routes.CREATE_ACTIVITY,
        name: Routes.CREATE_ACTIVITY,
        builder: (context, state) => const CreateActivityScreen(),
      ),

      // 10. Attendance & Check-In Screen (Oasish Google Stitch)
      GoRoute(
        path: Routes.ATTENDANCE,
        name: Routes.ATTENDANCE,
        builder: (context, state) => const AttendanceScreen(),
      ),
    ],
    redirect: (context, state) {
      return null;
    },
  );
}
