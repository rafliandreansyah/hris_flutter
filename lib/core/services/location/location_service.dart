import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service utilitas untuk interaksi langsung dengan sensor GPS, deteksi Fake GPS,
/// pembacaan level baterai, dan optimasi daya (sensor throttling).
class LocationService {
  final Battery _battery;

  LocationService({Battery? battery}) : _battery = battery ?? Battery();

  /// Memeriksa apakah switch GPS / Location Service perangkat sedang aktif
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('⚠️ [LocationService.isLocationServiceEnabled] $e');
      return false;
    }
  }

  /// Mengambil posisi geografis saat ini
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [LocationService.getCurrentPosition] $e');
      return await getLastKnownPosition();
    }
  }

  /// Mengambil koordinat terakhir yang dicatat oleh OS
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('⚠️ [LocationService.getLastKnownPosition] $e');
      return null;
    }
  }

  /// Memeriksa apakah lokasi berasal dari mock provider / Fake GPS
  bool isMockLocation(Position position) {
    return position.isMocked;
  }

  /// Membaca level baterai perangkat (0–100)
  Future<int?> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      debugPrint('ℹ️ [LocationService.getBatteryLevel] Baterai tidak terbaca: $e');
      return null;
    }
  }

  /// Evaluasi Sensor Throttling untuk menghemat baterai saat karyawan diam di meja kerja:
  /// Jika kecepatan < 1 m/s dan jarak perpindahan < 20 meter selama kurang dari 10 menit,
  /// kembalikan true (lewati perekaman titik baru).
  bool shouldThrottle({
    required Position current,
    Position? previous,
    DateTime? previousTime,
  }) {
    if (previous == null || previousTime == null) {
      return false;
    }

    final speed = current.speed;
    // Jika kecepatan bergerak terdeteksi (> 1.0 m/s), jangan throttle
    if (speed >= 1.0) {
      return false;
    }

    final distanceMeters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );

    // Jika perpindahan signifikan (>= 20 meter), catat titik baru
    if (distanceMeters >= 20.0) {
      return false;
    }

    // Jika diam di tempat (< 20 meter) dan belum lewat 10 menit, throttle (skip)
    final elapsedMinutes = DateTime.now().difference(previousTime).inMinutes;
    if (elapsedMinutes < 10) {
      return true;
    }

    return false;
  }
}
