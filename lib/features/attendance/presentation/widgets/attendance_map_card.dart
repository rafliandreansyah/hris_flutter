import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceMapCard extends StatefulWidget {
  final AttendanceDetailModel detail;

  const AttendanceMapCard({
    super.key,
    required this.detail,
  });

  @override
  State<AttendanceMapCard> createState() => _AttendanceMapCardState();
}

class _AttendanceMapCardState extends State<AttendanceMapCard> {
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
    final l10n = AppLocalizations.of(context);
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

    final lat = widget.detail.latitude ?? 0.0;
    final lng = widget.detail.longitude ?? 0.0;
    final targetLocation = LatLng(lat, lng);
    final hasValidCoordinates = widget.detail.latitude != null &&
        widget.detail.longitude != null &&
        (lat != 0.0 || lng != 0.0);

    return Container(
      width: double.infinity,
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
          // 1. Header: Icon + Title + Action "Buka di Maps"
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
                    l10n?.attendanceLocation ?? 'Lokasi Presensi',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              if (hasValidCoordinates)
                InkWell(
                  onTap: () {
                    MapsConfig.openGoogleMaps(
                      latitude: lat,
                      longitude: lng,
                      queryLabel: widget.detail.workLocation?.name ??
                          widget.detail.address,
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
                          l10n?.openInMaps ?? 'Buka di Maps',
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

          // 2. Google Map Container
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: borderCol, width: 1),
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
              ),
              child: Stack(
                children: [
                  if (!_isTestEnvironment && !kIsWeb && hasValidCoordinates)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: targetLocation,
                        zoom: 15.5,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('attendance_marker'),
                          position: targetLocation,
                          infoWindow: InfoWindow(
                            title: widget.detail.workLocation?.name ??
                                'Lokasi Presensi',
                            snippet: widget.detail.address,
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
                    _buildFallbackMapPreview(isDark, textCol, subtitleCol),

                  // Location Tag Chip on Map (Top Right)
                  if (widget.detail.workLocation?.name != null &&
                      widget.detail.workLocation!.name.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                            const Icon(
                              LucideIcons.building2,
                              size: 11,
                              color: AppColors.brandTeal,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                widget.detail.workLocation!.name,
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Address Info
          if (widget.detail.address != null &&
              widget.detail.address!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 15,
                  color: subtitleCol,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.detail.address!,
                    style: AppTypography.bodySmall.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // 4. Coordinates Info
          Row(
            children: [
              Icon(
                LucideIcons.compass,
                size: 14,
                color: subtitleCol,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n?.gpsCoordinates ?? "Koordinat GPS"}: ',
                style: AppTypography.labelSmall.copyWith(
                  color: subtitleCol,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.detail.coordinateDisplay,
                style: AppTypography.labelSmall.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackMapPreview(
    bool isDark,
    Color textCol,
    Color subtitleCol,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                LucideIcons.mapPin,
                size: 24,
                color: AppColors.brandTeal,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.detail.workLocation?.name ?? 'Lokasi Presensi',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.detail.coordinateDisplay,
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
