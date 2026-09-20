import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Layanan terpusat untuk memantau status konektivitas internet (online/offline)
/// secara real-time di seluruh aplikasi HRIS.
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  static NetworkConnectivityService get instance => _instance;
  factory NetworkConnectivityService() => _instance;

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;

  @visibleForTesting
  static Stream<bool>? testStream;

  NetworkConnectivityService._internal({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  /// Factory untuk testing
  @visibleForTesting
  factory NetworkConnectivityService.custom({required Connectivity connectivity}) {
    return NetworkConnectivityService._internal(connectivity: connectivity);
  }

  /// Status koneksi saat ini
  bool get isOnline => _isOnline;

  /// Stream status koneksi (true jika online, false jika offline)
  Stream<bool> get onConnectivityChanged =>
      testStream ?? _controller.stream;

  void _init() async {
    try {
      final initialResults = await _connectivity.checkConnectivity();
      _isOnline = _checkIsOnline(initialResults);
      _controller.add(_isOnline);
    } catch (_) {
      _isOnline = true;
      _controller.add(true);
    }

    _connectivity.onConnectivityChanged.listen((results) {
      final online = _checkIsOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  bool _checkIsOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _controller.close();
  }
}
