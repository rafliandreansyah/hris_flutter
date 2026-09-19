import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/services/biometric_service.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hris_flutter/features/attendance/data/repositories/attendance_request_repository_impl.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/schedule_attendance/schedule_attendance_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/schedule_location_picker_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ScheduleAttendanceScreen extends StatelessWidget {
  final AttendanceRequestRepository? repository;
  final AttendanceRepository? attendanceRepository;
  final ScheduleAttendanceBloc? bloc;
  final String? initialMethod;
  final ImagePicker? imagePicker;

  const ScheduleAttendanceScreen({
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
      return BlocProvider<ScheduleAttendanceBloc>.value(
        value: bloc!,
        child: _ScheduleAttendanceView(imagePicker: imagePicker),
      );
    }

    return BlocProvider<ScheduleAttendanceBloc>(
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

        return ScheduleAttendanceBloc(
          repository: reqRepo,
          attendanceRepository: attRepo,
        )..add(ScheduleAttendanceStarted(initialMethod: initialMethod));
      },
      child: _ScheduleAttendanceView(imagePicker: imagePicker),
    );
  }
}

class _ScheduleAttendanceView extends StatefulWidget {
  final ImagePicker? imagePicker;

  const _ScheduleAttendanceView({this.imagePicker});

  @override
  State<_ScheduleAttendanceView> createState() =>
      _ScheduleAttendanceViewState();
}

class _ScheduleAttendanceViewState extends State<_ScheduleAttendanceView> {
  final TextEditingController _reasonController = TextEditingController();
  late final ImagePicker _imagePicker;

  ImageCompressResult? _inCompressResult;
  ImageCompressResult? _outCompressResult;
  bool _isInCompressing = false;
  bool _isOutCompressing = false;
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

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_monthsId[dt.month - 1]} ${dt.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST') ||
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  Widget _buildMiniMapFallback({
    required bool isDark,
    required Color textCol,
    required double latitude,
    required double longitude,
  }) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mapPin, size: 14, color: AppColors.brandTeal),
            const SizedBox(width: 6),
            Text(
              '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.brandTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuka kamera depan secara langsung untuk mengambil foto selfie (Strict Camera-Only)
  Future<void> _captureCameraSelfie({required bool isIn}) async {
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
        if (isIn) {
          setState(() => _isInCompressing = true);
        } else {
          setState(() => _isOutCompressing = true);
        }

        final compressed = await ImageCompressUtil.compressXFile(
          picked,
          maxSizeBytes: ImageCompressUtil.defaultMaxSizeBytes,
        );

        if (mounted) {
          setState(() {
            if (isIn) {
              _inCompressResult = compressed;
              _isInCompressing = false;
            } else {
              _outCompressResult = compressed;
              _isOutCompressing = false;
            }
          });

          if (isIn) {
            context
                .read<ScheduleAttendanceBloc>()
                .add(ScheduleAttendanceInPhotoChanged(compressed.file));
          } else {
            context
                .read<ScheduleAttendanceBloc>()
                .add(ScheduleAttendanceOutPhotoChanged(compressed.file));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isIn) _isInCompressing = false;
          if (!isIn) _isOutCompressing = false;
        });
        AppDialogUtil.showError(
          context,
          title: 'Kamera Gagal',
          message: 'Terjadi kesalahan saat mengambil foto selfie: $e',
        );
      }
    }
  }

  void _clearPhoto({required bool isIn}) {
    setState(() {
      if (isIn) {
        _inCompressResult = null;
      } else {
        _outCompressResult = null;
      }
    });
    if (isIn) {
      context
          .read<ScheduleAttendanceBloc>()
          .add(const ScheduleAttendanceInPhotoChanged(null));
    } else {
      context
          .read<ScheduleAttendanceBloc>()
          .add(const ScheduleAttendanceOutPhotoChanged(null));
    }
  }

  /// Membuka interactive Google Maps pin picker modal untuk memilih lokasi
  Future<void> _pickLocation({required bool isIn}) async {
    final state = context.read<ScheduleAttendanceBloc>().state;
    final initialLat = isIn ? state.inLatitude : state.latitudeOut;
    final initialLng = isIn ? state.longitudeIn : state.longitudeOut;
    final initialAddr = isIn ? state.addressIn : state.addressOut;

    final result = await showScheduleLocationPickerModal(
      context,
      initialLatitude: initialLat,
      initialLongitude: initialLng,
      initialAddress: initialAddr,
      title: isIn ? 'Pilih Lokasi Absen Masuk' : 'Pilih Lokasi Absen Pulang',
    );

    if (result != null && mounted) {
      if (isIn) {
        context.read<ScheduleAttendanceBloc>().add(
              ScheduleAttendanceInLocationChanged(
                latitude: result.latitude,
                longitude: result.longitude,
                address: result.address,
              ),
            );
      } else {
        context.read<ScheduleAttendanceBloc>().add(
              ScheduleAttendanceOutLocationChanged(
                latitude: result.latitude,
                longitude: result.longitude,
                address: result.address,
              ),
            );
      }
    }
  }

  /// Membuka pemilih tanggal
  Future<void> _selectDate(BuildContext context, DateTime currentDate) async {
    final bloc = context.read<ScheduleAttendanceBloc>();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.brandTeal,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      bloc.add(ScheduleAttendanceDateChanged(picked));
    }
  }

  /// Membuka pemilih waktu
  Future<void> _selectTime(
    BuildContext context, {
    required TimeOfDay initialTime,
    required bool isIn,
  }) async {
    final bloc = context.read<ScheduleAttendanceBloc>();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.brandTeal,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      if (isIn) {
        bloc.add(ScheduleAttendanceInTimeChanged(picked));
      } else {
        bloc.add(ScheduleAttendanceOutTimeChanged(picked));
      }
    }
  }

  Future<void> _handleSubmission(
    ScheduleAttendanceState state,
  ) async {
    // 1. Validasi Alasan
    if (_reasonController.text.trim().isEmpty) {
      AppDialogUtil.showWarning(
        context,
        title: 'Form Belum Lengkap',
        message: 'Alasan pengajuan presensi terjadwal wajib diisi.',
      );
      return;
    }

    // 2. Validasi Masuk (In)
    if (state.hasIn) {
      if (!state.hasValidInLocation) {
        AppDialogUtil.showWarning(
          context,
          title: 'Lokasi Belum Dipilih',
          message: 'Silakan tentukan lokasi absen masuk menggunakan peta.',
        );
        return;
      }
      if (state.isPhotoMethod && state.inPhoto == null) {
        AppDialogUtil.showWarning(
          context,
          title: 'Foto Masuk Belum Diambil',
          message:
              'Foto selfie absen masuk wajib diambil menggunakan kamera depan.',
        );
        return;
      }
    }

    // 3. Validasi Pulang (Out)
    if (state.hasOut) {
      if (!state.hasValidOutLocation) {
        AppDialogUtil.showWarning(
          context,
          title: 'Lokasi Belum Dipilih',
          message: 'Silakan tentukan lokasi absen pulang menggunakan peta.',
        );
        return;
      }
      if (state.isPhotoMethod && state.outPhoto == null) {
        AppDialogUtil.showWarning(
          context,
          title: 'Foto Pulang Belum Diambil',
          message:
              'Foto selfie absen pulang wajib diambil menggunakan kamera depan.',
        );
        return;
      }
    }

    // 4. Verifikasi Biometrik jika mode biometric
    if (state.isBiometricMethod) {
      try {
        final authenticated = await BiometricService.instance.authenticate(
          localizedReason:
              'Verifikasi sidik jari atau Face ID Anda untuk mengajukan presensi terjadwal.',
        );
        if (!authenticated) return;
        if (!mounted) return;
      } on BiometricException catch (e) {
        if (!mounted) return;
        AppDialogUtil.showError(
          context,
          title: 'Autentikasi Biometrik Gagal',
          message: e.message,
        );
        return;
      }
    }

    if (!mounted) return;

    _isSuccessDialogShown = false;

    // Sinkronkan controller ke bloc jika belum
    context.read<ScheduleAttendanceBloc>().add(
          ScheduleAttendanceReasonChanged(_reasonController.text),
        );
    context
        .read<ScheduleAttendanceBloc>()
        .add(const ScheduleAttendanceSubmitted());
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

    return BlocConsumer<ScheduleAttendanceBloc, ScheduleAttendanceState>(
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
            title: 'Pengajuan Berhasil',
            message: state.successMessage ??
                'Pengajuan presensi terjadwal berhasil dikirim ke server.',
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
            title: 'Gagal Mengajukan Presensi',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: surfaceCol,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: textCol),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presensi Luar (Schedule)',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Ajukan jadwal presensi luar kantor terencana',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: borderCol, height: 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Switcher Tipe Presensi (In / Out / InOut) ───────────
                _buildTypeSelector(
                  context: context,
                  state: state,
                  isDark: isDark,
                  surfaceCol: surfaceCol,
                  borderCol: borderCol,
                  subtitleCol: subtitleCol,
                ),

                const SizedBox(height: 16),

                // ── Card 1: Tanggal & Waktu Presensi Terencana ─────────
                _buildDateTimeSection(
                  context: context,
                  state: state,
                  isDark: isDark,
                  surfaceCol: surfaceCol,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                ),

                const SizedBox(height: 16),

                // ── Card 2: Lokasi GPS Masuk & Pulang ──────────────────
                _buildLocationSection(
                  context: context,
                  state: state,
                  isDark: isDark,
                  surfaceCol: surfaceCol,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                ),

                const SizedBox(height: 16),

                // ── Card 3: Bukti Verifikasi (Foto / Biometrik) ─────────
                _buildVerificationSection(
                  context: context,
                  state: state,
                  isDark: isDark,
                  surfaceCol: surfaceCol,
                  borderCol: borderCol,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                ),

                const SizedBox(height: 16),

                // ── Card 4: Form Alasan & Penjelasan ───────────────────
                _buildReasonSection(
                  context: context,
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

  /// Switcher Tiga Opsi: Masuk (In), Pulang (Out), Masuk & Pulang (In & Out)
  Widget _buildTypeSelector({
    required BuildContext context,
    required ScheduleAttendanceState state,
    required bool isDark,
    required Color surfaceCol,
    required Color borderCol,
    required Color subtitleCol,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Row(
        children: [
          _buildTypeOption(
            context: context,
            key: const Key('schedule-type-in'),
            label: 'Masuk (In)',
            isSelected: state.attendanceType == 'in',
            onTap: () {
              context
                  .read<ScheduleAttendanceBloc>()
                  .add(const ScheduleAttendanceTypeChanged('in'));
            },
            isDark: isDark,
            subtitleCol: subtitleCol,
          ),
          const SizedBox(width: 4),
          _buildTypeOption(
            context: context,
            key: const Key('schedule-type-out'),
            label: 'Pulang (Out)',
            isSelected: state.attendanceType == 'out',
            onTap: () {
              context
                  .read<ScheduleAttendanceBloc>()
                  .add(const ScheduleAttendanceTypeChanged('out'));
            },
            isDark: isDark,
            subtitleCol: subtitleCol,
          ),
          const SizedBox(width: 4),
          _buildTypeOption(
            context: context,
            key: const Key('schedule-type-inout'),
            label: 'Masuk & Pulang',
            isSelected: state.attendanceType == 'inout',
            onTap: () {
              context
                  .read<ScheduleAttendanceBloc>()
                  .add(const ScheduleAttendanceTypeChanged('inout'));
            },
            isDark: isDark,
            subtitleCol: subtitleCol,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required BuildContext context,
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color subtitleCol,
  }) {
    return Expanded(
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.brandTeal.withValues(alpha: 0.25)
                    : const Color(0xFFF0FDFA))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: isSelected
                ? Border.all(color: AppColors.brandTeal, width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.brandTeal : subtitleCol,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Card 1: Tanggal & Waktu Presensi Terencana
  Widget _buildDateTimeSection({
    required BuildContext context,
    required ScheduleAttendanceState state,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'TANGGAL & WAKTU PRESENSI TERENCANA',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.brandTeal,
                fontSize: 11.5,
                letterSpacing: 0.5,
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
          ),
          const SizedBox(height: 14),

          // Date Picker Card
          InkWell(
            key: const Key('schedule-date-picker-trigger'),
            onTap: () => _selectDate(context, state.selectedDate),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderCol, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatDate(state.selectedDate),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textCol,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronDown, size: 16, color: subtitleCol),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Time Grid (In & Out)
          Row(
            children: [
              if (state.hasIn)
                Expanded(
                  child: InkWell(
                    key: const Key('schedule-time-in-trigger'),
                    onTap: () => _selectTime(
                      context,
                      initialTime: state.inTime,
                      isIn: true,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderCol, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.logIn,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Text.rich(
                                TextSpan(
                                  text: 'Jam Masuk',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeOfDay(state.inTime),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (state.hasIn && state.hasOut) const SizedBox(width: 10),
              if (state.hasOut)
                Expanded(
                  child: InkWell(
                    key: const Key('schedule-time-out-trigger'),
                    onTap: () => _selectTime(
                      context,
                      initialTime: state.outTime,
                      isIn: false,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderCol, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.logOut,
                                size: 14,
                                color: Color(0xFFF97316),
                              ),
                              const SizedBox(width: 6),
                              Text.rich(
                                TextSpan(
                                  text: 'Jam Pulang',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeOfDay(state.outTime),
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card 2: Lokasi GPS Masuk & Pulang
  Widget _buildLocationSection({
    required BuildContext context,
    required ScheduleAttendanceState state,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'LOKASI GPS (MASUK & PULANG)',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTeal,
                      fontSize: 11.5,
                      letterSpacing: 0.5,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF003732).withValues(alpha: 0.5)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.map,
                      size: 11,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Google Maps',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Checkbox Opsi Lokasi In & Out Sama (Hanya tampil pada type inout)
          if (state.attendanceType == 'inout') ...[
            const SizedBox(height: 10),
            InkWell(
              key: const Key('schedule-same-location-checkbox'),
              onTap: () {
                context.read<ScheduleAttendanceBloc>().add(
                      ScheduleAttendanceSameLocationToggled(
                        !state.isSameLocation,
                      ),
                    );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: state.isSameLocation,
                        activeColor: AppColors.brandTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          context.read<ScheduleAttendanceBloc>().add(
                                ScheduleAttendanceSameLocationToggled(
                                  val ?? false,
                                ),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lokasi waktu In dan Out sama',
                        style: AppTypography.bodySmall.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Kartu Lokasi Masuk (Jika hasIn)
          if (state.hasIn)
            _buildSingleLocationCard(
              title: 'Lokasi Absen Masuk',
              isRequired: true,
              address: state.addressIn,
              latitude: state.inLatitude,
              longitude: state.longitudeIn,
              iconColor: const Color(0xFF10B981),
              onPickLocation: () => _pickLocation(isIn: true),
              pickButtonKey: const Key('schedule-pick-in-location-button'),
              isDark: isDark,
              borderCol: borderCol,
              textCol: textCol,
              subtitleCol: subtitleCol,
            ),

          if (state.hasIn && state.hasOut) const SizedBox(height: 12),

          // Kartu Lokasi Pulang (Jika hasOut)
          if (state.hasOut)
            _buildSingleLocationCard(
              title: 'Lokasi Absen Pulang',
              isRequired: true,
              address: state.addressOut,
              latitude: state.latitudeOut,
              longitude: state.longitudeOut,
              iconColor: const Color(0xFFF97316),
              isSynchronized:
                  state.attendanceType == 'inout' && state.isSameLocation,
              onPickLocation: () => _pickLocation(isIn: false),
              pickButtonKey: const Key('schedule-pick-out-location-button'),
              isDark: isDark,
              borderCol: borderCol,
              textCol: textCol,
              subtitleCol: subtitleCol,
            ),
        ],
      ),
    );
  }

  Widget _buildSingleLocationCard({
    required String title,
    required bool isRequired,
    required String? address,
    required double? latitude,
    required double? longitude,
    required Color iconColor,
    bool isSynchronized = false,
    required VoidCallback onPickLocation,
    required Key pickButtonKey,
    required bool isDark,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    final hasLocation =
        latitude != null && longitude != null && address != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 16, color: iconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: title,
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textCol,
                            fontSize: 12.5,
                          ),
                          children: [
                            if (isRequired)
                              const TextSpan(
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSynchronized)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerHigh
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Sama dengan In',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: subtitleCol,
                    ),
                  ),
                )
              else
                InkWell(
                  key: pickButtonKey,
                  onTap: onPickLocation,
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.map,
                        size: 13,
                        color: AppColors.brandTeal,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Pilih / Ubah Lokasi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandTeal,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasLocation
                ? address
                : 'Belum memilih lokasi. Ketuk tombol untuk membuka peta.',
            style: AppTypography.bodySmall.copyWith(
              color: hasLocation ? textCol : subtitleCol,
              fontWeight: hasLocation ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasLocation) ...[
            const SizedBox(height: 4),
            Text(
              '${latitude.toStringAsFixed(5)}°, ${longitude.toStringAsFixed(5)}°',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.brandTeal,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: borderCol, width: 1),
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                ),
                child: Stack(
                  children: [
                    if (!_isTestEnvironment &&
                        (Platform.isAndroid || Platform.isIOS))
                      GoogleMap(
                        key: ValueKey(
                          'schedule_loc_preview_${title}_${latitude.toStringAsFixed(5)}_${longitude.toStringAsFixed(5)}',
                        ),
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latitude, longitude),
                          zoom: 15.5,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('loc_preview_${title.hashCode}'),
                            position: LatLng(latitude, longitude),
                          ),
                        },
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        liteModeEnabled: Platform.isAndroid,
                      )
                    else
                      _buildMiniMapFallback(
                        isDark: isDark,
                        textCol: textCol,
                        latitude: latitude,
                        longitude: longitude,
                      ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isSynchronized ? null : onPickLocation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (!isSynchronized) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onPickLocation,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.brandTeal.withValues(alpha: 0.1)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.brandTeal.withValues(alpha: 0.25)
                        : const Color(0xFFCCFBF1),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 15,
                      color: AppColors.brandTeal,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pilih Lokasi di Peta Google Maps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Card 3: Bukti Verifikasi (Foto Selfie vs Sensor Biometrik)
  Widget _buildVerificationSection({
    required BuildContext context,
    required ScheduleAttendanceState state,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'BUKTI VERIFIKASI KEHADIRAN',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTeal,
                      fontSize: 11.5,
                      letterSpacing: 0.5,
                    ),
                    children: [
                      if (state.isPhotoMethod)
                        const TextSpan(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  state.isPhotoMethod
                      ? 'Metode: Photo Verification'
                      : 'Metode: Biometric Verification',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (state.isPhotoMethod) ...[
            // Foto Masuk (jika hasIn)
            if (state.hasIn)
              _buildPhotoCard(
                context: context,
                label: 'Foto Selfie Masuk',
                photo: state.inPhoto,
                compressResult: _inCompressResult,
                isCompressing: _isInCompressing,
                triggerKey: const Key('schedule-photo-in-trigger'),
                onCapture: () => _captureCameraSelfie(isIn: true),
                onClear: () => _clearPhoto(isIn: true),
                isDark: isDark,
                borderCol: borderCol,
                textCol: textCol,
                subtitleCol: subtitleCol,
              ),

            if (state.hasIn && state.hasOut) const SizedBox(height: 14),

            // Foto Pulang (jika hasOut)
            if (state.hasOut)
              _buildPhotoCard(
                context: context,
                label: 'Foto Selfie Pulang',
                photo: state.outPhoto,
                compressResult: _outCompressResult,
                isCompressing: _isOutCompressing,
                triggerKey: const Key('schedule-photo-out-trigger'),
                onCapture: () => _captureCameraSelfie(isIn: false),
                onClear: () => _clearPhoto(isIn: false),
                isDark: isDark,
                borderCol: borderCol,
                textCol: textCol,
                subtitleCol: subtitleCol,
              ),
          ] else ...[
            // Tampilan Biometrik
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
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textCol,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Identitas Anda akan diverifikasi menggunakan sensor biometrik perangkat saat menekan tombol kirim. Tidak memerlukan upload foto selfie.',
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
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required BuildContext context,
    required String label,
    required XFile? photo,
    required ImageCompressResult? compressResult,
    required bool isCompressing,
    required Key triggerKey,
    required VoidCallback onCapture,
    required VoidCallback onClear,
    required bool isDark,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: textCol,
              fontSize: 12.5,
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
        ),
        const SizedBox(height: 8),

        if (photo == null)
          InkWell(
            key: triggerKey,
            onTap: isCompressing ? null : onCapture,
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
                height: 115,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.brandTeal.withValues(alpha: 0.08)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isCompressing
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brandTeal
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              size: 22,
                              color: AppColors.brandTeal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ambil Foto Selfie via Kamera Depan',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.brandTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Strict Camera-Only (Maksimal 100 KB)',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: 1),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(photo.path),
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 54,
                      height: 54,
                      color: AppColors.brandTeal.withValues(alpha: 0.1),
                      child: const Icon(
                        LucideIcons.camera,
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.name.isNotEmpty
                            ? photo.name
                            : photo.path.split(RegExp(r'[/\\]')).last,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textCol,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (compressResult != null)
                        Text(
                          '${compressResult.originalSizeFormatted} -> ${compressResult.compressedSizeFormatted}',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10.5,
                            color: AppColors.brandTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              AppImagePreviewDialog.show(
                                context,
                                xFile: photo,
                                title: label,
                              );
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.eye,
                                  size: 13,
                                  color: AppColors.brandTeal,
                                ),
                                SizedBox(width: 3),
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
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: onCapture,
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.camera,
                                  size: 13,
                                  color: AppColors.brandTeal,
                                ),
                                SizedBox(width: 3),
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
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: onClear,
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  size: 13,
                                  color: AppColors.errorRed,
                                ),
                                SizedBox(width: 3),
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

  /// Card 4: Form Alasan & Penjelasan Terencana
  Widget _buildReasonSection({
    required BuildContext context,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'ALASAN & PENJELASAN TUGAS LUAR',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.brandTeal,
                fontSize: 11.5,
                letterSpacing: 0.5,
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
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('schedule-reason-input'),
            label: 'Alasan Presensi Terjadwal *',
            controller: _reasonController,
            hintText:
                'Tuliskan alasan penugasan / jadwal dinas luar kantor ini...',
            maxLines: 3,
            isRequired: true,
            prefixIcon: LucideIcons.fileText,
            onChanged: (val) {
              context
                  .read<ScheduleAttendanceBloc>()
                  .add(ScheduleAttendanceReasonChanged(val));
            },
          ),
        ],
      ),
    );
  }

  /// Sticky Bottom Action Bar dengan [AppButton]
  Widget _buildBottomActionBar({
    required BuildContext context,
    required ScheduleAttendanceState state,
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
        key: const Key('schedule-attendance-submit-button'),
        text: 'Ajukan Presensi Terencana',
        variant: AppButtonVariant.primary,
        leadingIcon: LucideIcons.send,
        height: 52,
        isLoading: state.isSubmitting,
        onPressed: state.isSubmitting
            ? null
            : () => _handleSubmission(state),
      ),
    );
  }
}
