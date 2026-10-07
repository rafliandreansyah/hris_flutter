import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_batch_payload.dart';
import 'package:path_provider/path_provider.dart';

/// Item antrean titik pelacakan yang tersimpan di disk lokal
class QueuedTrackingPoint {
  final String sourceType;
  final String referenceId;
  final TrackingLocationPoint point;

  const QueuedTrackingPoint({
    required this.sourceType,
    required this.referenceId,
    required this.point,
  });

  Map<String, dynamic> toJson() => {
        'sourceType': sourceType,
        'referenceId': referenceId,
        'point': point.toLocalJson(),
      };

  factory QueuedTrackingPoint.fromJson(Map<String, dynamic> json) {
    return QueuedTrackingPoint(
      sourceType: json['sourceType']?.toString() ?? 'attendance',
      referenceId: json['referenceId']?.toString() ?? '',
      point: TrackingLocationPoint.fromLocalJson(
        json['point'] is Map<String, dynamic>
            ? json['point'] as Map<String, dynamic>
            : {},
      ),
    );
  }
}

/// Layanan penyimpanan antrean titik koordinat offline ke file JSON lokal secara atomik.
/// Menjamin data tidak hilang saat perangkat berada di area dead-zone / sinyal putus.
class LocationLocalStorage {
  static final LocationLocalStorage _instance = LocationLocalStorage._internal();
  static LocationLocalStorage get instance => _instance;

  LocationLocalStorage._internal();

  factory LocationLocalStorage() => _instance;

  String? _customStoragePath;

  /// Setter untuk memfasilitasi unit test dengan direktori mock/temp
  @visibleForTesting
  set customStoragePath(String? path) => _customStoragePath = path;

  Future<File> _getFile() async {
    if (_customStoragePath != null) {
      return File(_customStoragePath!);
    }
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/location_buffer.json');
  }

  // Sequential queue lock untuk mencegah race condition pada operasi disk
  Future<void> _lock = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final next = _lock.then((_) => action());
    _lock = next.then((_) {}, onError: (_) {});
    return next;
  }

  /// Membaca seluruh antrean dari file lokal
  Future<List<QueuedTrackingPoint>> _readAllUnlocked() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => QueuedTrackingPoint.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [LocationLocalStorage._readAllUnlocked] Gagal membaca buffer: $e');
      return [];
    }
  }

  /// Menulis seluruh antrean ke file lokal secara atomik (tulis ke .tmp lalu rename)
  Future<void> _writeAllUnlocked(List<QueuedTrackingPoint> points) async {
    try {
      final file = await _getFile();
      final tempFile = File('${file.path}.tmp');

      final jsonString = jsonEncode(points.map((p) => p.toJson()).toList());
      await tempFile.writeAsString(jsonString, flush: true);

      // Rename atomik
      if (await tempFile.exists()) {
        await tempFile.rename(file.path);
      }
    } catch (e) {
      debugPrint('⚠️ [LocationLocalStorage._writeAllUnlocked] Gagal menulis buffer: $e');
    }
  }

  /// Menambahkan satu titik koordinat baru ke antrean lokal
  Future<void> enqueuePoint({
    required TrackingLocationPoint point,
    required String sourceType,
    required String referenceId,
  }) {
    return _synchronized(() async {
      final list = await _readAllUnlocked();
      list.add(QueuedTrackingPoint(
        sourceType: sourceType,
        referenceId: referenceId,
        point: point,
      ));
      await _writeAllUnlocked(list);
    });
  }

  /// Mengambil kumpulan titik antrean hingga batas [limit] (default: 50)
  Future<List<QueuedTrackingPoint>> getQueuedPoints({int limit = 50}) {
    return _synchronized(() async {
      final list = await _readAllUnlocked();
      if (list.length <= limit) return List.unmodifiable(list);
      return List.unmodifiable(list.sublist(0, limit));
    });
  }

  /// Mengelompokkan titik antrean berdasarkan (sourceType, referenceId) untuk diunggah secara batch
  Future<List<TrackingBatchPayload>> getBatchesForUpload({int limit = 50}) {
    return _synchronized(() async {
      final list = await _readAllUnlocked();
      if (list.isEmpty) return [];

      final sliced = list.length <= limit ? list : list.sublist(0, limit);
      final Map<String, List<TrackingLocationPoint>> grouped = {};

      for (final item in sliced) {
        final key = '${item.sourceType}:${item.referenceId}';
        grouped.putIfAbsent(key, () => []).add(item.point);
      }

      final payloads = <TrackingBatchPayload>[];
      grouped.forEach((key, points) {
        final parts = key.split(':');
        payloads.add(TrackingBatchPayload(
          sourceType: parts[0],
          referenceId: parts[1],
          locations: points,
        ));
      });

      return payloads;
    });
  }

  /// Menghapus titik-titik yang sukses diterima oleh server (berdasarkan point.id)
  Future<void> removePoints(List<String> pointIds) {
    if (pointIds.isEmpty) return Future.value();
    return _synchronized(() async {
      final list = await _readAllUnlocked();
      final idSet = pointIds.toSet();
      list.removeWhere((item) => idSet.contains(item.point.id));
      await _writeAllUnlocked(list);
    });
  }

  /// Membersihkan antrean khusus untuk referenceId tertentu saat sesi ditutup di server (SESSION_CLOSED)
  Future<void> purgeQueueForReference(String referenceId) {
    return _synchronized(() async {
      final list = await _readAllUnlocked();
      list.removeWhere((item) => item.referenceId == referenceId);
      await _writeAllUnlocked(list);
    });
  }

  /// Mengambil jumlah total titik yang mengantre di buffer lokal
  Future<int> getQueueCount() {
    return _synchronized(() async {
      final list = await _readAllUnlocked();
      return list.length;
    });
  }

  /// Menghapus seluruh antrean (misal saat logout pengguna)
  Future<void> clearAll() {
    return _synchronized(() async {
      try {
        final file = await _getFile();
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('⚠️ [LocationLocalStorage.clearAll] Gagal menghapus file buffer: $e');
      }
    });
  }
}
