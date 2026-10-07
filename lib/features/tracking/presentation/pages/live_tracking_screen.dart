import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_event.dart';
import 'package:hris_flutter/features/tracking/presentation/bloc/live_tracking_state.dart';
import 'package:hris_flutter/features/tracking/presentation/widgets/live_employee_bottom_card.dart';
import 'package:hris_flutter/features/tracking/presentation/widgets/live_tracking_summary_bar.dart';
import 'package:hris_flutter/features/tracking/presentation/widgets/tracking_route_modal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(MapsConfig.defaultLatitude, MapsConfig.defaultLongitude),
    zoom: MapsConfig.defaultZoom,
  );

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  BitmapDescriptor _getMarkerIcon(LiveEmployeeLocation emp) {
    if (emp.isGpsOff) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    if (!emp.isOnline) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    if (emp.status == 'activity') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Set<Marker> _buildEmployeeMarkers(
    BuildContext context,
    List<LiveEmployeeLocation> employees,
    LiveEmployeeLocation? selected,
  ) {
    final markers = <Marker>{};

    for (final emp in employees) {
      final isSelected = selected?.employeeId == emp.employeeId;
      markers.add(
        Marker(
          markerId: MarkerId(emp.employeeId),
          position: LatLng(emp.latitude, emp.longitude),
          icon: _getMarkerIcon(emp),
          zIndexInt: isSelected ? 10 : 1,
          infoWindow: InfoWindow(
            title: emp.name,
            snippet: '${emp.positionName ?? 'Staff'} • ${emp.departmentName ?? 'Dept'}',
            onTap: () {
              context
                  .read<LiveTrackingBloc>()
                  .add(LiveTrackingEmployeeSelected(emp));
            },
          ),
          onTap: () {
            context
                .read<LiveTrackingBloc>()
                .add(LiveTrackingEmployeeSelected(emp));
            _animateToPosition(emp.latitude, emp.longitude);
          },
        ),
      );
    }

    return markers;
  }

  void _animateToPosition(double lat, double lng, {double zoom = 16.0}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: zoom),
      ),
    );
  }

  void _fitAllEmployees(List<LiveEmployeeLocation> employees) {
    if (employees.isEmpty || _mapController == null) return;

    if (employees.length == 1) {
      _animateToPosition(employees.first.latitude, employees.first.longitude);
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (final emp in employees) {
      minLat = minLat == null ? emp.latitude : (emp.latitude < minLat ? emp.latitude : minLat);
      maxLat = maxLat == null ? emp.latitude : (emp.latitude > maxLat ? emp.latitude : maxLat);
      minLng = minLng == null ? emp.longitude : (emp.longitude < minLng ? emp.longitude : minLng);
      maxLng = maxLng == null ? emp.longitude : (emp.longitude > maxLng ? emp.longitude : maxLng);
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return BlocConsumer<LiveTrackingBloc, LiveTrackingState>(
      listener: (context, state) {
        if (state.selectedRouteLogs.isNotEmpty && state.selectedEmployee != null) {
          TrackingRouteModal.show(
            context,
            employee: state.selectedEmployee!,
            logs: state.selectedRouteLogs,
            isLoading: state.isLoadingRoute,
            errorMessage: state.routeErrorMessage,
            onRetry: () {
              final emp = state.selectedEmployee!;
              context.read<LiveTrackingBloc>().add(
                    LiveTrackingRouteRequested(
                      sourceType: emp.status,
                      referenceId: emp.activeRefId ?? '',
                      employeeId: emp.employeeId,
                    ),
                  );
            },
          );
        }
      },
      builder: (context, state) {
        final employees = state.filteredEmployees;
        final selected = state.selectedEmployee;

        return Scaffold(
          body: Stack(
            children: [
              // 1. Google Map Layer
              GoogleMap(
                initialCameraPosition: _initialPosition,
                markers: _buildEmployeeMarkers(context, employees, selected),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                  if (employees.isNotEmpty) {
                    _fitAllEmployees(employees);
                  }
                },
                onTap: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (state.selectedEmployee != null) {
                    context
                        .read<LiveTrackingBloc>()
                        .add(const LiveTrackingEmployeeSelected(null));
                  }
                },
              ),

              // 2. Top Header & Floating Filters Overlay
              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top App Bar Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.arrowLeft, size: 20),
                            color: textCol,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Tracking',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textCol,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Monitoring armada karyawan',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Pusatkan Semua',
                            onPressed: () => _fitAllEmployees(employees),
                            icon: const Icon(LucideIcons.focus, size: 19),
                            color: AppColors.brandTeal,
                          ),
                          IconButton(
                            tooltip: 'Perbarui',
                            onPressed: () {
                              context
                                  .read<LiveTrackingBloc>()
                                  .add(const LiveTrackingRefreshed());
                            },
                            icon: state.status == LiveTrackingStatus.loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(LucideIcons.rotateCcw, size: 18),
                            color: textCol,
                          ),
                        ],
                      ),
                    ),

                    // Search & Segmented Filter Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Input Field
                          TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              context
                                  .read<LiveTrackingBloc>()
                                  .add(LiveTrackingSearchQueryChanged(val));
                            },
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            style: AppTypography.bodySmall.copyWith(color: textCol),
                            decoration: InputDecoration(
                              hintText: 'Cari nama atau NIK karyawan...',
                              hintStyle: AppTypography.bodySmall.copyWith(color: subtitleCol),
                              prefixIcon: const Icon(LucideIcons.search, size: 16),
                              prefixIconConstraints: const BoxConstraints(minWidth: 32),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 14),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<LiveTrackingBloc>().add(
                                              const LiveTrackingSearchQueryChanged(''),
                                            );
                                      },
                                    )
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 6),
                          const Divider(height: 1),
                          const SizedBox(height: 6),

                          // Status Filter Chips
                          Row(
                            children: [
                              _buildStatusChip(
                                context: context,
                                label: 'Semua',
                                statusKey: 'all',
                                isSelected: state.selectedStatus == 'all',
                              ),
                              const SizedBox(width: 6),
                              _buildStatusChip(
                                context: context,
                                label: 'Presensi',
                                statusKey: 'attendance',
                                isSelected: state.selectedStatus == 'attendance',
                              ),
                              const SizedBox(width: 6),
                              _buildStatusChip(
                                context: context,
                                label: 'Dinas',
                                statusKey: 'activity',
                                isSelected: state.selectedStatus == 'activity',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Metrics Summary Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LiveTrackingSummaryBar(
                        summary: state.summary,
                        onRefresh: () {
                          context
                              .read<LiveTrackingBloc>()
                              .add(const LiveTrackingRefreshed());
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Bottom Card Karyawan Terpilih
              if (selected != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: LiveEmployeeBottomCard(
                      employee: selected,
                      onClose: () {
                        context
                            .read<LiveTrackingBloc>()
                            .add(const LiveTrackingEmployeeSelected(null));
                      },
                      onViewRoute: () {
                        if (selected.activeRefId != null &&
                            selected.activeRefId!.isNotEmpty) {
                          context.read<LiveTrackingBloc>().add(
                                LiveTrackingRouteRequested(
                                  sourceType: selected.status,
                                  referenceId: selected.activeRefId!,
                                  employeeId: selected.employeeId,
                                ),
                              );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ID sesi aktif tidak ditemukan untuk rute ini.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),

              // 4. State Failure View
              if (state.status == LiveTrackingStatus.failure && state.data == null)
                Positioned.fill(
                  child: Container(
                    color: bg.withValues(alpha: 0.9),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.circleAlert,
                            size: 42,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage ?? 'Gagal memuat data live tracking.',
                            style: AppTypography.titleSmall.copyWith(color: textCol),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: 'Coba Lagi',
                            leadingIcon: LucideIcons.rotateCcw,
                            height: 44,
                            onPressed: () {
                              context
                                  .read<LiveTrackingBloc>()
                                  .add(const LiveTrackingStarted());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip({
    required BuildContext context,
    required String label,
    required String statusKey,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          context
              .read<LiveTrackingBloc>()
              .add(LiveTrackingFilterChanged(status: statusKey));
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
