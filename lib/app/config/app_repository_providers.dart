import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/announcement/data/repositories/announcement_repository_impl.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_request_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:hris_flutter/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/data/repositories/organization_filter_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/warning_letter/data/repositories/warning_letter_repository_impl.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';

/// Sentralisasi Dependency Injection (DI) berbasis [RepositoryProvider] bawaan `flutter_bloc`.
///
/// Menyediakan singleton/lazy-loaded repository di root aplikasi tanpa memerlukan
/// library tambahan eksternal (zero dependency).
class AppRepositoryProviders {
  static List<RepositoryProvider> get providers => [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(),
        ),
        RepositoryProvider<LeaveRepository>(
          create: (_) => LeaveRepositoryImpl(),
        ),
        RepositoryProvider<OvertimeRepository>(
          create: (_) => OvertimeRepositoryImpl(),
        ),
        RepositoryProvider<AttendanceRepository>(
          create: (_) => AttendanceRepositoryImpl(),
        ),
        RepositoryProvider<AttendanceRequestRepository>(
          create: (_) => AttendanceRequestRepositoryImpl(),
        ),
        RepositoryProvider<OrganizationFilterRepository>(
          create: (_) => OrganizationFilterRepositoryImpl(),
        ),
        RepositoryProvider<EmployeeRepository>(
          create: (_) => EmployeeRepositoryImpl(),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (_) => NotificationRepositoryImpl(),
        ),
        RepositoryProvider<ActivityRepository>(
          create: (_) => ActivityRepositoryImpl(),
        ),
        RepositoryProvider<WarningLetterRepository>(
          create: (_) => WarningLetterRepositoryImpl(),
        ),
        RepositoryProvider<AnnouncementRepository>(
          create: (_) => AnnouncementRepositoryImpl(),
        ),
        RepositoryProvider<DashboardRepository>(
          create: (_) => DashboardRepositoryImpl(),
        ),
      ];
}
