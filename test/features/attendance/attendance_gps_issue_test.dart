import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';

class _NoopRepository implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _office = WorkLocationItem(
  id: 'office',
  name: 'HQ',
  radius: 50,
  latitude: -6.2253,
  longitude: 106.8097,
);

AttendanceLoaded _loaded({double? lat, double? lng}) => AttendanceLoaded(
      data: AttendanceTodayData(
        serverTime: DateTime(2026, 8, 27, 8, 45),
        selectedWorkLocation: _office,
      ),
      currentClockTime: DateTime(2026, 8, 27, 8, 45),
      userLatitude: lat,
      userLongitude: lng,
    );

void main() {
  group('AttendanceLoaded.distanceToOfficeMeters', () {
    test('null saat GPS belum didapat', () {
      expect(_loaded().distanceToOfficeMeters, isNull);
    });

    test('null untuk lokasi kerja isAnyWhere', () {
      final state = AttendanceLoaded(
        data: AttendanceTodayData(
          serverTime: DateTime(2026, 8, 27),
          selectedWorkLocation:
              const WorkLocationItem(id: 'any', name: 'Anywhere', isAnyWhere: true),
        ),
        currentClockTime: DateTime(2026, 8, 27),
        userLatitude: -6.2,
        userLongitude: 106.8,
      );
      expect(state.distanceToOfficeMeters, isNull);
    });

    test('menghitung jarak ke kantor dalam meter', () {
      final d = _loaded(lat: -6.3253, lng: 106.8097).distanceToOfficeMeters!;
      // ±0.1 derajat lintang ≈ 11.1 km
      expect(d, inInclusiveRange(11000, 11300));
    });
  });

  group('AttendanceGpsIssueReported', () {
    test('menyimpan kendala GPS lalu dikosongkan saat lokasi berhasil didapat',
        () async {
      final bloc =
          AttendanceBloc(repository: _NoopRepository(), autoStartClock: false);
      addTearDown(bloc.close);
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      bloc.emit(_loaded());

      final states = <AttendanceLoaded>[];
      final sub = bloc.stream
          .where((s) => s is AttendanceLoaded)
          .cast<AttendanceLoaded>()
          .listen(states.add);

      bloc.add(const AttendanceGpsIssueReported(
          AttendanceGpsIssue.serviceDisabled));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const AttendanceLocationUpdated(
        latitude: -6.2253,
        longitude: 106.8097,
        accuracy: 5,
        isInsideGeofence: true,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(states, hasLength(2));
      expect(states[0].gpsIssue, AttendanceGpsIssue.serviceDisabled);
      expect(states[0].isGpsAcquired, isFalse);
      expect(states[1].gpsIssue, isNull);
      expect(states[1].isGpsAcquired, isTrue);
    });
  });
}
