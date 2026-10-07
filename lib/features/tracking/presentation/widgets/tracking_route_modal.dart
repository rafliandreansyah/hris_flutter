import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/data/models/tracking_log_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal dialog/bottom sheet yang menampilkan visualisasi polyline rute GPS karyawan
class TrackingRouteModal extends StatefulWidget {
  final LiveEmployeeLocation employee;
  final List<TrackingLogItem> logs;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const TrackingRouteModal({
    super.key,
    required this.employee,
    required this.logs,
    required this.isLoading,
    this.errorMessage,
    required this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required LiveEmployeeLocation employee,
    required List<TrackingLogItem> logs,
    required bool isLoading,
    String? errorMessage,
    required VoidCallback onRetry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TrackingRouteModal(
        employee: employee,
        logs: logs,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: onRetry,
      ),
    );
  }

  @override
  State<TrackingRouteModal> createState() => _TrackingRouteModalState();
}

class _TrackingRouteModalState extends State<TrackingRouteModal> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Polyline> _buildPolylines() {
    if (widget.logs.isEmpty) return {};

    final points = widget.logs
        .map((log) => LatLng(log.latitude, log.longitude))
        .toList();

    return {
      Polyline(
        polylineId: const PolylineId('employee_route'),
        points: points,
        color: AppColors.brandTeal,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Set<Marker> _buildMarkers() {
    if (widget.logs.isEmpty) return {};

    final markers = <Marker>{};

    // Titik Awal
    final first = widget.logs.first;
    markers.add(
      Marker(
        markerId: const MarkerId('route_start'),
        position: LatLng(first.latitude, first.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Titik Awal',
          snippet: AppDateUtil.formatTimeHHmm(
            first.recordedAt.toIso8601String(),
          ),
        ),
      ),
    );

    // Titik Akhir / Terkini
    if (widget.logs.length > 1) {
      final last = widget.logs.last;
      markers.add(
        Marker(
          markerId: const MarkerId('route_end'),
          position: LatLng(last.latitude, last.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: 'Posisi Terkini',
            snippet: AppDateUtil.formatTimeHHmm(
              last.recordedAt.toIso8601String(),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  CameraPosition _initialCameraPosition() {
    if (widget.logs.isNotEmpty) {
      final last = widget.logs.last;
      return CameraPosition(
        target: LatLng(last.latitude, last.longitude),
        zoom: 14.5,
      );
    }
    return CameraPosition(
      target: LatLng(widget.employee.latitude, widget.employee.longitude),
      zoom: 14.5,
    );
  }

  void _fitBounds() {
    if (widget.logs.isEmpty || _mapController == null) return;

    double? minLat, maxLat, minLng, maxLng;
    for (final log in widget.logs) {
      minLat = minLat == null ? log.latitude : (log.latitude < minLat ? log.latitude : minLat);
      maxLat = maxLat == null ? log.latitude : (log.latitude > maxLat ? log.latitude : maxLat);
      minLng = minLng == null ? log.longitude : (log.longitude < minLng ? log.longitude : minLng);
      maxLng = maxLng == null ? log.longitude : (log.longitude > maxLng ? log.longitude : maxLng);
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.route,
                    size: 18,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rute Perjalanan: ${widget.employee.name}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.logs.length} titik koordinat tercatat',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                  color: subtitleCol,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Konten Peta atau State Loading / Error
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : widget.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.circleAlert,
                                size: 36,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.errorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: textCol,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              AppButton(
                                text: 'Coba Lagi',
                                leadingIcon: LucideIcons.rotateCcw,
                                height: 40,
                                onPressed: widget.onRetry,
                              ),
                            ],
                          ),
                        ),
                      )
                    : widget.logs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.mapPin,
                                    size: 40,
                                    color: subtitleCol,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Belum ada riwayat jejak rute GPS yang tercatat untuk sesi ini.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: subtitleCol,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: _initialCameraPosition(),
                                polylines: _buildPolylines(),
                                markers: _buildMarkers(),
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                onMapCreated: (ctrl) {
                                  _mapController = ctrl;
                                  _fitBounds();
                                },
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: FloatingActionButton.small(
                                  heroTag: 'fit_bounds_btn',
                                  backgroundColor: bg,
                                  onPressed: _fitBounds,
                                  child: Icon(
                                    LucideIcons.scan,
                                    size: 18,
                                    color: textCol,
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
}
