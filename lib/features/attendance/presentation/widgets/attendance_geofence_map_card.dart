import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceGeofenceMapCard extends StatefulWidget {
  final double officeLatitude;
  final double officeLongitude;
  final double? userLatitude;
  final double? userLongitude;
  final double geofenceRadiusMeters;
  final bool isInsideGeofence;
  final String gpsAccuracy;
  final double mapHeight;
  final VoidCallback? onCenterPressed;

  /// Apakah lokasi kerja bertipe isAnyWhere (bisa absen di mana saja).
  final bool isAnyWhere;

  /// Apakah user memiliki lokasi kerja yang ditentukan.
  final bool hasWorkLocation;

  /// Apakah GPS sudah berhasil didapat.
  final bool isGpsAcquired;

  const AttendanceGeofenceMapCard({
    super.key,
    required this.officeLatitude,
    required this.officeLongitude,
    this.userLatitude,
    this.userLongitude,
    this.geofenceRadiusMeters = 50.0,
    this.isInsideGeofence = true,
    this.gpsAccuracy = '±5m',
    this.mapHeight = 220.0,
    this.onCenterPressed,
    this.isAnyWhere = false,
    this.hasWorkLocation = true,
    this.isGpsAcquired = true,
  });

  @override
  State<AttendanceGeofenceMapCard> createState() =>
      _AttendanceGeofenceMapCardState();
}

class _AttendanceGeofenceMapCardState extends State<AttendanceGeofenceMapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  GoogleMapController? _mapController;

  bool get _isTestOrDesktop {
    if (kIsWeb) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );

    bool isTest = false;
    try {
      isTest = Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {}

    if (!isTest) {
      _pulseController.repeat();
    } else {
      _pulseController.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant AttendanceGeofenceMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.officeLatitude != widget.officeLatitude ||
        oldWidget.officeLongitude != widget.officeLongitude ||
        oldWidget.userLatitude != widget.userLatitude ||
        oldWidget.userLongitude != widget.userLongitude ||
        oldWidget.isAnyWhere != widget.isAnyWhere ||
        oldWidget.hasWorkLocation != widget.hasWorkLocation) {
      _fitCameraBetweenLocations();
    }
  }

  /// Memfokuskan kamera Google Maps secara cerdas.
  void _fitCameraBetweenLocations() {
    if (_mapController == null) return;

    // Jika isAnyWhere atau tidak punya work location, fokus ke GPS user
    if (widget.isAnyWhere || !widget.hasWorkLocation) {
      if (widget.userLatitude != null && widget.userLongitude != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(widget.userLatitude!, widget.userLongitude!),
            16.5,
          ),
        );
      }
      return;
    }

    final officeLatLng = LatLng(widget.officeLatitude, widget.officeLongitude);

    if (widget.userLatitude == null || widget.userLongitude == null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(officeLatLng, 17.0),
      );
      return;
    }

    final userLatLng = LatLng(widget.userLatitude!, widget.userLongitude!);

    final latDiff = (officeLatLng.latitude - userLatLng.latitude).abs();
    final lngDiff = (officeLatLng.longitude - userLatLng.longitude).abs();

    if (latDiff < 0.0001 && lngDiff < 0.0001) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(officeLatLng, 17.5),
      );
    } else {
      final southwest = LatLng(
        math.min(officeLatLng.latitude, userLatLng.latitude),
        math.min(officeLatLng.longitude, userLatLng.longitude),
      );
      final northeast = LatLng(
        math.max(officeLatLng.latitude, userLatLng.latitude),
        math.max(officeLatLng.longitude, userLatLng.longitude),
      );
      final bounds = LatLngBounds(southwest: southwest, northeast: northeast);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 65.0),
      );
    }
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
    final cardBg =
        isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map Display Area
          SizedBox(
            height: widget.mapHeight,
            width: double.infinity,
            child: Stack(
              children: [
                _buildMapCanvas(),

                // Visual Geofence Overlay & Pins (Active on Desktop/Test & Visual preview)
                if (_isTestOrDesktop && widget.hasWorkLocation && !widget.isAnyWhere)
                  _buildVisualGeofenceOverlay(),

                // isAnyWhere overlay badge
                if (_isTestOrDesktop && widget.isAnyWhere)
                  _buildAnyWhereOverlay(),

                // No work location overlay
                if (_isTestOrDesktop && !widget.hasWorkLocation)
                  _buildNoWorkLocationOverlay(),

                // Live GPS Tracking Pill Badge (Top Right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.92),
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
                        const SizedBox(width: 5),
                        const Text(
                          'Live GPS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Focus Quick-Button (Bottom Right)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _fitCameraBetweenLocations,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkSurfaceContainerLowest
                                  : Colors.white)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.focus,
                                size: 14, color: AppColors.brandTeal),
                            SizedBox(width: 4),
                            Text(
                              'Fokus Lokasi',
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
                  ),
                ),
              ],
            ),
          ),

          // Bottom Geofence Status Pill & Accuracy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Geofence Pill — depends on state
                _buildGeofenceStatusPill(isDark),

                // GPS Accuracy Label
                Text(
                  'GPS Accuracy: ${widget.gpsAccuracy}',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.surfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build geofence status pill berdasarkan state: GPS pending, isAnyWhere, no location, dll.
  Widget _buildGeofenceStatusPill(bool isDark) {
    // Poin 7: GPS belum tersedia
    if (!widget.isGpsAcquired && widget.hasWorkLocation && !widget.isAnyWhere) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainerHigh
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isTestOrDesktop)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.surfaceVariant,
                ),
              )
            else
              Icon(
                LucideIcons.loader,
                size: 14,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.surfaceVariant,
              ),
            const SizedBox(width: 6),
            Text(
              'Mendeteksi lokasi...',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.surfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Poin 4: Tidak punya lokasi kerja
    if (!widget.hasWorkLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF450A0A)
              : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 15,
              color: AppColors.errorRed,
            ),
            const SizedBox(width: 6),
            Text(
              'Lokasi Kerja Tidak Tersedia',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.errorRed,
              ),
            ),
          ],
        ),
      );
    }

    // Poin 5: isAnyWhere
    if (widget.isAnyWhere) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkPrimaryContainer
              : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.globe,
              size: 15,
              color: isDark
                  ? AppColors.darkOnPrimaryContainer
                  : AppColors.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'Bisa Absen di Mana Saja',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkOnPrimaryContainer
                    : AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    // Normal: Inside / Outside
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isInsideGeofence
            ? (isDark
                ? AppColors.darkPrimaryContainer
                : AppColors.primaryContainer)
            : (isDark
                ? const Color(0xFF450A0A)
                : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isInsideGeofence
                ? LucideIcons.circleCheck
                : LucideIcons.circleAlert,
            size: 15,
            color: widget.isInsideGeofence
                ? (isDark
                    ? AppColors.darkOnPrimaryContainer
                    : AppColors.onPrimaryContainer)
                : AppColors.errorRed,
          ),
          const SizedBox(width: 6),
          Text(
            widget.isInsideGeofence
                ? 'Inside Geofence Radius'
                : 'Outside Geofence Radius',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.isInsideGeofence
                  ? (isDark
                      ? AppColors.darkOnPrimaryContainer
                      : AppColors.onPrimaryContainer)
                  : AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCanvas() {
    if (_isTestOrDesktop) {
      // Clean modern top-down simulated street grid per Google Stitch specs
      return Container(
        color: const Color(0xFFE5E7EB),
        child: CustomPaint(
          painter: _MapGridPainter(),
          child: const SizedBox.expand(),
        ),
      );
    }

    final officeLatLng = LatLng(widget.officeLatitude, widget.officeLongitude);
    final hasUser = widget.userLatitude != null && widget.userLongitude != null;

    // Tentukan target kamera awal
    final LatLng initialTarget;
    if (widget.isAnyWhere && hasUser) {
      initialTarget = LatLng(widget.userLatitude!, widget.userLongitude!);
    } else if (hasUser) {
      initialTarget = LatLng(
        (officeLatLng.latitude + widget.userLatitude!) / 2,
        (officeLatLng.longitude + widget.userLongitude!) / 2,
      );
    } else {
      initialTarget = officeLatLng;
    }

    // Build circles — sembunyikan jika isAnyWhere atau no work location
    final Set<Circle> circles = {};
    if (widget.hasWorkLocation && !widget.isAnyWhere) {
      circles.add(
        Circle(
          circleId: const CircleId('geofence_circle'),
          center: officeLatLng,
          radius: widget.geofenceRadiusMeters,
          fillColor: AppColors.brandTeal.withValues(alpha: 0.20),
          strokeColor: AppColors.brandTeal.withValues(alpha: 0.50),
          strokeWidth: 2,
        ),
      );
    }

    // Build markers — sembunyikan user pin (Poin 2), sembunyikan office jika isAnyWhere/no location
    final Set<Marker> markers = {};
    if (widget.hasWorkLocation && !widget.isAnyWhere) {
      markers.add(
        Marker(
          markerId: const MarkerId('office_hq'),
          position: officeLatLng,
          infoWindow: const InfoWindow(title: 'Lokasi Kerja (Kantor)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 16.5,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitCameraBetweenLocations();
      },
      circles: circles,
      markers: markers,
    );
  }

  Widget _buildVisualGeofenceOverlay() {
    return Stack(
      children: [
        // Geofence Circle Overlay
        Center(
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
          ),
        ),

        // HQ Marker (Offset in circle)
        Positioned(
          top: 36,
          right: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Text(
                  'HQ Office',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandTeal,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                LucideIcons.mapPin,
                color: AppColors.brandTeal,
                size: 28,
              ),
            ],
          ),
        ),

        // Blue Pulse Dot (GPS native representation, no pin marker)
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = 0.8 + (_pulseAnimation.value * 1.2);
              final alpha = (1.0 - _pulseAnimation.value) * 0.7;

              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3B82F6).withValues(alpha: alpha),
                      ),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Overlay untuk lokasi kerja bertipe isAnyWhere.
  Widget _buildAnyWhereOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.globe,
                  color: AppColors.brandTeal,
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bisa Absen di Mana Saja',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lokasi kerja fleksibel',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.brandTeal.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Overlay saat tidak memiliki lokasi kerja.
  Widget _buildNoWorkLocationOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.errorRed.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.mapPinOff,
                  color: AppColors.errorRed,
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lokasi Kerja Tidak Tersedia',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hubungi admin untuk mengatur lokasi kerja',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.errorRed.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for simulated city street grid
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), minorRoadPaint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), minorRoadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(size.width * 0.8, size.height), minorRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
