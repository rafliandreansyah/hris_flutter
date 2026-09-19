import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:hris_flutter/core/widgets/app_realtime_map_card.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_request_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/live_attendance/live_attendance_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Presensi Luar (Live) - Oasish Outside Office Live Attendance Screen.
///
/// Fitur:
/// - Jam server live WIB tersinkronisasi real-time.
/// - Segmented switch jenis presensi: Absen Masuk (In) / Absen Pulang (Out).
/// - Peta GPS real-time (tanpa teks alamat statis pada kartu peta).
/// - Pengisian alamat otomatis ke server melalui reverse geocoding Mapbox.
/// - Input Alasan presensi luar kantor ber-asterisk merah wajib.
/// - Mode Foto (Strict Camera-Only, tanpa galeri) & Mode Biometrik (Fingerprint / Face ID tanpa foto).
/// - Konfirmasi pengiriman dan umpan balik via [AppDialogUtil] (`pro_dialog`).
class LiveAttendanceScreen extends StatelessWidget {
  final AttendanceRequestRepository? repository;
  final AttendanceRepository? attendanceRepository;
  final LiveAttendanceBloc? bloc;
  final String? initialMethod;
  final ImagePicker? imagePicker;

  const LiveAttendanceScreen({
    super.key,
    this.repository,
    this.attendanceRepository,
    this.bloc,
    this.initialMethod,
    this.imagePicker,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<LiveAttendanceBloc>.value(
        value: bloc!,
        child: _LiveAttendanceView(imagePicker: imagePicker),
      );
    }

    return BlocProvider<LiveAttendanceBloc>(
      create: (context) {
        AttendanceRequestRepository reqRepo;
        if (repository != null) {
          reqRepo = repository!;
        } else {
          try {
            reqRepo = context.read<AttendanceRequestRepository>();
          } catch (_) {
            reqRepo = AttendanceRequestRepositoryImpl();
          }
        }

        AttendanceRepository? attRepo;
        if (attendanceRepository != null) {
          attRepo = attendanceRepository;
        } else {
          try {
            attRepo = context.read<AttendanceRepository>();
          } catch (_) {
            attRepo = AttendanceRepositoryImpl();
          }
        }

        return LiveAttendanceBloc(
          repository: reqRepo,
          attendanceRepository: attRepo,
        )..add(LiveAttendanceStarted(initialMethod: initialMethod));
      },
      child: _LiveAttendanceView(imagePicker: imagePicker),
    );
  }
}

class _LiveAttendanceView extends StatefulWidget {
  final ImagePicker? imagePicker;

  const _LiveAttendanceView({this.imagePicker});

  @override
  State<_LiveAttendanceView> createState() => _LiveAttendanceViewState();
}

class _LiveAttendanceViewState extends State<_LiveAttendanceView> {
  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<AppRealtimeMapCardState> _mapCardKey =
      GlobalKey<AppRealtimeMapCardState>();
  late final ImagePicker _imagePicker;

  ImageCompressResult? _compressResult;
  bool _isCompressing = false;
  bool _isSuccessDialogShown = false;

  static const List<String> _monthsId = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? ImagePicker();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatWibDateTime(DateTime dt) {
    final day = dt.day;
    final month = _monthsId[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute:$second WIB';
  }

  /// Membuka kamera depan secara langsung untuk mengambil foto selfie presensi.
  /// Strictly Camera-Only (tanpa opsi galeri).
  Future<void> _captureCameraSelfie() async {
    final camResult = await PermissionUtil.requestCameraPermission(
      context: context,
      showRationale: true,
    );

    if (!camResult.isGranted) return;
    if (!mounted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() => _isCompressing = true);

        final compressed = await ImageCompressUtil.compressXFile(
          picked,
          maxSizeBytes: ImageCompressUtil.defaultMaxSizeBytes,
        );

        if (mounted) {
          setState(() {
            _compressResult = compressed;
            _isCompressing = false;
          });
          context.read<LiveAttendanceBloc>().add(
                LiveAttendancePhotoChanged(compressed.file),
              );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressing = false);
        AppDialogUtil.showError(
          context,
          title: 'Gagal Membuka Kamera',
          message: 'Terjadi kendala saat mengakses kamera perangkat: $e',
        );
      }
    }
  }

  void _clearPhoto() {
    setState(() {
      _compressResult = null;
    });
    context
        .read<LiveAttendanceBloc>()
        .add(const LiveAttendancePhotoChanged(null));
  }

  Future<void> _handleSubmission(
    BuildContext context,
    LiveAttendanceState state,
  ) async {
    if (!state.hasValidCoordinates) {
      AppDialogUtil.showWarning(
        context,
        title: 'Lokasi Belum Terdeteksi',
        message:
            'Koordinat GPS belum ditemukan. Harap tunggu hingga GPS terkunci atau tekan tombol "Perbarui Koordinat GPS".',
      );
      return;
    }

    if (state.reason.trim().isEmpty) {
      AppDialogUtil.showWarning(
        context,
        title: 'Form Belum Lengkap',
        message: 'Alasan presensi luar kantor wajib diisi.',
      );
      return;
    }

    // Mode Foto: wajib ada foto selfie
    if (state.isPhotoMethod && state.photo == null) {
      AppDialogUtil.showWarning(
        context,
        title: 'Foto Belum Diambil',
        message:
            'Foto bukti kehadiran / selfie wajib diambil menggunakan kamera.',
      );
      return;
    }

    // Mode Biometrik: autentikasi sensor biometrik (Fingerprint / Face ID) sebelum kirim
    if (state.isBiometricMethod) {
      try {
        final authenticated = await BiometricService.instance.authenticate(
          localizedReason:
              'Pindai sidik jari atau wajah Anda untuk konfirmasi presensi ${state.attendanceType == "in" ? "Masuk" : "Pulang"} (Live)',
        );

        if (!authenticated) return;
        if (!context.mounted) return;
      } on BiometricException catch (e) {
        if (!context.mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Autentikasi Biometrik Gagal',
          message: e.message,
        );
        return;
      }
    }

    if (!context.mounted) return;
    _isSuccessDialogShown = false;
    context.read<LiveAttendanceBloc>().add(const LiveAttendanceSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);

    return BlocConsumer<LiveAttendanceBloc, LiveAttendanceState>(
      listenWhen: (previous, current) {
        return (previous.submissionSuccess != current.submissionSuccess &&
                current.submissionSuccess) ||
            (previous.errorMessage != current.errorMessage &&
                current.errorMessage != null &&
                !current.isSubmitting);
      },
      listener: (context, state) {
        if (state.submissionSuccess && !_isSuccessDialogShown) {
          _isSuccessDialogShown = true;
          AppDialogUtil.showSuccess(
            context,
            title: 'Presensi Live Berhasil',
            message:
                state.successMessage ?? 'Presensi live berhasil dikirim ke server.',
            buttonText: 'Selesai',
            onOk: () {
              if (context.mounted) {
                context.pop(true);
              }
            },
          );
        } else if (state.errorMessage != null && !state.isSubmitting) {
          AppDialogUtil.showError(
            context,
            title: 'Gagal Mengirim Presensi',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final lat = state.latitude ?? -6.2088;
        final lng = state.longitude ?? 106.8456;

        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: surfaceCol,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                color: textCol,
              ),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presensi Luar (Live)',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Check-in / Check-out real-time di lokasi tugas',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  LucideIcons.locateFixed,
                  color: AppColors.brandTeal,
                  size: 20,
                ),
                tooltip: 'Pusatkan ke Lokasi Saya',
                onPressed: () {
                  _mapCardKey.currentState?.refreshLocation();
                },
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: borderCol,
                height: 1,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card 1: Waktu Server & Pilihan Presensi ────────────
                _buildTimeAndTypeCard(
                  context: context,
                  state: state,
                  isDark: isDark,
                  surfaceCol: surfaceCol,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                ),

                const SizedBox(height: 16),

                // ── Card 2: Peta Lokasi GPS (Tanpa Alamat pada Map) ─────
                _buildMapLocationCard(
                  context: context,
                  state: state,
                  lat: lat,
                  lng: lng,
                  isDark: isDark,
                  surfaceCol: surfaceCol,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                ),

                const SizedBox(height: 16),

                // ── Card 3: Form Alasan & Bukti Verifikasi ──────────────
                _buildFormSectionCard(
                  context: context,
                  state: state,
                  isDark: isDark,
                  surfaceCol: surfaceCol,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomActionBar(
            context: context,
            state: state,
            isDark: isDark,
            surfaceCol: surfaceCol,
            borderCol: borderCol,
          ),
        );
      },
    );
  }

  /// Card 1: Jam Live WIB & Switcher Presensi Masuk / Pulang
  Widget _buildTimeAndTypeCard({
    required BuildContext context,
    required LiveAttendanceState state,
    required bool isDark,
    required Color surfaceCol,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    final isClockIn = state.attendanceType == 'in';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCol,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Jam Live WIB
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.brandTeal.withValues(alpha: 0.15)
                  : const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    color: AppColors.brandTeal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatWibDateTime(state.currentClockTime),
                        key: const Key('live-attendance-clock-text'),
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sinkronisasi Waktu Server Standar WIB',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11,
                          color: subtitleCol,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Segmented Switcher Masuk (In) / Pulang (Out)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: 1),
            ),
            child: Row(
              children: [
                // Tombol Masuk
                Expanded(
                  child: InkWell(
                    key: const Key('live-attendance-type-in'),
                    onTap: () {
                      context
                          .read<LiveAttendanceBloc>()
                          .add(const LiveAttendanceTypeChanged('in'));
                    },
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isClockIn
                            ? (isDark
                                ? AppColors.brandTeal.withValues(alpha: 0.25)
                                : const Color(0xFFF0FDFA))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: isClockIn
                            ? Border.all(
                                color: AppColors.brandTeal,
                                width: 1.5,
                              )
                            : Border.all(color: Colors.transparent, width: 1.5),
                        boxShadow: isClockIn
                            ? [
                                BoxShadow(
                                  color: AppColors.brandTeal
                                      .withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Absen Masuk (In)',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight:
                              isClockIn ? FontWeight.w700 : FontWeight.w500,
                          color: isClockIn ? AppColors.brandTeal : subtitleCol,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Tombol Pulang
                Expanded(
                  child: InkWell(
                    key: const Key('live-attendance-type-out'),
                    onTap: () {
                      context
                          .read<LiveAttendanceBloc>()
                          .add(const LiveAttendanceTypeChanged('out'));
                    },
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isClockIn
                            ? (isDark
                                ? AppColors.brandTeal.withValues(alpha: 0.25)
                                : const Color(0xFFF0FDFA))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: !isClockIn
                            ? Border.all(
                                color: AppColors.brandTeal,
                                width: 1.5,
                              )
                            : Border.all(color: Colors.transparent, width: 1.5),
                        boxShadow: !isClockIn
                            ? [
                                BoxShadow(
                                  color: AppColors.brandTeal
                                      .withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Absen Pulang (Out)',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight:
                              !isClockIn ? FontWeight.w700 : FontWeight.w500,
                          color: !isClockIn ? AppColors.brandTeal : subtitleCol,
                          fontSize: 13,
                        ),
                      ),
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

  /// Card 2: Peta GPS Real-Time (Tanpa Teks Alamat Statis)
  Widget _buildMapLocationCard({
    required BuildContext context,
    required LiveAttendanceState state,
    required double lat,
    required double lng,
    required bool isDark,
    required Color surfaceCol,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    return Column(
      children: [
        AppRealtimeMapCard(
          key: _mapCardKey,
          title: 'Lokasi Presensi',
          latitude: lat,
          longitude: lng,
          gpsAccuracy: state.gpsAccuracy,
          mapHeight: 150.0,
          enableTracking: true,
          showOpenInMaps: true,
          onLocationChanged: (newLat, newLng, accuracy) {
            context.read<LiveAttendanceBloc>().add(
                  LiveAttendanceLocationUpdated(
                    latitude: newLat,
                    longitude: newLng,
                    accuracy: accuracy,
                  ),
                );
          },
        ),

        const SizedBox(height: 10),

        // Tombol Outlined "Perbarui Koordinat GPS"
        SizedBox(
          width: double.infinity,
          height: 44,
          child: AppButton(
            key: const Key('live-attendance-refresh-gps-button'),
            text: 'Perbarui Koordinat GPS',
            variant: AppButtonVariant.outlined,
            leadingIcon: LucideIcons.refreshCw,
            textStyle: AppTypography.labelMedium.copyWith(
              color: AppColors.brandTeal,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            onPressed: () {
              _mapCardKey.currentState?.refreshLocation();
            },
          ),
        ),
      ],
    );
  }

  /// Card 3: Form Alasan & Bukti Verifikasi Kehadiran
  Widget _buildFormSectionCard({
    required BuildContext context,
    required LiveAttendanceState state,
    required bool isDark,
    required Color surfaceCol,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCol,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Alasan Presensi Luar Kantor (Wajib Bintang Merah)
          AppTextField(
            key: const Key('live-attendance-reason-input'),
            label: 'Alasan Presensi Luar Kantor *',
            controller: _reasonController,
            hintText: 'Tuliskan alasan atau keterangan pekerjaan di lokasi ini...',
            maxLines: 3,
            isRequired: true,
            prefixIcon: LucideIcons.fileText,
            onChanged: (val) {
              context
                  .read<LiveAttendanceBloc>()
                  .add(LiveAttendanceReasonChanged(val));
            },
          ),

          const SizedBox(height: 20),

          // Section 2: Verifikasi Kehadiran (Mode Foto vs Mode Biometrik)
          if (state.isPhotoMethod)
            _buildPhotoSection(
              context: context,
              state: state,
              isDark: isDark,
              borderCol: borderCol,
              textCol: textCol,
              subtitleCol: subtitleCol,
            )
          else
            _buildBiometricSection(
              context: context,
              isDark: isDark,
              borderCol: borderCol,
              textCol: textCol,
              subtitleCol: subtitleCol,
            ),
        ],
      ),
    );
  }

  /// Tampilan Verifikasi Foto Selfie (Strict Camera-Only)
  Widget _buildPhotoSection({
    required BuildContext context,
    required LiveAttendanceState state,
    required bool isDark,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    final photo = state.photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Foto Bukti Kehadiran
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Foto Bukti Kehadiran / Selfie',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textCol,
                    fontSize: 13,
                  ),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerHigh
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Metode: Photo Verification',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: subtitleCol,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Kotak Pengambilan Foto Kamera
        if (photo == null)
          InkWell(
            key: const Key('live-attendance-camera-trigger'),
            onTap: _isCompressing ? null : _captureCameraSelfie,
            borderRadius: BorderRadius.circular(14),
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color: AppColors.brandTeal.withValues(alpha: 0.6),
                strokeWidth: 1.5,
                dashPattern: const [6, 4],
                radius: const Radius.circular(14),
              ),
              childOnTop: true,
              child: Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.brandTeal.withValues(alpha: 0.08)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isCompressing
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.brandTeal,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandTeal
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              size: 26,
                              color: AppColors.brandTeal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ketuk untuk Ambil Foto Selfie via Kamera',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.brandTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kamera Depan Selfie (Maksimal 100 KB)',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          )
        else
          // Pratinjau Foto yang sudah diambil
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol, width: 1),
            ),
            child: Row(
              children: [
                // Thumbnail Gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(photo.path),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto Selfie Berhasil Diambil',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textCol,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (_compressResult != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTeal
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tersimpan: ${_compressResult!.compressedSizeFormatted}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandTeal,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Tombol Intip Foto
                          InkWell(
                            onTap: () {
                              AppImagePreviewDialog.show(
                                context,
                                xFile: photo,
                                title: 'Foto Selfie Presensi',
                              );
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.eye,
                                  size: 14,
                                  color: AppColors.brandTeal,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Intip Foto',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Tombol Ambil Ulang (Kamera Saja)
                          InkWell(
                            onTap: _captureCameraSelfie,
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.camera,
                                  size: 14,
                                  color: AppColors.brandTeal,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ambil Ulang',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Tombol Hapus
                          InkWell(
                            onTap: _clearPhoto,
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  size: 14,
                                  color: AppColors.errorRed,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Hapus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Tampilan Verifikasi Biometrik (Fingerprint / Face ID tanpa upload foto)
  Widget _buildBiometricSection({
    required BuildContext context,
    required bool isDark,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Verifikasi Identitas Biometrik',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textCol,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerHigh
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Metode: Biometric Verification',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: subtitleCol,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.brandTeal.withValues(alpha: 0.12)
                : const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.brandTeal.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.fingerprint,
                  size: 28,
                  color: AppColors.brandTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Autentikasi Sidik Jari / Face ID',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Identitas Anda akan diverifikasi menggunakan sensor biometrik perangkat saat menekan tombol kirim. Tidak memerlukan foto selfie.',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sticky Bottom Action Bar dengan [AppButton]
  Widget _buildBottomActionBar({
    required BuildContext context,
    required LiveAttendanceState state,
    required bool isDark,
    required Color surfaceCol,
    required Color borderCol,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: surfaceCol,
        border: Border(top: BorderSide(color: borderCol, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: AppButton(
        key: const Key('live-attendance-submit-button'),
        text: 'Kirim Presensi Live Sekarang',
        variant: AppButtonVariant.primary,
        leadingIcon: LucideIcons.checkCircle,
        height: 52,
        isLoading: state.isSubmitting,
        onPressed: state.isSubmitting ? null : () => _handleSubmission(context, state),
      ),
    );
  }
}
