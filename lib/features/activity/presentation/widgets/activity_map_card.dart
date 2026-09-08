import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Lokasi Aktivitas dengan integrasi Google Maps sesuai spesifikasi Google Stitch
class ActivityMapCard extends StatefulWidget {
  final ActivityItem activity;

  const ActivityMapCard({super.key, required this.activity});

  @override
  State<ActivityMapCard> createState() => _ActivityMapCardState();
}

class _ActivityMapCardState extends State<ActivityMapCard> {
  GoogleMapController? _mapController;

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    final targetLocation = LatLng(
      widget.activity.latitude,
      widget.activity.longitude,
    );

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Map Icon + Title + Action "Buka di Maps"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.map,
                    size: 18,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lokasi Aktivitas',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  MapsConfig.openGoogleMaps(
                    latitude: widget.activity.latitude,
                    longitude: widget.activity.longitude,
                    queryLabel: widget.activity.location,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.externalLink,
                        size: 14,
                        color: AppColors.brandTeal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Buka di Maps',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Google Maps Container (Interactive on device, styled fallback in widget tests)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: borderCol, width: 1),
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
              child: Stack(
                children: [
                  // Real Google Map (if not testing) or Stylized Map Canvas (for tests/fallback)
                  if (!_isTestEnvironment && !kIsWeb)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: targetLocation,
                        zoom: 15.5,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('activity_marker'),
                          position: targetLocation,
                          infoWindow: InfoWindow(
                            title: widget.activity.location,
                            snippet: widget.activity.fullAddress,
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
                    _buildFallbackMapPreview(isDark, textCol),

                  // Overlay Tag: Location Floor / Pin Tag (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
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
                      child: Text(
                        widget.activity.location,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Address Text
          Text(
            widget.activity.fullAddress,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.activity.districtCity,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: subtitleCol,
            ),
          ),

          const SizedBox(height: 8),

          // 4. Coordinates Chip & Verified Zone
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderCol, width: 1),
                ),
                child: Text(
                  '${widget.activity.latitude.toStringAsFixed(4)}° S, ${widget.activity.longitude.toStringAsFixed(4)}° E',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandTeal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stylized Map Preview used in Widget Tests or as fallback
  Widget _buildFallbackMapPreview(bool isDark, Color textCol) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.brandTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.mapPin,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.9,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Google Maps • ${widget.activity.location}',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
