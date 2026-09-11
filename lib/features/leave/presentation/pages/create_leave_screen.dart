import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/create_leave/create_leave_bloc.dart';

/// Halaman Form Pengajuan Cuti / Izin baru (Create Leave Request).
class CreateLeaveScreen extends StatelessWidget {
  final LeaveRepository? repository;
  final CreateLeaveBloc? bloc;

  const CreateLeaveScreen({super.key, this.repository, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<CreateLeaveBloc>.value(
        value: bloc!,
        child: const _CreateLeaveView(),
      );
    }
    return BlocProvider(
      create: (_) => CreateLeaveBloc(repository: repository)
        ..add(const CreateLeaveStarted()),
      child: const _CreateLeaveView(),
    );
  }
}

class _CreateLeaveView extends StatefulWidget {
  const _CreateLeaveView();

  @override
  State<_CreateLeaveView> createState() => _CreateLeaveViewState();
}

class _CreateLeaveViewState extends State<_CreateLeaveView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  int _totalDays = 1;
  LeaveTypeOptionModel? _selectedType;

  XFile? _pickedPhoto;
  ImageCompressResult? _compressResult;
  bool _isCompressingPhoto = false;

  /// Batas maksimal hari pengajuan cuti secara default (30 hari).
  static const int _defaultMaxDays = 30;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Menghitung batas maksimum hari yang berlaku untuk jenis cuti yang dipilih.
  int get _effectiveMaxDays {
    if (_selectedType?.fixedDays != null) {
      return _selectedType!.fixedDays!;
    }
    if (_selectedType?.maxDays != null) {
      final max = _selectedType!.maxDays!;
      return max < _defaultMaxDays ? max : _defaultMaxDays;
    }
    return _defaultMaxDays;
  }

  /// Menghitung estimasi tanggal berakhir cuti (inklusif).
  DateTime get _calculatedEndDate {
    return _startDate.add(Duration(days: _totalDays > 0 ? _totalDays - 1 : 0));
  }

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

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  String _toApiDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
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

    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  void _onSelectLeaveType(LeaveTypeOptionModel type) {
    setState(() {
      _selectedType = type;
      if (type.fixedDays != null) {
        _totalDays = type.fixedDays!;
      } else if (type.maxDays != null && _totalDays > type.maxDays!) {
        _totalDays = type.maxDays!;
      }
    });
    context.read<CreateLeaveBloc>().add(CreateLeaveTypeChanged(type));
  }

  void _showLeaveTypeBottomSheet(List<LeaveTypeOptionModel> leaveTypes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendarClock,
                    color: Color(0xFF0D9488),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pilih Jenis Cuti / Izin',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (leaveTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Tidak ada jenis cuti yang tersedia.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: leaveTypes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final type = leaveTypes[index];
                      final isSelected = _selectedType?.id == type.id;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _onSelectLeaveType(type);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          type.name,
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF0D9488)
                                                : null,
                                          ),
                                        ),
                                        if (type.code.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D9488)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              type.code,
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: const Color(0xFF0D9488),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (type.requiresFile)
                                          _buildTag(
                                            label: 'Wajib Foto/Dokumen',
                                            bgColor: const Color(0xFFFEF2F2),
                                            textColor: const Color(0xFFDC2626),
                                            icon: LucideIcons.fileText,
                                          ),
                                        if (type.fixedDays != null)
                                          _buildTag(
                                            label: 'Durasi: ${type.fixedDays} Hari',
                                            bgColor: const Color(0xFFEFF6FF),
                                            textColor: const Color(0xFF2563EB),
                                            icon: LucideIcons.lock,
                                          )
                                        else if (type.maxDays != null)
                                          _buildTag(
                                            label: 'Maks. ${type.maxDays} Hari',
                                            bgColor: const Color(0xFFF0FDF4),
                                            textColor: const Color(0xFF16A34A),
                                            icon: LucideIcons.calendarDays,
                                          ),
                                        if (type.isDeducted)
                                          _buildTag(
                                            label: 'Potong Kuota',
                                            bgColor: const Color(0xFFFFFBEB),
                                            textColor: const Color(0xFFD97706),
                                          ),
                                      ],
                                    ),
                                    if (type.description != null &&
                                        type.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        type.description!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  LucideIcons.check,
                                  color: Color(0xFF0D9488),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
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

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() {
          _pickedPhoto = photo;
        });

        // Kompres di background thread tanpa memblokir UI
        ImageCompressUtil.compressXFile(
          photo,
          quality: 75,
          minWidth: 1600,
          minHeight: 1600,
          onLoadingChanged: (isCompressing) {
            if (mounted) {
              setState(() => _isCompressingPhoto = isCompressing);
            }
          },
        ).then((result) {
          if (mounted) {
            setState(() {
              _pickedPhoto = result.file;
              _compressResult = result;
            });
            debugPrint(
              '📸 [CreateLeave] Foto bukti cuti berhasil dikompresi:\n'
              '   • Sebelum (RAW) : ${result.originalSizeFormatted} (${result.originalSizeBytes} bytes)\n'
              '   • Sesudah (OPT) : ${result.compressedSizeFormatted} (${result.compressedSizeBytes} bytes)\n'
              '   • Efisiensi     : Hemat ${result.savedPercentage.toStringAsFixed(1)}% '
              '(${ImageCompressResult.formatBytes(result.originalSizeBytes - result.compressedSizeBytes > 0 ? result.originalSizeBytes - result.compressedSizeBytes : 0)})\n'
              '   • Waktu         : ${result.compressionDuration.inMilliseconds} ms',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showWarningSnackBar('Gagal mengambil foto: $e');
      }
    }
  }

  void _useSamplePhoto() {
    try {
      final tempFile = File(
        '${Directory.systemTemp.path}/sample_leave_proof.jpg',
      );
      if (!tempFile.existsSync()) {
        final dummyBytes = [
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
          0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
          0x00, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
          0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09,
          0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x7F, 0x00,
          0xFF, 0xD9,
        ];
        tempFile.writeAsBytesSync(dummyBytes);
      }
      setState(() {
        _pickedPhoto = XFile(tempFile.path);
      });

      ImageCompressUtil.compressXFile(
        XFile(tempFile.path),
        quality: 75,
        onLoadingChanged: (isCompressing) {
          if (mounted) {
            setState(() => _isCompressingPhoto = isCompressing);
          }
        },
      ).then((result) {
        if (mounted) {
          setState(() {
            _pickedPhoto = result.file;
            _compressResult = result;
          });
        }
      });
    } catch (_) {}
  }

  void _showPhotoOptionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Sumber Dokumen / Foto',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDFA),
                  child: Icon(LucideIcons.camera, color: Color(0xFF0D9488)),
                ),
                title: const Text('Ambil Foto Kamera'),
                subtitle: const Text('Gunakan kamera perangkat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDFA),
                  child: Icon(LucideIcons.image, color: Color(0xFF0D9488)),
                ),
                title: const Text('Pilih dari Galeri'),
                subtitle: const Text('Pilih foto dari penyimpanan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDFA),
                  child: Icon(LucideIcons.fileCheck2, color: Color(0xFF0D9488)),
                ),
                title: const Text('Gunakan Sampel Surat Dokter'),
                subtitle: const Text('Simulasi lampiran dokumen pendukung'),
                onTap: () {
                  Navigator.pop(ctx);
                  _useSamplePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  void _handleSubmit() {
    if (_selectedType == null) {
      _showWarningSnackBar('Silakan pilih jenis cuti/izin terlebih dahulu.');
      return;
    }
    if (_notesController.text.trim().isEmpty) {
      _showWarningSnackBar('Alasan pengajuan cuti/izin wajib diisi.');
      return;
    }
    if (_selectedType!.requiresFile && _pickedPhoto == null) {
      _showWarningSnackBar(
        'Dokumen pendukung (surat dokter/bukti) wajib dilampirkan untuk jenis ${_selectedType!.name}.',
      );
      return;
    }

    context.read<CreateLeaveBloc>().add(
          CreateLeaveSubmitted(
            leaveTypeId: _selectedType!.id,
            startDate: _toApiDate(_startDate),
            totalDays: _totalDays,
            notes: _notesController.text.trim(),
            file: _pickedPhoto,
          ),
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

    return BlocConsumer<CreateLeaveBloc, CreateLeaveState>(
      listener: (context, state) {
        if (state.isSuccess) {
          AppDialogUtil.showSuccess(
            context,
            title: 'Pengajuan Berhasil',
            message: state.successMessage,
            onOk: () {
              Navigator.of(context).pop(true);
            },
          );
        } else if (state.isFailure) {
          AppDialogUtil.showError(
            context,
            title: 'Gagal Mengajukan Cuti',
            message: state.errorMessage,
          );
        }
      },
      builder: (context, state) {
        final leaveTypes = state.leaveTypes;

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
                  'Ajukan Cuti / Izin',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Formulir permohonan cuti & izin karyawan',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // ── SECTION 1: Jenis Cuti / Izin ──────────────────────────
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
                              LucideIcons.calendarCheck2,
                              color: Color(0xFF0D9488),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'JENIS CUTI / IZIN',
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
                        InkWell(
                          key: const ValueKey('leave_type_selector'),
                          onTap: state.isLoadingTypes
                              ? null
                              : () => _showLeaveTypeBottomSheet(leaveTypes),
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
                                Expanded(
                                  child: _selectedType == null
                                      ? Text(
                                          state.isLoadingTypes
                                              ? 'Memuat jenis cuti...'
                                              : 'Pilih Jenis Cuti / Izin',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedType!.name,
                                              style: AppTypography.bodyLarge
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (_selectedType!.requiresFile)
                                                  _buildTag(
                                                    label: 'Wajib Dokumen/Foto',
                                                    bgColor:
                                                        const Color(0xFFFEF2F2),
                                                    textColor:
                                                        const Color(0xFFDC2626),
                                                    icon: LucideIcons.fileText,
                                                  ),
                                                if (_selectedType!.fixedDays !=
                                                    null)
                                                  _buildTag(
                                                    label:
                                                        'Durasi ${_selectedType!.fixedDays} Hari',
                                                    bgColor:
                                                        const Color(0xFFEFF6FF),
                                                    textColor:
                                                        const Color(0xFF2563EB),
                                                    icon: LucideIcons.lock,
                                                  )
                                                else if (_selectedType!
                                                        .maxDays !=
                                                    null)
                                                  _buildTag(
                                                    label:
                                                        'Maks ${_selectedType!.maxDays} Hari',
                                                    bgColor:
                                                        const Color(0xFFF0FDF4),
                                                    textColor:
                                                        const Color(0xFF16A34A),
                                                  ),
                                                if (_selectedType!.isDeducted)
                                                  _buildTag(
                                                    label: 'Potong Kuota',
                                                    bgColor:
                                                        const Color(0xFFFFFBEB),
                                                    textColor:
                                                        const Color(0xFFD97706),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  LucideIcons.chevronDown,
                                  color: subtitleCol,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── SECTION 2: Periode & Durasi Cuti ───────────────────────
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
                              LucideIcons.calendarDays,
                              color: Color(0xFF0D9488),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PERIODE & DURASI CUTI',
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
                        const SizedBox(height: 14),

                        // Tanggal Mulai Picker
                        Text(
                          'Tanggal Mulai',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          key: const ValueKey('start_date_picker'),
                          onTap: _selectStartDate,
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
                                    _formatDate(_startDate),
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
                        const SizedBox(height: 16),

                        // Durasi (Total Hari) - Maksimal 30 hari
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jumlah Hari',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textCol,
                                  ),
                                ),
                                Text(
                                  _selectedType?.fixedDays != null
                                      ? 'Terkunci ${_selectedType!.fixedDays} hari'
                                      : 'Pilihan hingga $_effectiveMaxDays hari',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            // Counter Controls
                            Row(
                              children: [
                                IconButton(
                                  key: const ValueKey('decrement_days_btn'),
                                  onPressed: (_selectedType?.fixedDays != null ||
                                          _totalDays <= 1)
                                      ? null
                                      : () {
                                          setState(() => _totalDays--);
                                        },
                                  icon: const Icon(LucideIcons.minusCircle),
                                  color: const Color(0xFF0D9488),
                                  disabledColor: Colors.grey.withValues(alpha: 0.3),
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderCol),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$_totalDays Hari',
                                      key: const ValueKey('days_counter_text'),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D9488),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: const ValueKey('increment_days_btn'),
                                  onPressed: (_selectedType?.fixedDays != null ||
                                          _totalDays >= _effectiveMaxDays)
                                      ? null
                                      : () {
                                          setState(() => _totalDays++);
                                        },
                                  icon: const Icon(LucideIcons.plusCircle),
                                  color: const Color(0xFF0D9488),
                                  disabledColor: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Quick Day Selection Chips (1 s/d 30 hari)
                        if (_selectedType?.fixedDays == null) ...[
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [1, 2, 3, 5, 7, 14, 30]
                                  .where((d) => d <= _effectiveMaxDays)
                                  .map((days) {
                                final isSelected = _totalDays == days;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text('$days Hari'),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _totalDays = days);
                                      }
                                    },
                                    selectedColor: const Color(0xFF0D9488)
                                        .withValues(alpha: 0.15),
                                    backgroundColor: inputBg,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF0D9488)
                                          : textCol,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFF0D9488)
                                            : borderCol,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Banner Estimasi Rentang Cuti
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.calendarRange,
                                color: Color(0xFF0D9488),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Periode: ${_formatDate(_startDate)} s/d ${_formatDate(_calculatedEndDate)} ($_totalDays hari)',
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

                  // ── SECTION 3: Alasan Pengajuan ───────────────────────────
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
                          key: const ValueKey('leave_notes_field'),
                          controller: _notesController,
                          maxLines: 4,
                          maxLength: 500,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                'Tuliskan alasan atau keterangan lengkap pengajuan cuti/izin Anda...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
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

                  // ── SECTION 4: Dokumen / Bukti Pendukung ──────────────────
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
                                  LucideIcons.paperclip,
                                  color: Color(0xFF0D9488),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'DOKUMEN PENDUKUNG',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: const Color(0xFF0D9488),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (_selectedType?.requiresFile == true)
                                  const Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            if (_selectedType?.requiresFile == true)
                              _buildTag(
                                label: 'Wajib Diunggah',
                                bgColor: const Color(0xFFFEF2F2),
                                textColor: const Color(0xFFDC2626),
                              )
                            else
                              _buildTag(
                                label: 'Opsional',
                                bgColor: const Color(0xFFF1F5F9),
                                textColor: const Color(0xFF64748B),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Container Upload / Foto Preview
                        if (_pickedPhoto == null) ...[
                          InkWell(
                            key: const ValueKey('upload_leave_photo_box'),
                            onTap: _showPhotoOptionsSheet,
                            borderRadius: BorderRadius.circular(12),
                            child: DottedBorder(
                              options: RoundedRectDottedBorderOptions(
                                color: _selectedType?.requiresFile == true
                                    ? const Color(0xFFF87171)
                                    : borderCol,
                                strokeWidth: 1.5,
                                dashPattern: const [6, 4],
                                radius: const Radius.circular(12),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(0xFF0D9488)
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        LucideIcons.camera,
                                        color: Color(0xFF0D9488),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Lampirkan Foto Bukti / Surat Dokter',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: textCol,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kamera atau Galeri (Otomatis dikompresi)',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: subtitleCol,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Card Foto Terpilih
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_pickedPhoto!.path),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        LucideIcons.fileText,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _pickedPhoto!.name.isNotEmpty
                                            ? _pickedPhoto!.name
                                            : 'dokumen_bukti.jpg',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (_isCompressingPhoto)
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF0D9488),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Mengompresi...',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: const Color(0xFF0D9488),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (_compressResult != null)
                                        Text(
                                          'Ukuran: ${_compressResult!.compressedSizeFormatted} (Hemat ${_compressResult!.savedPercentage.toStringAsFixed(0)}%)',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: const Color(0xFF16A34A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: const ValueKey('delete_leave_photo_btn'),
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _pickedPhoto = null;
                                      _compressResult = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── STICKY BOTTOM BAR: Submit Button ──────────────────────────────
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
              key: const ValueKey('submit_leave_btn'),
              text: 'Kirim Pengajuan Cuti',
              leadingIcon: LucideIcons.send,
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _handleSubmit,
            ),
          ),
        );
      },
    );
  }
}
