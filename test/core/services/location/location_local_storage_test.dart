import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/services/location/location_local_storage.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';

void main() {
  late LocationLocalStorage storage;
  late Directory tempDir;
  late File testFile;

  setUp(() {
    storage = LocationLocalStorage.instance;
    tempDir = Directory.systemTemp.createTempSync('hris_tracking_test_');
    testFile = File('${tempDir.path}/test_location_buffer.json');
    storage.customStoragePath = testFile.path;
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
    storage.customStoragePath = null;
  });

  group('LocationLocalStorage Tests', () {
    test('initially empty queue count is 0', () async {
      final count = await storage.getQueueCount();
      expect(count, equals(0));
      final points = await storage.getQueuedPoints();
      expect(points, isEmpty);
    });

    test('enqueuePoint saves point to file and increases queue count', () async {
      final point = TrackingLocationPoint(
        id: 'pt-1',
        latitude: -6.2,
        longitude: 106.8,
        accuracy: 10.0,
        recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
      );

      await storage.enqueuePoint(
        point: point,
        sourceType: 'attendance',
        referenceId: 'att-100',
      );

      final count = await storage.getQueueCount();
      expect(count, equals(1));

      final items = await storage.getQueuedPoints();
      expect(items.length, equals(1));
      expect(items.first.sourceType, equals('attendance'));
      expect(items.first.referenceId, equals('att-100'));
      expect(items.first.point.id, equals('pt-1'));
      expect(items.first.point.latitude, equals(-6.2));
      expect(testFile.existsSync(), isTrue);
    });

    test('getBatchesForUpload groups points by sourceType and referenceId', () async {
      final now = DateTime.utc(2026, 10, 7, 8, 0, 0);

      // 2 points for attendance att-100
      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'att-p1', latitude: -6.21, longitude: 106.81, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'att-100',
      );
      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'att-p2', latitude: -6.22, longitude: 106.82, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'att-100',
      );

      // 1 point for activity act-200
      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'act-p1', latitude: -6.31, longitude: 106.91, recordedAt: now),
        sourceType: 'activity',
        referenceId: 'act-200',
      );

      final batches = await storage.getBatchesForUpload();
      expect(batches.length, equals(2));

      final attBatch = batches.firstWhere((b) => b.sourceType == 'attendance');
      expect(attBatch.referenceId, equals('att-100'));
      expect(attBatch.locations.length, equals(2));

      final actBatch = batches.firstWhere((b) => b.sourceType == 'activity');
      expect(actBatch.referenceId, equals('act-200'));
      expect(actBatch.locations.length, equals(1));
    });

    test('removePoints removes only specified point IDs from buffer', () async {
      final now = DateTime.utc(2026, 10, 7, 8, 0, 0);

      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'pt-1', latitude: -6.1, longitude: 106.1, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'att-1',
      );
      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'pt-2', latitude: -6.2, longitude: 106.2, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'att-1',
      );
      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'pt-3', latitude: -6.3, longitude: 106.3, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'att-1',
      );

      expect(await storage.getQueueCount(), equals(3));

      // Remove pt-1 and pt-3
      await storage.removePoints(['pt-1', 'pt-3']);

      expect(await storage.getQueueCount(), equals(1));
      final remaining = await storage.getQueuedPoints();
      expect(remaining.first.point.id, equals('pt-2'));
    });

    test('purgeQueueForReference purges all points for closed session', () async {
      final now = DateTime.utc(2026, 10, 7, 8, 0, 0);

      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'pt-closed-1', latitude: -6.1, longitude: 106.1, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'session-closed-123',
      );
      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'pt-closed-2', latitude: -6.2, longitude: 106.2, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'session-closed-123',
      );
      await storage.enqueuePoint(
        point: TrackingLocationPoint(id: 'pt-active-1', latitude: -6.3, longitude: 106.3, recordedAt: now),
        sourceType: 'attendance',
        referenceId: 'session-active-456',
      );

      expect(await storage.getQueueCount(), equals(3));

      await storage.purgeQueueForReference('session-closed-123');

      expect(await storage.getQueueCount(), equals(1));
      final remaining = await storage.getQueuedPoints();
      expect(remaining.first.referenceId, equals('session-active-456'));
    });

    test('clearAll deletes storage file and empties queue', () async {
      await storage.enqueuePoint(
        point: TrackingLocationPoint(
          id: 'pt-1',
          latitude: -6.1,
          longitude: 106.1,
          recordedAt: DateTime.utc(2026, 10, 7, 8, 0, 0),
        ),
        sourceType: 'attendance',
        referenceId: 'att-1',
      );

      expect(testFile.existsSync(), isTrue);
      await storage.clearAll();

      expect(await storage.getQueueCount(), equals(0));
      expect(testFile.existsSync(), isFalse);
    });
  });
}
