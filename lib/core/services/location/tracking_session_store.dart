import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot sesi pelacakan aktif agar bisa dipulihkan setelah app dimatikan / HP restart,
/// juga ketika server belum bisa dihubungi saat app dibuka.
class TrackingSessionSnapshot extends Equatable {
  final bool onActivity;
  final String? attendanceId;
  final String? activityId;
  final String? activityTitle;
  final int attendanceIntervalSeconds;
  final int activityIntervalSeconds;

  const TrackingSessionSnapshot({
    required this.onActivity,
    this.attendanceId,
    this.activityId,
    this.activityTitle,
    required this.attendanceIntervalSeconds,
    required this.activityIntervalSeconds,
  });

  Map<String, dynamic> toJson() => {
        'onActivity': onActivity,
        'attendanceId': attendanceId,
        'activityId': activityId,
        'activityTitle': activityTitle,
        'attendanceIntervalSeconds': attendanceIntervalSeconds,
        'activityIntervalSeconds': activityIntervalSeconds,
      };

  factory TrackingSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return TrackingSessionSnapshot(
      onActivity: json['onActivity'] as bool? ?? false,
      attendanceId: json['attendanceId'] as String?,
      activityId: json['activityId'] as String?,
      activityTitle: json['activityTitle'] as String?,
      attendanceIntervalSeconds: json['attendanceIntervalSeconds'] as int? ?? 600,
      activityIntervalSeconds: json['activityIntervalSeconds'] as int? ?? 180,
    );
  }

  @override
  List<Object?> get props => [
        onActivity,
        attendanceId,
        activityId,
        activityTitle,
        attendanceIntervalSeconds,
        activityIntervalSeconds,
      ];
}

/// Penyimpanan sesi pelacakan + flag "tracking aktif" yang dibaca kode native:
/// - Android `TrackingBootReceiver`: notifikasi "ketuk untuk melanjutkan" setelah reboot.
/// - iOS `AppDelegate`: Significant Location Change untuk membangunkan app di background.
class TrackingSessionStore {
  /// Jangan ubah tanpa menyesuaikan TrackingBootReceiver.kt & AppDelegate.swift.
  static const String activeFlagKey = 'tracking_session_active';
  static const String snapshotKey = 'tracking_session_snapshot';

  static const MethodChannel _iosChannel =
      MethodChannel('oasish/tracking_relaunch');

  Future<void> save(TrackingSessionSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(snapshotKey, jsonEncode(snapshot.toJson()));
      await prefs.setBool(activeFlagKey, true);
      await _setIosRelaunch(true);
    } catch (e) {
      debugPrint('ℹ️ [TrackingSessionStore.save] $e');
    }
  }

  Future<TrackingSessionSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(snapshotKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? TrackingSessionSnapshot.fromJson(decoded)
          : null;
    } catch (e) {
      debugPrint('ℹ️ [TrackingSessionStore.load] $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(snapshotKey);
      await prefs.setBool(activeFlagKey, false);
      await _setIosRelaunch(false);
    } catch (e) {
      debugPrint('ℹ️ [TrackingSessionStore.clear] $e');
    }
  }

  Future<void> _setIosRelaunch(bool active) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _iosChannel.invokeMethod<void>('setActive', active);
    } on MissingPluginException {
      // Engine belum siap / test: flag di UserDefaults tetap dibaca saat launch berikutnya.
    }
  }
}
