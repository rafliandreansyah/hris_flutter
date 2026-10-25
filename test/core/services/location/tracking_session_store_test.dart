import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/services/location/tracking_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const snapshot = TrackingSessionSnapshot(
    onActivity: true,
    attendanceId: 'att-1',
    activityId: 'act-1',
    activityTitle: 'Survey Lokasi',
    attendanceIntervalSeconds: 600,
    activityIntervalSeconds: 120,
  );

  test('save menulis snapshot & flag aktif yang dibaca kode native', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TrackingSessionStore();

    await store.save(snapshot);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(TrackingSessionStore.activeFlagKey), isTrue);
    expect(await store.load(), snapshot);
  });

  test('clear menghapus snapshot dan mematikan flag', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TrackingSessionStore();
    await store.save(snapshot);

    await store.clear();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(TrackingSessionStore.activeFlagKey), isFalse);
    expect(await store.load(), isNull);
  });

  test('data rusak -> load mengembalikan null', () async {
    SharedPreferences.setMockInitialValues({
      TrackingSessionStore.snapshotKey: '{bukan json',
    });

    expect(await TrackingSessionStore().load(), isNull);
  });
}
