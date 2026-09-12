
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_document_upload_card.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_create_models.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/create_overtime/create_overtime_bloc.dart';

/// Halaman Tambah Lembur (Request Overtime).
///
/// Tampilan UI dan komponen kartu, input, dan tombol diselaraskan konsisten
/// dengan standar formulir [CreateLeaveScreen].
class CreateOvertimeScreen extends StatelessWidget {
  final OvertimeRepository? repository;
  final CreateOvertimeBloc? bloc;

  const CreateOvertimeScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<CreateOvertimeBloc>.value(
        value: bloc!,
        child: const _CreateOvertimeView(),
      );
    }
    return BlocProvider<CreateOvertimeBloc>(
      create: (_) => CreateOvertimeBloc(repository: repository)
        ..add(const CreateOvertimeStarted()),
      child: const _CreateOvertimeView(),
    );
  }
}

class _CreateOvertimeView extends StatefulWidget {
  const _CreateOvertimeView();

  @override
  State<_CreateOvertimeView> createState() => _CreateOvertimeViewState();
}

class _CreateOvertimeViewState extends State<_CreateOvertimeView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  XFile? _pickedPhoto;
  ImageCompressResult? _compressResult;
  bool _isCompressingPhoto = false;

  static const List<String> _months = [
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
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.day;
    final m = _months[dt.month - 1];
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d $m $y, $h:$min WIB';
  }

  Future<void> _pickStartDateTime(DateTime current) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (mounted) {
      context.read<CreateOvertimeBloc>().add(
            CreateOvertimeStartChanged(newDateTime),
          );
    }
  }

  Future<void> _pickEndDateTime(DateTime current, DateTime minStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current.isBefore(minStart) ? minStart : current,
      firstDate: DateTime(minStart.year, minStart.month, minStart.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (newDateTime.isBefore(minStart)) {
      _showWarningSnackBar(
        'Waktu selesai tidak boleh lebih awal dari waktu mulai.',
      );
      return;
    }

    if (mounted) {
      context.read<CreateOvertimeBloc>().add(
            CreateOvertimeEndChanged(newDateTime),
          );
    }
  }



  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleSubmit(CreateOvertimeState state) {
    if (_notesController.text.trim().isEmpty) {
      _showWarningSnackBar('Alasan pengajuan lembur wajib diisi.');
      return;
    }
    if (_pickedPhoto == null) {
      _showWarningSnackBar('Foto bukti lembur wajib dilampirkan.');
      return;
    }
    if (state.startOvertime == null || state.endOvertime == null) {
      _showWarningSnackBar('Waktu mulai dan selesai lembur harus dipilih.');
      return;
    }
    if (state.isCheckOutRequiredBlocked) {
      _showWarningSnackBar(
        'Anda belum melakukan check-out kehadiran. Harap check-out terlebih dahulu.',
      );
      return;
    }

    context.read<CreateOvertimeBloc>().add(
          CreateOvertimeSubmitted(
            startOvertime: state.startOvertime!,
            endOvertime: state.endOvertime!,
            notes: _notesController.text.trim(),
            workScheduleId: state.scheduleData?.workScheduleId,
            file: _pickedPhoto!,
          ),
        );
  }

  Widget _buildTag({
    required String label,
    required Color bgColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.info, color: Color(0xFF0D9488), size: 20),
            const SizedBox(width: 8),
            Text(
              'Panduan Pengajuan Lembur',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              icon: LucideIcons.clock,
              title: 'Lembur Pra-Shift',
              desc:
                  'Dilakukan sebelum jam shift kerja. Waktu selesai otomatis diset ke jam masuk shift.',
            ),
            const SizedBox(height: 10),
            _buildHelpItem(
              icon: LucideIcons.calendarCheck,
              title: 'Lembur Pasca-Shift',
              desc:
                  'Dilakukan setelah shift. Anda harus sudah check-out presensi. Waktu selesai terkunci otomatis.',
            ),
            const SizedBox(height: 10),
            _buildHelpItem(
              icon: LucideIcons.calendarOff,
              title: 'Lembur Hari Libur',
              desc:
                  'Bebas menentukan jam mulai & selesai lembur jika pada hari libur kerja.',
            ),
            const SizedBox(height: 10),
            _buildHelpItem(
              icon: LucideIcons.camera,
              title: 'Bukti Foto Wajib',
              desc:
                  'Lampirkan foto bukti pekerjaan sebagai syarat validasi atasan/approver.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Mengerti',
              style: TextStyle(
                color: Color(0xFF0D9488),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D9488)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.backgroundSubtle;
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
    final inputBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;

    return BlocConsumer<CreateOvertimeBloc, CreateOvertimeState>(
      listener: (context, state) {
        if (state.status == CreateOvertimeStatus.success) {
          AppDialogUtil.showSuccess(
            context,
            title: 'Pengajuan Berhasil',
            message: state.successMessage.isNotEmpty
                ? state.successMessage
                : 'Pengajuan lembur berhasil dibuat.',
            onOk: () {
              Navigator.of(context).pop(true);
            },
          );
        } else if (state.status == CreateOvertimeStatus.failure) {
          AppDialogUtil.showError(
            context,
            title: 'Gagal Mengajukan Lembur',
            message: state.errorMessage.isNotEmpty
                ? state.errorMessage
                : 'Terjadi kesalahan sistem.',
          );
        }
      },
      builder: (context, state) {
        final start = state.startOvertime;
        final end = state.endOvertime;
        final isSubmitting = state.status == CreateOvertimeStatus.submitting;
        final canSubmit = state.canSubmit && _pickedPhoto != null;

        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: bgCol.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 1.5,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajukan Lembur',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Formulir permohonan lembur karyawan',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  LucideIcons.helpCircle,
                  color: subtitleCol,
                  size: 20,
                ),
                onPressed: () => _showHelpDialog(context, isDark),
                tooltip: 'Panduan',
              ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // ── Banner Blokir Check-Out (Jika Post-Shift & Belum Out) ──
                  if (state.isCheckOutRequiredBlocked)
                    _buildBlockedCheckOutBanner(context, isDark),

                  // ── Banner Peringatan Pre-Shift (Lembur Sebelum Shift) ─
                  if (state.category == OvertimeTypeCategory.preShift)
                    _buildPreShiftNoticeBanner(isDark),

                  // ── SECTION 1: Periode & Jadwal Lembur ──────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.calendarClock,
                                  color: Color(0xFF0D9488),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PERIODE & JADWAL LEMBUR',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: const Color(0xFF0D9488),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Text(
                                  ' *',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (state.category == OvertimeTypeCategory.dayOff)
                              _buildTag(
                                label: 'Hari Libur (Day Off)',
                                bgColor: const Color(0xFFEFF6FF),
                                textColor: const Color(0xFF2563EB),
                                icon: LucideIcons.calendarOff,
                              )
                            else if (state.category ==
                                OvertimeTypeCategory.preShift)
                              _buildTag(
                                label: 'Pra-Shift',
                                bgColor: const Color(0xFFFFFBEB),
                                textColor: const Color(0xFFD97706),
                                icon: LucideIcons.clockAlert,
                              )
                            else if (state.category ==
                                OvertimeTypeCategory.postShift)
                              _buildTag(
                                label: 'Pasca-Shift',
                                bgColor: const Color(0xFFF0FDF4),
                                textColor: const Color(0xFF16A34A),
                                icon: LucideIcons.clockCheck,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Shift & Info Presensi jika ada
                        if (state.scheduleData != null &&
                            state.scheduleData!.hasSchedule) ...[
                          _buildShiftAttendanceInfo(
                            state.scheduleData!,
                            subtitleCol,
                            borderCol,
                            inputBg,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Tanggal & Jam Mulai Picker
                        Text(
                          'Tanggal & Jam Mulai',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          key: const ValueKey('start_time_picker'),
                          onTap: () {
                            if (start != null) {
                              _pickStartDateTime(start);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.calendar,
                                  color: Color(0xFF0D9488),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(start),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Ubah',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: const Color(0xFF0D9488),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tanggal & Jam Selesai Picker
                        Text(
                          'Tanggal & Jam Selesai',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          key: const ValueKey('end_time_picker'),
                          onTap: () {
                            if (state.isEndTimeLocked) {
                              _showWarningSnackBar(
                                'Waktu selesai terkunci otomatis sesuai jam check-out kehadiran.',
                              );
                            } else if (end != null && start != null) {
                              _pickEndDateTime(end, start);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: state.isEndTimeLocked
                                  ? (isDark
                                      ? AppColors.darkSurfaceContainer
                                      : const Color(0xFFF1F5F9))
                                  : inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: state.isEndTimeLocked
                                    ? borderCol.withValues(alpha: 0.6)
                                    : borderCol,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  state.isEndTimeLocked
                                      ? LucideIcons.lock
                                      : LucideIcons.calendarCheck,
                                  color: state.isEndTimeLocked
                                      ? subtitleCol
                                      : const Color(0xFF0D9488),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(end),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: state.isEndTimeLocked
                                          ? subtitleCol
                                          : textCol,
                                    ),
                                  ),
                                ),
                                if (state.isEndTimeLocked)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        size: 14,
                                        color: subtitleCol,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Terkunci',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: subtitleCol,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    'Ubah',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: const Color(0xFF0D9488),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (state.isEndTimeLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 2),
                            child: Text(
                              '*Terkunci otomatis dari jam check-out kehadiran',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF0D9488),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),

                        // Banner Estimasi Durasi Lembur
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF0D9488)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.timer,
                                color: Color(0xFF0D9488),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Total Durasi Lembur: ${state.durationLabel}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF0F766E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── SECTION 2: Alasan / Catatan Lembur ───────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.fileEdit,
                              color: Color(0xFF0D9488),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ALASAN / CATATAN',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF0D9488),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('overtime_notes_field'),
                          controller: _notesController,
                          maxLines: 4,
                          maxLength: 250,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                'Tuliskan alasan atau keterangan lengkap pengajuan lembur Anda...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0D9488),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── SECTION 3: Dokumen / Bukti Pendukung ─────────────────
                  AppDocumentUploadCard(
                    title: 'DOKUMEN PENDUKUNG',
                    titleIcon: LucideIcons.paperclip,
                    isRequired: true,
                    requiredTagText: 'Wajib Diunggah',
                    uploadPlaceholderTitle: 'Lampirkan Foto Bukti Lembur',
                    uploadPlaceholderSubtitle:
                        'Kamera atau Galeri (Otomatis dikompresi)',
                    sheetTitle: 'Pilih Sumber Dokumen / Foto',
                    sampleTitle: 'Gunakan Sampel Foto Lembur',
                    sampleSubtitle: 'Simulasi lampiran bukti tugas/kerja',
                    sampleFileName: 'sample_overtime_proof.jpg',
                    file: _pickedPhoto,
                    compressResult: _compressResult,
                    isCompressing: _isCompressingPhoto,
                    uploadBoxKey:
                        const ValueKey('upload_overtime_photo_box'),
                    deleteButtonKey:
                        const ValueKey('delete_overtime_photo_btn'),
                    onFileWithCompressionChanged: (file, result) {
                      setState(() {
                        _pickedPhoto = file;
                        _compressResult = result;
                        _isCompressingPhoto = false;
                      });
                    },
                    onError: _showWarningSnackBar,
                  ),
                ],
              ),
            ),
          ),

          // ── STICKY BOTTOM BAR: Submit Button (Konsisten dengan CreateLeaveScreen) ─
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderCol)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: AppButton(
              key: const ValueKey('submit_overtime_btn'),
              text: 'Kirim Pengajuan Lembur',
              leadingIcon: LucideIcons.send,
              isLoading: isSubmitting,
              onPressed:
                  (isSubmitting || !canSubmit) ? null : () => _handleSubmit(state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedCheckOutBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF450A0A).withValues(alpha: 0.6)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertTriangle,
                  size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Belum Melakukan Check-Out',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Anda memiliki jadwal kerja hari ini tetapi belum melakukan check-out kehadiran. Harap check-out terlebih dahulu sebelum mengajukan lembur setelah jam kerja.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFF991B1B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              context.push(Routes.ATTENDANCE);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.arrowRight,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Buka Menu Presensi',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreShiftNoticeBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF451A03).withValues(alpha: 0.6)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.clockAlert,
              size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lembur Sebelum Shift (Pre-Shift)',
                  style: AppTypography.labelMedium.copyWith(
                    color: const Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lembur diajukan sebelum jam masuk kerja. Pastikan melampirkan foto bukti tugas nyata karena persetujuan mutlak menjadi tanggung jawab atasan/approver.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF92400E),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftAttendanceInfo(
    OvertimeScheduleData scheduleData,
    Color subtitleCol,
    Color borderCol,
    Color inputBg,
  ) {
    final shift = scheduleData.schedule?.shift;
    final att = scheduleData.attendance;
    final shiftTime = (shift?.startTime != null && shift?.endTime != null)
        ? '${shift!.startTime!.substring(0, 5)} - ${shift.endTime!.substring(0, 5)} WIB'
        : '-';
    final checkInTime = att?.checkIn != null
        ? (att!.checkIn!.length >= 5
            ? att.checkIn!.substring(0, 5)
            : att.checkIn!)
        : '-';
    final checkOutTime = att?.checkOut != null
        ? (att!.checkOut!.length >= 5
            ? att.checkOut!.substring(0, 5)
            : att.checkOut!)
        : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.calendarClock,
              size: 16, color: Color(0xFF0D9488)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift: $shiftTime',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Presensi: In $checkInTime • Out $checkOutTime',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 10.5,
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
