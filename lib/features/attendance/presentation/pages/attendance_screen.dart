import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_action_buttons.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_employee_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_geofence_map_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_server_clock_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_timeline_section.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_top_app_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

class AttendanceScreen extends StatelessWidget {
  final AttendanceRepository? repository;
  final bool autoStartClock;

  const AttendanceScreen({
    super.key,
    this.repository,
    this.autoStartClock = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttendanceBloc>(
      create: (context) => AttendanceBloc(
        repository: repository ?? AttendanceRepositoryImpl(),
        autoStartClock: autoStartClock,
      )..add(const AttendanceFetchRequested()),
      child: const _AttendanceScreenView(),
    );
  }
}

class _AttendanceScreenView extends StatefulWidget {
  const _AttendanceScreenView();

  @override
  State<_AttendanceScreenView> createState() => _AttendanceScreenViewState();
}

class _AttendanceScreenViewState extends State<_AttendanceScreenView> {
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    _requestGpsLocation();
  }

  Future<Position?> _requestGpsLocation({bool showFeedback = false}) async {
    if (showFeedback && mounted) {
      setState(() => _isUpdatingLocation = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Memperbarui lokasi GPS sekarang...'),
            ],
          ),
          backgroundColor: AppColors.brandTeal,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (!mounted) return position;
      context.read<AttendanceBloc>().add(
            AttendanceLocationUpdated(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              isInsideGeofence: true,
            ),
          );

      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circleCheck,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lokasi GPS diperbarui: ${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.brandTeal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return position;
    } catch (_) {
      // Ignored for environments without GPS/test runner
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.circleAlert, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Tidak dapat memperbarui lokasi GPS'),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return null;
    } finally {
      if (showFeedback && mounted) {
        setState(() => _isUpdatingLocation = false);
      }
    }
  }

  void _showReportLocationDialog(BuildContext context) {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Laporkan Kendala Lokasi',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Jika GPS Anda mendeteksi di luar radius kantor padahal Anda sudah di lokasi, jelaskan detail kendala di bawah ini:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.surfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: GPS melompat atau sinyal di lobi utama lemah...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineMuted),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Kirim Laporan',
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    final bloc = context.read<AttendanceBloc>();
                    final currentState = bloc.state;
                    final lat = currentState is AttendanceLoaded
                        ? currentState.userLatitude ?? -6.2253
                        : -6.2253;
                    final lng = currentState is AttendanceLoaded
                        ? currentState.userLongitude ?? 106.8097
                        : 106.8097;

                    bloc.add(
                      AttendanceReportIssueSubmitted(
                        issueDescription: text,
                        latitude: lat,
                        longitude: lng,
                      ),
                    );
                    Navigator.pop(bottomSheetContext);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: BlocConsumer<AttendanceBloc, AttendanceState>(
          listener: (context, state) {
            if (state is AttendanceLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionMessage!),
                  backgroundColor: AppColors.brandTeal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is AttendanceLoaded && state.errorMessage != null) {
              AppDialogUtil.showError(
                context,
                title: 'Gagal',
                message: state.errorMessage!,
              );
            } else if (state is AttendanceFailure) {
              final isNotFound = state.isNotFound;

              AppDialogUtil.showError(
                context,
                title: isNotFound ? 'Pemberitahuan' : 'Gagal Memuat Absensi',
                message: state.message,
                closeText: isNotFound ? 'Kembali' : 'Tutup',
                onClose: isNotFound
                    ? () => Navigator.of(context).maybePop()
                    : null,
                onRetry: isNotFound
                    ? null
                    : () {
                        context
                            .read<AttendanceBloc>()
                            .add(const AttendanceFetchRequested());
                      },
              );
            }
          },
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return _buildShimmerLoading(isDark);
            }

            if (state is AttendanceFailure) {
              final isNotFound = state.isNotFound;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNotFound
                            ? LucideIcons.calendarX
                            : LucideIcons.alertTriangle,
                        size: 48,
                        color: isNotFound
                            ? AppColors.warning
                            : AppColors.errorRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isNotFound
                            ? 'Pemberitahuan Jadwal'
                            : 'Gagal memuat absensi',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.surfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      if (isNotFound)
                        AppButton(
                          text: 'Kembali',
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      else
                        AppButton(
                          text: 'Coba Lagi',
                          onPressed: () {
                            context
                                .read<AttendanceBloc>()
                                .add(const AttendanceFetchRequested());
                          },
                        ),
                    ],
                  ),
                ),
              );
            }

            final loaded = state is AttendanceLoaded
                ? state
                : AttendanceLoaded(
                    data: AttendanceTodayData(serverTime: DateTime.now()),
                    currentClockTime: DateTime.now(),
                  );

            final data = loaded.data;

            return RefreshIndicator(
              color: AppColors.brandTeal,
              onRefresh: () async {
                context.read<AttendanceBloc>().add(
                      const AttendanceFetchRequested(isRefresh: true),
                    );
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top App Bar (SliverAppBar floating & snap - hide on scroll down, show on scroll up)
                  AttendanceTopAppBar(
                    title: 'Attendance & Check-In',
                    subtitle:
                        '${data.companyName} • ${data.departmentName}',
                    isUpdatingLocation: _isUpdatingLocation,
                    onUpdateLocationPressed: () =>
                        _requestGpsLocation(showFeedback: true),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Geofence Map Card
                        AttendanceGeofenceMapCard(
                          officeLatitude: data.officeLatitude,
                          officeLongitude: data.officeLongitude,
                          userLatitude: loaded.userLatitude,
                          userLongitude: loaded.userLongitude,
                          geofenceRadiusMeters: data.geofenceRadiusMeters,
                          isInsideGeofence: loaded.isInsideGeofence,
                          gpsAccuracy: data.gpsAccuracy,
                          isAnyWhere: data.selectedWorkLocation?.isAnyWhere ?? false,
                          hasWorkLocation: data.hasWorkLocation,
                          isGpsAcquired: loaded.isGpsAcquired,
                        ),
                        const SizedBox(height: 16),

                        // 2. Realtime Server Clock Card (Without 'WIB')
                        AttendanceServerClockCard(
                          serverTime: loaded.currentClockTime,
                          clockTimeString: loaded.formattedClockTime,
                          timezone: data.timezone,
                          shiftName: data.shiftName,
                        ),
                        const SizedBox(height: 16),

                        // 3. User & Office Info Card (with Work Location Selector)
                        AttendanceEmployeeCard(
                          employeeName: data.employeeName,
                          employeeRole: data.employeeRole,
                          employeeId: data.employeeId,
                          photoUrl: data.photoUrl,
                          officeName: data.officeName,
                          officeDetail: data.officeDetail,
                          geofenceRadiusMeters: data.geofenceRadiusMeters,
                          availableWorkLocations: data.availableWorkLocations,
                          selectedWorkLocation: data.selectedWorkLocation,
                          onLocationChanged: (newLoc) {
                            context.read<AttendanceBloc>().add(
                                  AttendanceWorkLocationChanged(newLoc),
                                );
                          },
                        ),
                        const SizedBox(height: 16),

                        // 4. Timeline Section (Clock In, Break Session, Clock Out)
                        AttendanceTimelineSection(
                          inTime: data.inTime,
                          outTime: data.outTime,
                          breakOutTime: data.breakOutTime,
                          breakInTime: data.breakInTime,
                          isClockedIn: data.isClockedIn,
                          isClockedOut: data.isClockedOut,
                        ),
                        const SizedBox(height: 20),

                        // 5. Action Buttons (Clock In Now, Start Break, Report Location Issue)
                        AttendanceActionButtons(
                          isClockedIn: data.isClockedIn,
                          isClockedOut: data.isClockedOut,
                          isOnBreak: data.isOnBreak,
                          isLoading: loaded.isSubmittingAction,
                          hasWorkLocation: data.hasWorkLocation,
                          breakOutTime: data.breakOutTime,
                          onClockPressed: () {
                            if (!data.isClockedIn) {
                              context.read<AttendanceBloc>().add(
                                    AttendanceClockInSubmitted(
                                      latitude: loaded.userLatitude ??
                                          data.officeLatitude,
                                      longitude: loaded.userLongitude ??
                                          data.officeLongitude,
                                      address: data.officeDetail,
                                    ),
                                  );
                            } else if (!data.isClockedOut) {
                              context.read<AttendanceBloc>().add(
                                    AttendanceClockOutSubmitted(
                                      latitude: loaded.userLatitude ??
                                          data.officeLatitude,
                                      longitude: loaded.userLongitude ??
                                          data.officeLongitude,
                                      address: data.officeDetail,
                                    ),
                                  );
                            }
                          },
                          onBreakPressed: () {
                            context.read<AttendanceBloc>().add(
                                  const AttendanceBreakToggled(),
                                );
                          },
                          onReportIssuePressed: () =>
                              _showReportLocationDialog(context),
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark
        ? AppColors.darkSurfaceContainer
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
