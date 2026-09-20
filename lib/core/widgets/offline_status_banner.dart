import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/services/network_connectivity_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Banner status konektivitas cerdas (Offline / Back Online) yang muncul di bagian atas layar
/// dengan transisi animasi halus saat perangkat kehilangan atau mendapatkan kembali sinyal internet.
class OfflineStatusBanner extends StatefulWidget {
  final Widget child;

  const OfflineStatusBanner({super.key, required this.child});

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;
  bool _showBanner = false;
  bool _wasOffline = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _isOnline = NetworkConnectivityService.instance.isOnline;
    _subscription = NetworkConnectivityService.instance.onConnectivityChanged
        .listen(_handleConnectivityChanged);
  }

  void _handleConnectivityChanged(bool isOnline) {
    if (!mounted) return;

    if (!isOnline) {
      _hideTimer?.cancel();
      setState(() {
        _isOnline = false;
        _showBanner = true;
        _wasOffline = true;
      });
    } else if (_wasOffline) {
      // Menampilkan banner "Kembali Online" sebentar (2.5 detik) lalu menghilangkannya
      setState(() {
        _isOnline = true;
        _showBanner = true;
      });

      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _showBanner = false;
            _wasOffline = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _showBanner
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      color: _isOnline
                          ? (isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.brandTeal)
                          : (isDark
                              ? const Color(0xFF7F1D1D)
                              : AppColors.errorRed),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isOnline
                                ? LucideIcons.wifi
                                : LucideIcons.wifiOff,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline
                                ? 'Koneksi internet terhubung kembali.'
                                : 'Tidak ada koneksi internet. Mencoba menghubungkan...',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
