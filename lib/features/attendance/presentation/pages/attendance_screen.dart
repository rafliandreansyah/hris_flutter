import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_success_dialog.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_timeline_section.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_top_app_bar.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_work_location_card.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
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
  bool _hasShownNoMethodDialog = false;

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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(LucideIcons.circleAlert, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return null;
      }

      // 1. Coba ambil lokasi terakhir (cached) secara instan (~10ms) untuk iOS/Android
      Position? position;
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          position = lastKnown;
          context.read<AttendanceBloc>().add(
            AttendanceLocationUpdated(
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
              accuracy: lastKnown.accuracy,
              isInsideGeofence: true,
            ),
          );
        }
      } catch (_) {}

      // 2. Ambil koordinat GPS akurat dengan batas waktu responsif (4 detik jika sudah ada posisi, 6 detik jika cold start)
      try {
        final freshPosition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: position != null
                ? const Duration(seconds: 4)
                : const Duration(seconds: 6),
          ),
        );
        position = freshPosition;
        if (mounted) {
          context.read<AttendanceBloc>().add(
            AttendanceLocationUpdated(
              latitude: freshPosition.latitude,
              longitude: freshPosition.longitude,
              accuracy: freshPosition.accuracy,
              isInsideGeofence: true,
            ),
          );
        }
      } catch (_) {
        // Fallback cepat: Jika high accuracy timeout & belum ada posisi (misal di dalam ruangan),
        // coba ambil posisi via jaringan seluler/Wi-Fi (medium accuracy) yang sangat cepat
        if (position == null) {
          try {
            final fallbackPosition = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 3),
              ),
            );
            position = fallbackPosition;
            if (mounted) {
              context.read<AttendanceBloc>().add(
                AttendanceLocationUpdated(
                  latitude: fallbackPosition.latitude,
                  longitude: fallbackPosition.longitude,
                  accuracy: fallbackPosition.accuracy,
                  isInsideGeofence: true,
                ),
              );
            }
          } catch (_) {
            if (position == null) {
              rethrow;
            }
          }
        }
      }

      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  LucideIcons.circleCheck,
                  color: Colors.white,
                  size: 18,
                ),
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
      if (mounted && _isUpdatingLocation) {
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
      showDragHandle: true,
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
            top: 8,
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
                  hintText:
                      'Contoh: GPS melompat atau sinyal di lobi utama lemah...',
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

  Future<void> _handleClockAction(
    BuildContext context, {
    required AttendanceLoaded state,
  }) async {
    final data = state.data;

    // 1. Pengecekan apakah sudah absen masuk dan pulang
    if (data.isClockedIn && data.isClockedOut) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presensi kehadiran hari ini sudah selesai.'),
          backgroundColor: AppColors.brandTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Validasi metode presensi dari server
    if (!data.hasAttendanceMethod) {
      AppDialogUtil.showError(
        context,
        title: 'Metode Presensi Tidak Ditemukan',
        message:
            'Anda belum memiliki metode presensi yang ditentukan. Hubungi admin atau atasan Anda untuk mengatur metode presensi.',
        closeText: 'Kembali',
        onClose: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
      );
      return;
    }

    // 3. Validasi lokasi kerja
    final selectedLocation = data.selectedWorkLocation;
    if (selectedLocation == null || selectedLocation.id.isEmpty) {
      AppDialogUtil.showError(
        context,
        title: 'Lokasi Kerja Tidak Ditemukan',
        message:
            'Anda belum memiliki lokasi kerja yang ditentukan. Hubungi admin atau atasan Anda.',
      );
      return;
    }

    // 4. Validasi radius kantor (kecuali lokasi kerja adalah isAnyWhere)
    final isAnyWhere = selectedLocation.isAnyWhere;
    if (!isAnyWhere && !state.isInsideGeofence) {
      AppDialogUtil.showError(
        context,
        title: 'Di Luar Radius Kantor',
        message:
            'Anda berada di luar radius lokasi kerja (${data.geofenceRadiusMeters.toStringAsFixed(0)}m). Silakan mendekat ke area kantor untuk melakukan presensi, atau laporkan kendala lokasi jika GPS Anda tidak akurat.',
        retryText: 'Laporkan Kendala',
        onRetry: () => _showReportLocationDialog(context),
        closeText: 'Kembali',
      );
      return;
    }

    // 5. Koordinat GPS & data lokasi
    final double effectiveLat = state.userLatitude ?? data.officeLatitude;
    final double effectiveLng = state.userLongitude ?? data.officeLongitude;
    final String effectiveAddress = data.officeDetail;
    final String targetType = !data.isClockedIn ? 'in' : 'out';

    // 6. Eksekusi berdasarkan metode dari server (photo vs biometric)
    if (data.isBiometricMethod) {
      try {
        final authenticated = await BiometricService.instance.authenticate(
          localizedReason:
              'Pindai sidik jari atau wajah Anda untuk konfirmasi presensi ${targetType == "in" ? "Masuk" : "Pulang"}',
        );

        if (!authenticated) return;
        if (!context.mounted) return;

        if (targetType == 'in') {
          context.read<AttendanceBloc>().add(
            AttendanceClockInSubmitted(
              latitude: effectiveLat,
              longitude: effectiveLng,
              address: effectiveAddress,
              attendanceMethod: data.attendanceMethod,
              workLocationId: selectedLocation.id,
            ),
          );
        } else {
          context.read<AttendanceBloc>().add(
            AttendanceClockOutSubmitted(
              latitude: effectiveLat,
              longitude: effectiveLng,
              address: effectiveAddress,
              attendanceMethod: data.attendanceMethod,
              workLocationId: selectedLocation.id,
            ),
          );
        }
      } on BiometricException catch (e) {
        if (!context.mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Autentikasi Biometrik Gagal',
          message: e.message,
        );
      } catch (e) {
        if (!context.mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Autentikasi Biometrik Gagal',
          message: e.toString(),
        );
      }
    } else {
      // Default: Photo / Selfie
      try {
        final result = await ImageCompressUtil.pickAndCompress(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
        );

        // Jika user membatalkan kamera
        if (result == null) return;
        if (!context.mounted) return;

        if (targetType == 'in') {
          context.read<AttendanceBloc>().add(
            AttendanceClockInSubmitted(
              latitude: effectiveLat,
              longitude: effectiveLng,
              address: effectiveAddress,
              attendanceMethod: data.attendanceMethod,
              workLocationId: selectedLocation.id,
              photoFile: result.file,
            ),
          );
        } else {
          context.read<AttendanceBloc>().add(
            AttendanceClockOutSubmitted(
              latitude: effectiveLat,
              longitude: effectiveLng,
              address: effectiveAddress,
              attendanceMethod: data.attendanceMethod,
              workLocationId: selectedLocation.id,
              photoFile: result.file,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Kamera Gagal',
          message:
              'Terjadi kesalahan saat mengakses kamera atau mengompres foto: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: BlocConsumer<AttendanceBloc, AttendanceState>(
          listener: (context, state) {
            if (state is AttendanceLoaded) {
              if (!state.data.hasAttendanceMethod && !_hasShownNoMethodDialog) {
                _hasShownNoMethodDialog = true;
                AppDialogUtil.showError(
                  context,
                  title: 'Metode Presensi Tidak Ditemukan',
                  message:
                      'Anda belum memiliki metode presensi yang ditentukan. Hubungi admin atau atasan Anda untuk mengatur metode presensi.',
                  closeText: 'Kembali',
                  onClose: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                );
                return;
              }

              // 1. Tampilkan Dialog Sukses Presensi jika ada (Clock In / Clock Out)
              if (state.attendanceSuccess != null) {
                final info = state.attendanceSuccess!;
                AttendanceSuccessDialog.show(
                  context,
                  successInfo: info,
                  onOk: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    context.pushReplacement(
                      Routes.ATTENDANCE_LOGS,
                      extra: {'redirectToDashboardOnBack': true},
                    );
                  },
                );
                return;
              }

              if (state.actionMessage != null) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.actionMessage!),
                    backgroundColor: AppColors.brandTeal,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state.errorMessage != null) {
                AppDialogUtil.showError(
                  context,
                  title: 'Gagal',
                  message: state.errorMessage!,
                );
              }
            } else if (state is AttendanceFailure) {
              final isNotFound = state.isNotFound;
              final l10n = AppLocalizations.of(context);
              AppDialogUtil.showError(
                context,
                title: isNotFound
                    ? (l10n?.notice ?? 'Pemberitahuan')
                    : (l10n?.failedToLoadAttendance ?? 'Gagal Memuat Absensi'),
                message: state.message,
                closeText: isNotFound
                    ? l10n?.back ?? 'Kembali'
                    : l10n?.close ?? 'Tutup',
                onClose: isNotFound
                    ? () => Navigator.of(context).maybePop()
                    : null,
                onRetry: isNotFound
                    ? null
                    : () {
                        context.read<AttendanceBloc>().add(
                          const AttendanceFetchRequested(),
                        );
                      },
              );
            }
          },
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
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
                            ? (l10n?.scheduleNotice ?? 'Pemberitahuan Jadwal')
                            : (l10n?.failedToLoadAttendance ??
                                  'Gagal memuat absensi'),
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.surfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isNotFound)
                        AppButton(
                          text: l10n?.back ?? 'Kembali',
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      else
                        AppButton(
                          text: l10n?.retry ?? 'Coba Lagi',
                          onPressed: () {
                            context.read<AttendanceBloc>().add(
                              const AttendanceFetchRequested(),
                            );
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
                final fetchFuture = context.read<AttendanceBloc>().stream.firstWhere(
                  (s) => s is AttendanceLoaded || s is AttendanceFailure,
                );
                context.read<AttendanceBloc>().add(
                  const AttendanceFetchRequested(isRefresh: true),
                );
                unawaited(_requestGpsLocation());
                await fetchFuture;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top App Bar (SliverAppBar floating & snap - hide on scroll down, show on scroll up)
                  AttendanceTopAppBar(
                    title: l10n?.attendanceTitle ?? 'Attendance & Check-In',
                    subtitle: '${data.companyName} • ${data.departmentName}',
                    isUpdatingLocation: _isUpdatingLocation,
                    onUpdateLocationPressed: _isUpdatingLocation
                        ? null
                        : () => _requestGpsLocation(showFeedback: true),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                          isAnyWhere:
                              data.selectedWorkLocation?.isAnyWhere ?? false,
                          hasWorkLocation: data.hasWorkLocation,
                          isGpsAcquired: loaded.isGpsAcquired,
                          officeName: data.officeName,
                        ),
                        const SizedBox(height: 16),

                        // 2. Work Location Card (Picker & Switcher)
                        AttendanceWorkLocationCard(
                          selectedLocation: data.selectedWorkLocation,
                          availableLocations: data.availableWorkLocations,
                          onLocationChanged: (newLocation) {
                            context.read<AttendanceBloc>().add(
                              AttendanceWorkLocationChanged(newLocation),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // 2.1 Day Off Informational Banner
                        if (data.isDayOff) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainerHighest
                                  : AppColors.warningContainer.withValues(alpha: 0.6),
                              borderRadius: AppRadius.borderLg,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkOutlineMuted
                                    : AppColors.warning.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceContainerHigh
                                        : AppColors.warningContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.calendarOff,
                                    color: isDark
                                        ? AppColors.warning
                                        : AppColors.onWarningContainer,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.dayOffNotice ?? 'Jadwal Libur Kerja',
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.darkOnSurface
                                              : AppColors.onWarningContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n?.dayOffDescription ??
                                            'Hari ini Anda tidak memiliki jadwal kerja aktif (Hari Libur).',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkOnSurfaceVariant
                                              : AppColors.onWarningContainer.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (!data.hasSchedule) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainerHighest
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: AppRadius.borderLg,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkOutlineMuted
                                    : AppColors.outlineMuted,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceContainerHigh
                                        : AppColors.surfaceContainerLowest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.calendarX,
                                    color: isDark
                                        ? AppColors.darkOnSurfaceVariant
                                        : AppColors.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.scheduleNotice ?? 'Pemberitahuan Jadwal',
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.darkOnSurface
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n?.noWorkSchedule ?? 'Tidak Ada Jadwal Kerja',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkOnSurfaceVariant
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3. Realtime Server Clock Card (Without 'WIB')
                        AttendanceServerClockCard(
                          serverTime: loaded.currentClockTime,
                          clockTimeString: loaded.formattedClockTime,
                          timezone: data.timezone,
                          shiftName: data.shiftName,
                          isDayOff: data.isDayOff,
                          hasSchedule: data.hasSchedule,
                        ),
                        const SizedBox(height: 16),

                        // 4. User & Office Info Card
                        AttendanceEmployeeCard(
                          employeeName: data.employeeName,
                          employeeRole: data.employeeRole,
                          employeeId: data.employeeId,
                          photoUrl: data.photoUrl,
                        ),
                        const SizedBox(height: 16),

                        // 5. Timeline Section (Clock In, Break Session, Clock Out)
                        AttendanceTimelineSection(
                          inTime: data.inTime,
                          outTime: data.outTime,
                          breakOutTime: data.breakOutTime,
                          breakInTime: data.breakInTime,
                          isClockedIn: data.isClockedIn,
                          isClockedOut: data.isClockedOut,
                        ),
                        const SizedBox(height: 20),

                        // 6. Action Buttons (Clock In Now, Start Break, Report Location Issue)
                        AttendanceActionButtons(
                          isClockedIn: data.isClockedIn,
                          isClockedOut: data.isClockedOut,
                          isOnBreak: data.isOnBreak,
                          isLoading: loaded.isSubmittingAction,
                          hasWorkLocation: data.hasWorkLocation,
                          breakOutTime: data.breakOutTime,
                          attendanceMethod: data.attendanceMethod,
                          isDayOff: data.isDayOff,
                          onClockPressed: () => _handleClockAction(
                            context,
                            state: loaded,
                          ),
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
