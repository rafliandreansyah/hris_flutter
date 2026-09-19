import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card 2: Geo-Location Card (Lokasi Absensi)
/// Sesuai spesifikasi Google Stitch Screen ID: `c0c581134c61461a8585cf77a66f1dd7`.
class AttendanceRequestLocationCard extends StatefulWidget {
  final AttendanceRequestDetailData detail;

  const AttendanceRequestLocationCard({super.key, required this.detail});

  @override
  State<AttendanceRequestLocationCard> createState() =>
      _AttendanceRequestLocationCardState();
}

class _AttendanceRequestLocationCardState
    extends State<AttendanceRequestLocationCard> {
  GoogleMapController? _mapController;
  int _selectedLocationIndex = 0; // 0 = Masuk, 1 = Pulang

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
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final primaryContainerCol = isDark
        ? AppColors.primaryContainer.withValues(alpha: 0.15)
        : const Color(0xFFF0FDFA);
    final brandTealCol =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final detail = widget.detail;
    final hasOutCoords = detail.hasValidCoordinatesOut;
    final showToggle = detail.isInOut && (hasOutCoords || detail.addressOut != null);

    final isViewingOut = detail.isOut || (showToggle && _selectedLocationIndex == 1);

    final lat = isViewingOut
        ? (detail.latitudeOut ?? detail.latitude ?? 0.0)
        : (detail.latitude ?? detail.latitudeOut ?? 0.0);
    final lng = isViewingOut
        ? (detail.longitudeOut ?? detail.longitude ?? 0.0)
        : (detail.longitude ?? detail.longitudeOut ?? 0.0);
    final address = isViewingOut
        ? (detail.addressOut ?? detail.address)
        : (detail.address ?? detail.addressOut);
    final hasCoords = isViewingOut
        ? (detail.hasValidCoordinatesOut || detail.hasValidCoordinates)
        : (detail.hasValidCoordinates || detail.hasValidCoordinatesOut);
    final targetLatLng = LatLng(lat, lng);

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
          // Header Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOKASI ABSENSI (GEO-LOCATION)',
                style: AppTypography.labelSmall.copyWith(
                  color: subtitleCol,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (hasCoords)
                InkWell(
                  onTap: () {
                    MapsConfig.openGoogleMaps(
                      latitude: lat,
                      longitude: lng,
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buka Maps',
                          style: AppTypography.labelSmall.copyWith(
                            color: brandTealCol,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.externalLink,
                          size: 13,
                          color: brandTealCol,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (showToggle) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSegmentChip(0, 'Lokasi Masuk', isDark, brandTealCol),
                const SizedBox(width: 8),
                _buildSegmentChip(1, 'Lokasi Pulang', isDark, brandTealCol),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Address & Coordinates Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryContainerCol,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 18,
                  color: brandTealCol,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (address != null && address.trim().isNotEmpty)
                          ? address.trim()
                          : 'Lokasi Luar Kantor',
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCoords
                          ? 'Lat: ${lat.toStringAsFixed(6)}, Long: ${lng.toStringAsFixed(6)}'
                          : 'Koordinat GPS tidak tersedia',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Google Map Container
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildMapWidget(
              targetLatLng,
              hasCoords,
              isDark,
              subtitleCol,
              address,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget(
    LatLng targetLatLng,
    bool hasCoords,
    bool isDark,
    Color subtitleCol,
    String? currentAddress,
  ) {
    if (_isTestEnvironment || !hasCoords) {
      return Container(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : const Color(0xFFF1F5F9),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.map,
                size: 32,
                color: subtitleCol.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 6),
              Text(
                hasCoords ? 'Peta Lokasi Presensi' : 'Peta Tidak Tersedia',
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      key: ValueKey(
        'attendance_request_map_${targetLatLng.latitude.toStringAsFixed(5)}_${targetLatLng.longitude.toStringAsFixed(5)}',
      ),
      initialCameraPosition: CameraPosition(
        target: targetLatLng,
        zoom: 15.5,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('attendance_request_location'),
          position: targetLatLng,
          infoWindow: InfoWindow(
            title: currentAddress ?? widget.detail.address ?? 'Lokasi Presensi',
          ),
        ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget _buildSegmentChip(
    int index,
    String label,
    bool isDark,
    Color brandTealCol,
  ) {
    final isSelected = _selectedLocationIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocationIndex = index;
        });
        final detail = widget.detail;
        final hasOutCoords = detail.hasValidCoordinatesOut;
        final showToggle =
            detail.isInOut && (hasOutCoords || detail.addressOut != null);
        final nextViewingOut =
            detail.isOut || (showToggle && index == 1);
        final nextLat = nextViewingOut
            ? (detail.latitudeOut ?? detail.latitude ?? 0.0)
            : (detail.latitude ?? detail.latitudeOut ?? 0.0);
        final nextLng = nextViewingOut
            ? (detail.longitudeOut ?? detail.longitude ?? 0.0)
            : (detail.longitude ?? detail.longitudeOut ?? 0.0);
        if (nextLat != 0.0 || nextLng != 0.0) {
          try {
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(nextLat, nextLng),
                  zoom: 15.5,
                ),
              ),
            );
          } catch (_) {}
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryContainer.withValues(alpha: 0.25)
                  : const Color(0xFFF0FDFA))
              : (isDark
                  ? AppColors.darkSurfaceContainerLow
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? brandTealCol
                : (isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? brandTealCol : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
