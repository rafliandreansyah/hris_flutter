import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';

import 'attendance_bloc_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AttendanceBloc Work Location Retention on Reload Tests', () {
    test('preserves user-selected work location when AttendanceFetchRequested(isRefresh: true) is called', () async {
      const defaultLoc = WorkLocationItem(
        id: 'loc-default',
        name: 'Headquarters',
        address: 'HQ Street 1',
        latitude: -6.2000,
        longitude: 106.8000,
        radius: 100,
      );

      const secondaryLoc = WorkLocationItem(
        id: 'loc-branch',
        name: 'Branch Office',
        address: 'Branch Avenue 2',
        latitude: -6.3000,
        longitude: 106.9000,
        radius: 75,
      );

      final initialData = AttendanceTodayData(
        serverTime: DateTime(2026, 9, 16, 9, 0, 0),
        selectedWorkLocation: defaultLoc,
        availableWorkLocations: const [defaultLoc, secondaryLoc],
        officeName: defaultLoc.name,
        officeDetail: defaultLoc.address,
        officeLatitude: defaultLoc.latitude!,
        officeLongitude: defaultLoc.longitude!,
        geofenceRadiusMeters: defaultLoc.radius,
      );

      final repo = MockAttendanceRepository(initialData: initialData);
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      // 1. Fetch initial data
      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, isA<AttendanceLoaded>());
      var loaded = bloc.state as AttendanceLoaded;
      expect(loaded.data.selectedWorkLocation?.id, 'loc-default');

      // 2. User selects secondary work location
      bloc.add(const AttendanceWorkLocationChanged(secondaryLoc));
      await Future.delayed(const Duration(milliseconds: 50));

      loaded = bloc.state as AttendanceLoaded;
      expect(loaded.data.selectedWorkLocation?.id, 'loc-branch');
      expect(loaded.data.officeName, 'Branch Office');
      expect(loaded.data.officeLatitude, -6.3000);

      // 3. User performs swipe-refresh / reload
      // Even though repo.getTodayAttendance() returns initialData with 'loc-default' as selectedWorkLocation,
      // the bloc should retain 'loc-branch' that the user picked!
      bloc.add(const AttendanceFetchRequested(isRefresh: true));
      await Future.delayed(const Duration(milliseconds: 50));

      loaded = bloc.state as AttendanceLoaded;
      expect(loaded.data.selectedWorkLocation?.id, 'loc-branch');
      expect(loaded.data.officeName, 'Branch Office');
      expect(loaded.data.officeLatitude, -6.3000);
      expect(loaded.data.officeLongitude, 106.9000);
      expect(loaded.data.geofenceRadiusMeters, 75.0);

      await bloc.close();
    });

    test('preserves user-selected work location coordinates on Clock In and emits attendanceSuccess with date and time', () async {
      const defaultLoc = WorkLocationItem(
        id: 'loc-default',
        name: 'Headquarters',
        address: 'HQ Street 1',
        latitude: -6.2000,
        longitude: 106.8000,
        radius: 100,
      );

      const secondaryLoc = WorkLocationItem(
        id: 'loc-branch',
        name: 'Branch Office',
        address: 'Branch Avenue 2',
        latitude: -6.3000,
        longitude: 106.9000,
        radius: 75,
      );

      final initialData = AttendanceTodayData(
        serverTime: DateTime(2026, 9, 16, 9, 0, 0),
        selectedWorkLocation: defaultLoc,
        availableWorkLocations: const [defaultLoc, secondaryLoc],
        officeName: defaultLoc.name,
        officeDetail: defaultLoc.address,
        officeLatitude: defaultLoc.latitude!,
        officeLongitude: defaultLoc.longitude!,
        geofenceRadiusMeters: defaultLoc.radius,
      );

      final repo = MockAttendanceRepository(initialData: initialData);
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // User selects secondary location
      bloc.add(const AttendanceWorkLocationChanged(secondaryLoc));
      await Future.delayed(const Duration(milliseconds: 50));

      // User performs Clock In
      bloc.add(
        const AttendanceClockInSubmitted(
          latitude: -6.3000,
          longitude: 106.9000,
          address: 'Branch Avenue 2',
          attendanceMethod: 'photo',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = bloc.state as AttendanceLoaded;
      // Must retain chosen work location and its office coordinates
      expect(loaded.data.selectedWorkLocation?.id, 'loc-branch');
      expect(loaded.data.officeName, 'Branch Office');
      expect(loaded.data.officeLatitude, -6.3000);
      expect(loaded.data.officeLongitude, 106.9000);
      expect(loaded.data.geofenceRadiusMeters, 75.0);

      // Must emit attendanceSuccess info
      expect(loaded.attendanceSuccess, isNotNull);
      expect(loaded.attendanceSuccess?.attendanceType, 'in');
      expect(loaded.attendanceSuccess?.locationName, 'Branch Office');
      expect(loaded.attendanceSuccess?.formattedTime, contains('08:45'));
      expect(loaded.attendanceSuccess?.formattedDate, isNotEmpty);

      await bloc.close();
    });

    test('preserves user-selected work location coordinates on Clock Out and emits attendanceSuccess with date and time', () async {
      const defaultLoc = WorkLocationItem(
        id: 'loc-default',
        name: 'Headquarters',
        address: 'HQ Street 1',
        latitude: -6.2000,
        longitude: 106.8000,
        radius: 100,
      );

      const secondaryLoc = WorkLocationItem(
        id: 'loc-branch',
        name: 'Branch Office',
        address: 'Branch Avenue 2',
        latitude: -6.3000,
        longitude: 106.9000,
        radius: 75,
      );

      final initialData = AttendanceTodayData(
        serverTime: DateTime(2026, 9, 16, 18, 0, 0),
        inTime: '08:45',
        selectedWorkLocation: defaultLoc,
        availableWorkLocations: const [defaultLoc, secondaryLoc],
        officeName: defaultLoc.name,
        officeDetail: defaultLoc.address,
        officeLatitude: defaultLoc.latitude!,
        officeLongitude: defaultLoc.longitude!,
        geofenceRadiusMeters: defaultLoc.radius,
      );

      final repo = MockAttendanceRepository(initialData: initialData);
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);

      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // User selects secondary location
      bloc.add(const AttendanceWorkLocationChanged(secondaryLoc));
      await Future.delayed(const Duration(milliseconds: 50));

      // User performs Clock Out
      bloc.add(
        const AttendanceClockOutSubmitted(
          latitude: -6.3000,
          longitude: 106.9000,
          address: 'Branch Avenue 2',
          attendanceMethod: 'photo',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final loaded = bloc.state as AttendanceLoaded;
      // Must retain chosen work location and its office coordinates
      expect(loaded.data.selectedWorkLocation?.id, 'loc-branch');
      expect(loaded.data.officeName, 'Branch Office');
      expect(loaded.data.officeLatitude, -6.3000);
      expect(loaded.data.officeLongitude, 106.9000);
      expect(loaded.data.geofenceRadiusMeters, 75.0);

      // Must emit attendanceSuccess info
      expect(loaded.attendanceSuccess, isNotNull);
      expect(loaded.attendanceSuccess?.attendanceType, 'out');
      expect(loaded.attendanceSuccess?.locationName, 'Branch Office');
      expect(loaded.attendanceSuccess?.formattedTime, contains('18:00'));
      expect(loaded.attendanceSuccess?.formattedDate, isNotEmpty);

      await bloc.close();
    });

    test('AttendanceClockTicked following clock-in automatically clears attendanceSuccess as a one-shot event', () async {
      const defaultLoc = WorkLocationItem(
        id: 'loc-default',
        name: 'Headquarters',
        address: 'HQ Street 1',
        latitude: -6.2000,
        longitude: 106.8000,
        radius: 100,
      );

      final initialData = AttendanceTodayData(
        serverTime: DateTime(2026, 9, 16, 9, 0, 0),
        selectedWorkLocation: defaultLoc,
        availableWorkLocations: const [defaultLoc],
        officeName: defaultLoc.name,
        officeDetail: defaultLoc.address,
        officeLatitude: defaultLoc.latitude!,
        officeLongitude: defaultLoc.longitude!,
        geofenceRadiusMeters: defaultLoc.radius,
      );

      final repo = MockAttendanceRepository(initialData: initialData);
      final bloc = AttendanceBloc(repository: repo, autoStartClock: false);
      bloc.add(const AttendanceFetchRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(
        const AttendanceClockInSubmitted(
          latitude: -6.2000,
          longitude: 106.8000,
          attendanceMethod: 'photo',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      var state = bloc.state as AttendanceLoaded;
      expect(state.attendanceSuccess, isNotNull);

      // Now dispatch clock tick (simulating the background 1-second timer)
      bloc.add(AttendanceClockTicked(state.currentClockTime.add(const Duration(seconds: 1))));
      await Future.delayed(const Duration(milliseconds: 50));

      state = bloc.state as AttendanceLoaded;
      // attendanceSuccess must be null, preventing flickering/re-showing dialogs
      expect(state.attendanceSuccess, isNull);

      await bloc.close();
    });
  });
}
