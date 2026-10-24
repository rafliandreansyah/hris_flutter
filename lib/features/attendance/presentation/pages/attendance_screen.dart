import 'dart:async';
import 'dart:io';
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
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/models/attendance_today_data.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_flutter/features/attendance/presentation/pages/liveness_camera_screen.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_action_buttons.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_break_sheet.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_geofence_map_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_break_sessions_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_compact_header.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_status_strip.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_success_dialog.dart';
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
  bool _isShowingSuccessDialog = false;

  /// Perkiraan tinggi header melayang (di luar status bar) untuk padding kamera peta.
  static const double _headerHeight = 196;

  @override
  void initState() {
    super.initState();
    _requestGpsLocation();
  }

  /// Muat ulang data presensi sekaligus posisi GPS.
  void _refresh() {
    context.read<AttendanceBloc>().add(
      const AttendanceFetchRequested(isRefresh: true),
    );
    unawaited(_requestGpsLocation(showFeedback: true));
  }

  void _openLocationPicker(BuildContext context, AttendanceLoaded loaded) {
    final data = loaded.data;
    if (data.availableWorkLocations.length < 2) return;
    AttendanceWorkLocationCard(
      selectedLocation: data.selectedWorkLocation,
      availableLocations: data.availableWorkLocations,
      onLocationChanged: (newLocation, {setAsDefault = false}) {
        context.read<AttendanceBloc>().add(
          AttendanceWorkLocationChanged(
            newLocation,
            setAsDefault: setAsDefault,
          ),
        );
      },
    ).showPicker(context);
  }

  void _showBreakHistory(BuildContext context, AttendanceLoaded loaded) {
    final status = loaded.breakStatus;
    if (status == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: AttendanceBreakSessionsCard(status: status),
        ),
      ),
    );
  }

  void _reportGpsIssue(AttendanceGpsIssue issue) {
    if (mounted) {
      context.read<AttendanceBloc>().add(AttendanceGpsIssueReported(issue));
    }
  }

  void _pushLocation(Position position) {
    if (!mounted) return;
    context.read<AttendanceBloc>().add(
      AttendanceLocationUpdated(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isInsideGeofence: true,
      ),
    );
  }

  /// Mengambil GPS user. Kegagalan (izin / GPS mati / timeout) dilaporkan ke bloc
  /// agar tampil jelas di status banner, bukan snackbar singkat.
  Future<Position?> _requestGpsLocation({bool showFeedback = false}) async {
    if (showFeedback && mounted) {
      setState(() => _isUpdatingLocation = true);
    }

    try {
      final locResult = await PermissionUtil.requestLocationPermission(
        context: context,
        showRationale: showFeedback,
      );
      if (!locResult.isGranted) {
        _reportGpsIssue(AttendanceGpsIssue.permissionDenied);
        return null;
      }

      // Pastikan saklar layanan GPS perangkat dalam keadaan aktif
      if (mounted) {
        final gpsEnabled = await PermissionUtil.ensureLocationServiceEnabled(
          context,
          promptToEnable: showFeedback,
        );
        if (!gpsEnabled) {
          _reportGpsIssue(AttendanceGpsIssue.serviceDisabled);
          return null;
        }
      }

      // 1. Lokasi terakhir (cached) secara instan agar banner cepat berubah
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position != null) _pushLocation(position);
      } catch (silentError) {
        debugPrint('[diabaikan] $silentError');
      }

      // 2. GPS akurat dengan batas waktu (4 dtk bila sudah ada posisi, 6 dtk cold start)
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: position != null ? 4 : 6),
          ),
        );
        _pushLocation(position);
      } catch (_) {
        // Fallback cepat via jaringan seluler/Wi-Fi bila belum ada posisi sama sekali
        if (position == null) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 3),
            ),
          );
          _pushLocation(position);
        }
      }
      return position;
    } catch (_) {
      _reportGpsIssue(AttendanceGpsIssue.unavailable);
      return null;
    } finally {
      if (mounted && _isUpdatingLocation) {
        setState(() => _isUpdatingLocation = false);
      }
    }
  }

  /// Mulai / selesai istirahat: konfirmasi via bottom sheet (catatan opsional),
  /// lalu kirim event ke bloc yang memanggil API.
  Future<void> _handleBreakAction(
    BuildContext context, {
    required AttendanceLoaded state,
  }) async {
    final isEnding = state.data.isOnBreak;
    final note = await showAttendanceBreakSheet(
      context,
      isEnding: isEnding,
      isGpsReady: state.isGpsAcquired,
      status: state.breakStatus,
    );
    if (note == null || !context.mounted) return;

    context.read<AttendanceBloc>().add(
      isEnding
          ? AttendanceBreakEnded(note: note)
          : AttendanceBreakStarted(note: note),
    );
  }

  Future<void> _handleClockAction(
    BuildContext context, {
    required AttendanceLoaded state,
  }) async {
    final data = state.data;

    // 1. Pengecekan apakah sudah absen masuk dan pulang
    if (data.isClockedIn && data.isClockedOut) {
      AppDialogUtil.showSuccess(
        context,
        title: 'Presensi Selesai',
        message: 'Presensi kehadiran hari ini sudah selesai.',
        buttonText: 'Mengerti',
      );
      return;
    }

    // 1b. Istirahat masih berjalan: server menutupnya otomatis saat clock-out
    if (data.isClockedIn && !data.isClockedOut && data.isOnBreak) {
      var confirmed = false;
      await AppDialogUtil.showWarning(
        context,
        title: 'Istirahat Masih Berjalan',
        message:
            'Istirahat Anda akan diselesaikan otomatis saat Clock Out. Lanjutkan?',
        confirmText: 'Lanjut Clock Out',
        onConfirm: () => confirmed = true,
      );
      if (!confirmed || !context.mounted) return;
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

    // 4. Validasi GPS & radius kantor (kecuali lokasi kerja adalah isAnyWhere)
    final isAnyWhere = selectedLocation.isAnyWhere;
    if (!isAnyWhere && !state.isGpsAcquired) {
      AppDialogUtil.showWarning(
        context,
        title: 'Lokasi Belum Terdeteksi',
        message: switch (state.gpsIssue) {
          AttendanceGpsIssue.permissionDenied =>
            'Izin lokasi belum diberikan, jadi kami belum bisa memastikan Anda berada di area kerja. Izinkan akses lokasi lalu coba lagi.',
          AttendanceGpsIssue.serviceDisabled =>
            'GPS perangkat Anda mati. Aktifkan GPS/Lokasi lalu coba lagi.',
          _ =>
            'Posisi Anda belum ditemukan. Tunggu GPS terkunci atau pindah ke area terbuka, lalu coba lagi.',
        },
        confirmText: 'Perbarui Lokasi',
        cancelText: 'Kembali',
        onConfirm: () => _requestGpsLocation(showFeedback: true),
      );
      return;
    }
    if (!isAnyWhere && !state.isInsideGeofence) {
      final dist = state.distanceToOfficeMeters;
      final distText = dist == null
          ? ''
          : 'Posisi Anda sekitar ${dist >= 1000 ? '${(dist / 1000).toStringAsFixed(1)} km' : '${dist.toStringAsFixed(0)} m'} dari ${data.officeName}. ';
      AppDialogUtil.showError(
        context,
        title: 'Anda Di Luar Radius Kantor',
        message:
            '${distText}Presensi hanya bisa dilakukan dalam radius ${data.geofenceRadiusMeters.toStringAsFixed(0)} m. Dekati area kantor, atau ganti lokasi kerja bila Anda bertugas di tempat lain.',
        retryText: 'Perbarui Lokasi',
        onRetry: () => _requestGpsLocation(showFeedback: true),
        closeText: 'Kembali',
      );
      return;
    }

    // 5. Koordinat GPS & data lokasi
    final double effectiveLat = state.userLatitude ?? data.officeLatitude;
    final double effectiveLng = state.userLongitude ?? data.officeLongitude;
    final String effectiveAddress = data.officeDetail;
    final String targetType = !data.isClockedIn ? 'in' : 'out';

    // 6. Eksekusi berdasarkan metode dari server (liveness vs biometric vs photo)
    if (data.isLivenessMethod) {
      final permissionsGranted =
          await PermissionUtil.requestAttendancePermissions(context: context);
      if (!permissionsGranted) return;
      if (!context.mounted) return;

      try {
        final File? capturedFile = await Navigator.of(context).push<File?>(
          MaterialPageRoute(builder: (_) => const LivenessCameraScreen()),
        );

        if (capturedFile == null) return;
        if (!context.mounted) return;

        final photoFile = XFile(capturedFile.path);

        if (targetType == 'in') {
          context.read<AttendanceBloc>().add(
            AttendanceClockInSubmitted(
              latitude: effectiveLat,
              longitude: effectiveLng,
              address: effectiveAddress,
              attendanceMethod: 'liveness',
              workLocationId: selectedLocation.id,
              photoFile: photoFile,
            ),
          );
        } else {
          context.read<AttendanceBloc>().add(
            AttendanceClockOutSubmitted(
              latitude: effectiveLat,
              longitude: effectiveLng,
              address: effectiveAddress,
              attendanceMethod: 'liveness',
              workLocationId: selectedLocation.id,
              photoFile: photoFile,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Liveness AI Gagal',
          message: 'Terjadi kesalahan saat memproses presensi liveness: $e',
        );
      }
    } else if (data.isBiometricMethod) {
      final locGranted = await PermissionUtil.requestLocationPermission(
        context: context,
      );
      if (!locGranted.isGranted) return;
      if (!context.mounted) return;

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
      // Pastikan izin Presensi (Lokasi + Kamera) aktif via rationale dialog
      final permissionsGranted =
          await PermissionUtil.requestAttendancePermissions(context: context);
      if (!permissionsGranted) return;
      if (!context.mounted) return;

      try {
        final result = await ImageCompressUtil.pickAndCompress(
          context: context,
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

    final currentState = context.watch<AttendanceBloc>().state;

    return Scaffold(
      backgroundColor: scaffoldBg,
      bottomNavigationBar: currentState is AttendanceLoaded
          ? _buildBottomBar(context, currentState, isDark)
          : null,
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listenWhen: (previous, current) {
          if (previous is AttendanceLoaded && current is AttendanceLoaded) {
            return previous.attendanceSuccess != current.attendanceSuccess ||
                previous.actionMessage != current.actionMessage ||
                previous.errorMessage != current.errorMessage ||
                previous.data.hasAttendanceMethod !=
                    current.data.hasAttendanceMethod;
          }
          return previous != current;
        },
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
            if (state.attendanceSuccess != null && !_isShowingSuccessDialog) {
              _isShowingSuccessDialog = true;
              final info = state.attendanceSuccess!;
              AttendanceSuccessDialog.show(
                context,
                successInfo: info,
                onOk: () {
                  _isShowingSuccessDialog = false;
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
              AppDialogUtil.showSuccess(
                context,
                title: 'Berhasil',
                message: state.actionMessage!,
              );
            } else if (state.errorMessage != null) {
              AppDialogUtil.showError(
                context,
                title: 'Presensi Gagal Dikirim',
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
            return SafeArea(child: _buildShimmerLoading(isDark));
          }

          if (state is AttendanceFailure) {
            final isNotFound = state.isNotFound;

            return SafeArea(
              child: Center(
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

          final topInset = MediaQuery.paddingOf(context).top;

          return Stack(
            children: [
              // Peta penuh layar: posisi user & radius kantor terlihat jelas
              Positioned.fill(
                child: AttendanceGeofenceMapCard(
                  fullscreen: true,
                  mapPadding: EdgeInsets.only(
                    top: topInset + _headerHeight,
                    bottom: AppSpacing.sm,
                  ),
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
                  officeName: data.officeName,
                  distanceMeters: loaded.distanceToOfficeMeters,
                  isRefreshingLocation: _isUpdatingLocation,
                  onRefreshLocation: _refresh,
                ),
              ),

              // Header ringkas melayang: lokasi, jam, shift, Masuk/Istirahat/Pulang
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm + AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.sm + AppSpacing.xs,
                      0,
                    ),
                    child: AttendanceCompactHeader(
                      state: loaded,
                      onLocationTap: () => _openLocationPicker(context, loaded),
                      onBreakTap: () => _showBreakHistory(context, loaded),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Bar aksi yang selalu terlihat di bawah layar (tidak ikut scroll).
  Widget _buildBottomBar(
    BuildContext context,
    AttendanceLoaded loaded,
    bool isDark,
  ) {
    final data = loaded.data;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AttendanceStatusStrip(
                state: loaded,
                isBusy: _isUpdatingLocation,
                onAction: () => _requestGpsLocation(showFeedback: true),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              AttendanceActionButtons(
                isClockedIn: data.isClockedIn,
                isClockedOut: data.isClockedOut,
                isOnBreak: data.isOnBreak,
                isLoading: loaded.isSubmittingAction,
                hasWorkLocation: data.hasWorkLocation,
                attendanceMethod: data.attendanceMethod,
                onClockPressed: () =>
                    _handleClockAction(context, state: loaded),
                onBreakPressed: () =>
                    _handleBreakAction(context, state: loaded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.darkOnBackground;
    final highlightColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.backgroundSubtle;

    Widget block(double height, {double radius = AppRadius.xl}) => Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            block(_headerHeight - AppSpacing.md), // header ringkas
            const SizedBox(height: AppSpacing.md),
            Expanded(child: block(double.infinity)), // peta
            const SizedBox(height: AppSpacing.md),
            block(72, radius: AppRadius.lg), // status
            const SizedBox(height: AppSpacing.sm),
            block(56, radius: AppRadius.full), // tombol
          ],
        ),
      ),
    );
  }
}
