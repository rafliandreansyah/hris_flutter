import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Peta Google Maps khusus Form Create Activity sesuai spesifikasi Google Stitch
/// Menampilkan Google Maps, badge Live GPS Tracking, GPS Akurat (±3m), dan baris koordinat Real-time.
class CreateActivityMapCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String gpsAccuracy;

  const CreateActivityMapCard({
    super.key,
    this.latitude = -6.2088,
    this.longitude = 106.8456,
    this.gpsAccuracy = '±3m',
  });

  @override
  State<CreateActivityMapCard> createState() => _CreateActivityMapCardState();
}

class _CreateActivityMapCardState extends State<CreateActivityMapCard>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final targetLocation = LatLng(widget.latitude, widget.longitude);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Google Map Container
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                // Native GoogleMap (device) or Styled Fallback (widget tests/web)
                if (!_isTestEnvironment && !kIsWeb)
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: targetLocation,
                      zoom: 16.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('current_location_pin'),
                        position: targetLocation,
                        infoWindow: const InfoWindow(
                          title: 'Lokasi Aktivitas Saat Ini',
                        ),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    liteModeEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  )
                else
                  _buildFallbackMap(isDark),

                // Radar Pulse Ring on Center Marker
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60 * _pulseAnimation.value + 30,
                            height: 60 * _pulseAnimation.value + 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0D9488).withValues(
                                alpha: (1.0 - _pulseAnimation.value) * 0.35,
                              ),
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0D9488),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.mapPin,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Top Right Badge: Live GPS Tracking
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Live GPS Tracking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Left Badge: GPS Akurat (±3m)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkSurfaceContainerLowest
                              : Colors.white)
                          .withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderCol, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D9488),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GPS Akurat (${widget.gpsAccuracy})',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Footer Coordinates Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                top: BorderSide(color: borderCol, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Locate icon + Monospace coordinates
                Row(
                  children: [
                    const Icon(
                      LucideIcons.locateFixed,
                      size: 16,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.latitude.toStringAsFixed(4)}° S, ${widget.longitude.toStringAsFixed(4)}° E',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ],
                ),

                // Right: Real-time Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.brandTeal.withValues(alpha: 0.15)
                        : const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Real-time',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackMap(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.map,
                size: 14,
                color: AppColors.brandTeal,
              ),
              SizedBox(width: 6),
              Text(
                'Google Maps • Live Tracking',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
