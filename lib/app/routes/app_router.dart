import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/announcement_detail_screen.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/announcement_list_screen.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/pdf_viewer_screen.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_detail_screen.dart';
import 'package:hris_flutter/features/activity/presentation/pages/activity_screen.dart';
import 'package:hris_flutter/features/activity/presentation/pages/create_activity_screen.dart';
import 'package:hris_flutter/features/activity/presentation/pages/create_plan_activity_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_detail_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_logs_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_request_detail_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_requests_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/employee_attendance_logs_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/live_attendance_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/schedule_attendance_screen.dart';
import 'package:hris_flutter/features/auth/presentation/pages/login_screen.dart';
import 'package:hris_flutter/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:hris_flutter/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/presentation/pages/change_password_screen.dart';
import 'package:hris_flutter/features/employee/presentation/pages/coworker_list_screen.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_detail_screen.dart';
import 'package:hris_flutter/features/employee/presentation/pages/employee_directory_screen.dart';
import 'package:hris_flutter/features/leave/presentation/pages/create_leave_screen.dart';
import 'package:hris_flutter/features/leave/presentation/pages/leave_detail_screen.dart';
import 'package:hris_flutter/features/leave/presentation/pages/leave_screen.dart';
import 'package:hris_flutter/features/notification/presentation/pages/notification_screen.dart';
import 'package:hris_flutter/features/notification/presentation/pages/notification_settings_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/create_overtime_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/overtime_detail_screen.dart';
import 'package:hris_flutter/features/overtime/presentation/pages/overtime_requests_screen.dart';
import 'package:hris_flutter/features/splash/presentation/pages/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/features/warning_letter/data/repositories/warning_letter_repository_impl.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_bloc.dart';
import 'package:hris_flutter/features/warning_letter/presentation/pages/create_warning_letter_screen.dart';
import 'package:hris_flutter/features/warning_letter/presentation/pages/warning_letter_detail_screen.dart';
import 'package:hris_flutter/features/warning_letter/presentation/pages/warning_letter_screen.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:hris_flutter/features/schedule/presentation/pages/employee_schedule_select_screen.dart';
import 'package:hris_flutter/features/schedule/presentation/pages/work_schedule_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/cash_advance_detail_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/create_cash_advance_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/create_reimbursement_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/disburse_action_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/expenses_list_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/reimbursement_detail_screen.dart';
import 'package:hris_flutter/features/resignation/presentation/pages/resignation_screen.dart';

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

      // 3b. Change Password Screen
      GoRoute(
        path: Routes.CHANGE_PASSWORD,
        name: Routes.CHANGE_PASSWORD,
        builder: (context, state) => const ChangePasswordScreen(),
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
          return const EmployeeDetailScreen(isFromDirectory: false);
        },
      ),

      // 7. Coworker List Screen
      GoRoute(
        path: Routes.COWORKER_LIST,
        name: Routes.COWORKER_LIST,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is CoworkerListArgs) {
            return CoworkerListScreen(args: extra);
          }
          return const CoworkerListScreen();
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

      // 9b. Create Activity Plan Screen (Superior creates plan for subordinate)
      GoRoute(
        path: Routes.CREATE_ACTIVITY_PLAN,
        name: Routes.CREATE_ACTIVITY_PLAN,
        builder: (context, state) => const CreatePlanActivityScreen(),
      ),

      // 10. Attendance & Check-In Screen (Oasish Google Stitch)
      GoRoute(
        path: Routes.ATTENDANCE,
        name: Routes.ATTENDANCE,
        builder: (context, state) => const AttendanceScreen(),
      ),

      GoRoute(
        path: Routes.ATTENDANCE_LOGS,
        name: Routes.ATTENDANCE_LOGS,
        builder: (context, state) {
          final extra = state.extra;
          bool redirectToDashboard = false;
          if (extra is Map<String, dynamic>) {
            redirectToDashboard =
                extra['redirectToDashboardOnBack'] as bool? ?? false;
          }
          return AttendanceLogsScreen(
            redirectToDashboardOnBack: redirectToDashboard,
          );
        },
      ),

      GoRoute(
        path: Routes.EMPLOYEE_ATTENDANCE_LOGS,
        name: Routes.EMPLOYEE_ATTENDANCE_LOGS,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is EmployeeDirectoryItem) {
            return EmployeeAttendanceLogsScreen(employee: extra);
          }
          return const Scaffold(
            body: Center(child: Text('Data pegawai tidak ditemukan')),
          );
        },
      ),

      // 13. Attendance Detail Screen (Google Stitch)
      GoRoute(
        path: Routes.ATTENDANCE_DETAIL,
        name: Routes.ATTENDANCE_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String attendanceId = '';
          if (extra is String) {
            attendanceId = extra;
          } else if (state.uri.queryParameters.containsKey('id')) {
            attendanceId = state.uri.queryParameters['id']!;
          }
          return AttendanceDetailScreen(attendanceId: attendanceId);
        },
      ),

      // 13b. Attendance Requests / Absen Luar Kantor Screen (Google Stitch)
      GoRoute(
        path: Routes.ATTENDANCE_REQUESTS,
        name: Routes.ATTENDANCE_REQUESTS,
        builder: (context, state) => const AttendanceRequestsScreen(),
      ),

      // 13c. Attendance Request Detail Screen (Google Stitch Outside Attendance Request Detail)
      GoRoute(
        path: Routes.ATTENDANCE_REQUEST_DETAIL,
        name: Routes.ATTENDANCE_REQUEST_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String id = '';
          bool isApprover = false;

          if (extra is Map<String, dynamic>) {
            id = extra['id']?.toString() ?? '';
            isApprover = extra['isApprover'] as bool? ?? false;
          } else if (extra is String) {
            id = extra;
          }

          if (id.isEmpty && state.uri.queryParameters.containsKey('id')) {
            id = state.uri.queryParameters['id']!;
          }
          if (state.uri.queryParameters.containsKey('isApprover')) {
            isApprover = state.uri.queryParameters['isApprover'] == 'true';
          }

          return AttendanceRequestDetailScreen(id: id, isApprover: isApprover);
        },
      ),

      // 13c. Live Attendance Screen (Google Stitch Outside Office Live Attendance)
      GoRoute(
        path: Routes.LIVE_ATTENDANCE,
        name: Routes.LIVE_ATTENDANCE,
        builder: (context, state) {
          final extra = state.extra;
          String? initialMethod;
          if (extra is String) {
            initialMethod = extra;
          } else if (extra is Map<String, dynamic>) {
            initialMethod = extra['attendanceMethod'] as String?;
          }
          return LiveAttendanceScreen(initialMethod: initialMethod);
        },
      ),

      // 13d. Schedule Attendance Screen (Google Stitch Outside Office Schedule Attendance)
      GoRoute(
        path: Routes.SCHEDULE_ATTENDANCE,
        name: Routes.SCHEDULE_ATTENDANCE,
        builder: (context, state) {
          final extra = state.extra;
          String? initialMethod;
          if (extra is String) {
            initialMethod = extra;
          } else if (extra is Map<String, dynamic>) {
            initialMethod = extra['attendanceMethod'] as String?;
          }
          return ScheduleAttendanceScreen(initialMethod: initialMethod);
        },
      ),

      // 14. Leave & Time Off Screen (Google Stitch slice)
      GoRoute(
        path: Routes.LEAVE,
        name: Routes.LEAVE,
        builder: (context, state) => const LeaveScreen(),
      ),

      // 15. Leave Request Detail Screen (Google Stitch slice)
      GoRoute(
        path: Routes.LEAVE_DETAIL,
        name: Routes.LEAVE_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String id = '';
          bool isApprover = false;

          if (extra is Map<String, dynamic>) {
            id = extra['id']?.toString() ?? '';
            isApprover = extra['isApprover'] as bool? ?? false;
          } else if (extra is String) {
            id = extra;
          }

          if (id.isEmpty && state.uri.queryParameters.containsKey('id')) {
            id = state.uri.queryParameters['id']!;
          }
          if (state.uri.queryParameters.containsKey('isApprover')) {
            isApprover = state.uri.queryParameters['isApprover'] == 'true';
          }

          return LeaveDetailScreen(id: id, isApprover: isApprover);
        },
      ),

      // 16. Create Leave Screen
      GoRoute(
        path: Routes.CREATE_LEAVE,
        name: Routes.CREATE_LEAVE,
        builder: (context, state) => const CreateLeaveScreen(),
      ),

      // 17. Overtime Requests Screen (Google Stitch slice - Team Overtime List)
      GoRoute(
        path: Routes.OVERTIME,
        name: Routes.OVERTIME,
        builder: (context, state) => const OvertimeRequestsScreen(),
      ),

      // 18. Create Overtime Screen (Google Stitch slice)
      GoRoute(
        path: Routes.CREATE_OVERTIME,
        name: Routes.CREATE_OVERTIME,
        builder: (context, state) => const CreateOvertimeScreen(),
      ),

      // 19. Overtime Request Detail Screen (Google Stitch slice)
      GoRoute(
        path: Routes.OVERTIME_DETAIL,
        name: Routes.OVERTIME_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String id = '';
          bool isApprover = false;

          if (extra is Map<String, dynamic>) {
            id = extra['id']?.toString() ?? '';
            isApprover = extra['isApprover'] as bool? ?? false;
          } else if (extra is String) {
            id = extra;
          }

          if (id.isEmpty && state.uri.queryParameters.containsKey('id')) {
            id = state.uri.queryParameters['id']!;
          }
          if (state.uri.queryParameters.containsKey('isApprover')) {
            isApprover = state.uri.queryParameters['isApprover'] == 'true';
          }

          return OvertimeDetailScreen(id: id, isApprover: isApprover);
        },
      ),

      // 20. Notification Screen (Notification Center)
      GoRoute(
        path: Routes.NOTIFICATIONS,
        name: Routes.NOTIFICATIONS,
        builder: (context, state) => const NotificationScreen(),
      ),

      // 20b. Notification Settings Screen (Stitch M3 Teal Oasis)
      GoRoute(
        path: Routes.NOTIFICATION_SETTINGS,
        name: Routes.NOTIFICATION_SETTINGS,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // 21. Announcement List Screen (Google Stitch M3 Teal Oasis)
      GoRoute(
        path: Routes.ANNOUNCEMENT,
        name: Routes.ANNOUNCEMENT,
        builder: (context, state) => const AnnouncementListScreen(),
      ),

      // 22. Announcement Detail Screen
      GoRoute(
        path: Routes.ANNOUNCEMENT_DETAIL,
        name: Routes.ANNOUNCEMENT_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String id = '';
          if (extra is String) {
            id = extra;
          } else if (extra is Map<String, dynamic>) {
            id = extra['id']?.toString() ?? '';
          }
          if (id.isEmpty && state.uri.queryParameters.containsKey('id')) {
            id = state.uri.queryParameters['id']!;
          }
          return AnnouncementDetailScreen(id: id);
        },
      ),

      // 23. PDF Viewer Screen
      GoRoute(
        path: Routes.PDF_VIEWER,
        name: Routes.PDF_VIEWER,
        builder: (context, state) {
          final extra = state.extra;
          String title = 'Dokumen PDF';
          String fileName = 'document.pdf';
          String fileUrl = '';

          if (extra is Map<String, dynamic>) {
            title = extra['title']?.toString() ?? title;
            fileName = extra['fileName']?.toString() ?? fileName;
            fileUrl = extra['fileUrl']?.toString() ?? '';
          }

          if (fileUrl.isEmpty &&
              state.uri.queryParameters.containsKey('fileUrl')) {
            fileUrl = state.uri.queryParameters['fileUrl']!;
          }

          return PdfViewerScreen(
            title: title,
            fileName: fileName,
            fileUrl: fileUrl,
          );
        },
      ),

      // 24. Warning Letter Screen (Google Stitch M3 Teal Oasis)
      GoRoute(
        path: Routes.WARNING_LETTER,
        name: Routes.WARNING_LETTER,
        builder: (context, state) => const WarningLetterScreen(),
      ),

      // 25. Create Warning Letter Form Screen (Google Stitch M3 Teal Oasis)
      GoRoute(
        path: Routes.CREATE_WARNING_LETTER,
        name: Routes.CREATE_WARNING_LETTER,
        builder: (context, state) => const CreateWarningLetterScreen(),
      ),

      // 26. Warning Letter Detail Screen (Google Stitch M3 Teal Oasis)
      GoRoute(
        path: Routes.WARNING_LETTER_DETAIL,
        name: Routes.WARNING_LETTER_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String id = '';

          if (extra is Map<String, dynamic>) {
            id = extra['id']?.toString() ?? '';
          } else if (extra is String) {
            id = extra;
          }

          if (id.isEmpty && state.uri.queryParameters.containsKey('id')) {
            id = state.uri.queryParameters['id']!;
          }

          return BlocProvider<WarningLetterDetailBloc>(
            create: (context) => WarningLetterDetailBloc(
              repository: WarningLetterRepositoryImpl(),
            ),
            child: WarningLetterDetailScreen(id: id),
          );
        },
      ),

      // 27. Work Schedule Screen (Jadwal Kerja Pegawai / Diri Sendiri)
      GoRoute(
        path: Routes.WORK_SCHEDULE,
        name: Routes.WORK_SCHEDULE,
        builder: (context, state) {
          final employeeId = state.uri.queryParameters['employeeId'];
          WorkScheduleEmployee? preview;
          final extra = state.extra;
          if (extra is WorkScheduleEmployee) {
            preview = extra;
          }
          return WorkScheduleScreen(
            employeeId: employeeId,
            employeePreview: preview,
          );
        },
      ),

      // 28. Employee Schedule Select Screen
      GoRoute(
        path: Routes.EMPLOYEE_SCHEDULE_SELECT,
        name: Routes.EMPLOYEE_SCHEDULE_SELECT,
        builder: (context, state) => const EmployeeScheduleSelectScreen(),
      ),

      // 29. Expenses Feed (Reimbursement & Kasbon)
      GoRoute(
        path: Routes.EXPENSES,
        name: Routes.EXPENSES,
        builder: (context, state) => const ExpensesListScreen(),
      ),

      // 30. Reimbursement Detail Screen
      GoRoute(
        path: Routes.REIMBURSEMENT_DETAIL,
        name: Routes.REIMBURSEMENT_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String id = '';
          if (extra is String) {
            id = extra;
          } else if (extra is Map<String, dynamic>) {
            id = extra['id']?.toString() ?? '';
          }
          if (id.isEmpty && state.uri.queryParameters.containsKey('id')) {
            id = state.uri.queryParameters['id']!;
          }
          return ReimbursementDetailScreen(id: id);
        },
      ),

      // 31. Create Reimbursement Form Screen
      GoRoute(
        path: Routes.CREATE_REIMBURSEMENT,
        name: Routes.CREATE_REIMBURSEMENT,
        builder: (context, state) {
          final extra = state.extra;
          String? cashAdvanceId;
          if (extra is String) {
            cashAdvanceId = extra;
          } else if (extra is Map<String, dynamic>) {
            cashAdvanceId = extra['cashAdvanceId']?.toString();
          }
          return CreateReimbursementScreen(
            initialCashAdvanceId: cashAdvanceId,
          );
        },
      ),

      // 32. Cash Advance Detail Screen
      GoRoute(
        path: Routes.CASH_ADVANCE_DETAIL,
        name: Routes.CASH_ADVANCE_DETAIL,
        builder: (context, state) {
          final extra = state.extra;
          String id = '';
          if (extra is String) {
            id = extra;
          } else if (extra is Map<String, dynamic>) {
            id = extra['id']?.toString() ?? '';
          }
          if (id.isEmpty && state.uri.queryParameters.containsKey('id')) {
            id = state.uri.queryParameters['id']!;
          }
          return CashAdvanceDetailScreen(id: id);
        },
      ),

      // 33. Create Cash Advance Form Screen
      GoRoute(
        path: Routes.CREATE_CASH_ADVANCE,
        name: Routes.CREATE_CASH_ADVANCE,
        builder: (context, state) => const CreateCashAdvanceScreen(),
      ),

      // 34. Disburse Action Screen (Multi-Method Kasir)
      GoRoute(
        path: Routes.DISBURSE_ACTION,
        name: Routes.DISBURSE_ACTION,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is DisburseScreenArgs) {
            return DisburseActionScreen(args: extra);
          }
          return DisburseActionScreen(
            args: DisburseScreenArgs(
              claimId: extra?.toString() ?? '',
              claimNumber: '',
              amount: 0,
              employeeName: '',
            ),
          );
        },
      ),

      // 35. Resignation Hub & Live Offboarding Tracking Screen
      GoRoute(
        path: Routes.RESIGNATION,
        name: Routes.RESIGNATION,
        builder: (context, state) => const ResignationScreen(),
      ),
    ],
    redirect: (context, state) {
      return null;
    },
  );
}
