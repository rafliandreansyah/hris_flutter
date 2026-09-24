import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_bloc.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_event.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/create_resignation/create_resignation_state.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_colleague_picker_modal.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_early_notice_card.dart';
import 'package:hris_flutter/features/resignation/presentation/widgets/resignation_policy_banner.dart';

class _CategoryOption {
  final String key;
  final String label;
  final IconData icon;

  const _CategoryOption(this.key, this.label, this.icon);
}

const List<_CategoryOption> _kResignationCategories = [
  _CategoryOption(
    'career_advancement',
    'Pengembangan Karir (Career Advancement)',
    LucideIcons.trendingUp,
  ),
  _CategoryOption(
    'compensation_and_benefits',
    'Kompensasi & Tunjangan (Compensation & Benefits)',
    LucideIcons.banknote,
  ),
  _CategoryOption(
    'health_or_personal',
    'Kesehatan atau Alasan Pribadi (Health / Personal)',
    LucideIcons.heartPulse,
  ),
  _CategoryOption(
    'relocation',
    'Pindah Domisili / Relokasi (Relocation)',
    LucideIcons.mapPin,
  ),
  _CategoryOption(
    'workplace_environment',
    'Lingkungan Kerja (Workplace Environment)',
    LucideIcons.building2,
  ),
  _CategoryOption(
    'further_studies',
    'Melanjutkan Pendidikan (Further Studies)',
    LucideIcons.graduationCap,
  ),
  _CategoryOption(
    'family_reasons',
    'Alasan Keluarga (Family Reasons)',
    LucideIcons.users,
  ),
  _CategoryOption(
    'entrepreneurship',
    'Memulai Usaha Mandiri (Entrepreneurship)',
    LucideIcons.briefcase,
  ),
  _CategoryOption(
    'other',
    'Lainnya (Other)',
    LucideIcons.moreHorizontal,
  ),
];

class CreateResignationScreen extends StatelessWidget {
  final ResignationRepository? repository;
  final CreateResignationBloc? bloc;

  const CreateResignationScreen({
    super.key,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<CreateResignationBloc>.value(
        value: bloc!,
        child: const _CreateResignationView(),
      );
    }

    return BlocProvider<CreateResignationBloc>(
      create: (_) => CreateResignationBloc(repository: repository)
        ..add(const CreateResignationStarted()),
      child: const _CreateResignationView(),
    );
  }
}

class _CreateResignationView extends StatefulWidget {
  const _CreateResignationView();

  @override
  State<_CreateResignationView> createState() => _CreateResignationViewState();
}

class _CreateResignationViewState extends State<_CreateResignationView> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _handoverNotesController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _notesController.dispose();
    _handoverNotesController.dispose();
    super.dispose();
  }

  void _showPolicyHelpDialog(CreateResignationState state) {
    FocusManager.instance.primaryFocus?.unfocus();
    final policy = state.initialData?.companyPolicy;
    final noticeDays = policy?.effectiveNoticePeriodDays ?? 30;

    AppDialogUtil.showWarning(
      context,
      title: 'Panduan Kebijakan Resign',
      message:
          '1. Notice Period: Standar pengajuan adalah minimal $noticeDays hari kerja sebelum tanggal efektif berhenti.\n\n'
          '2. Early Waiver: Pengajuan di bawah notice period membutuhkan persetujuan manajerial khusus dan alasan yang jelas.\n\n'
          '3. Serah Terima (Handover): Wajib menunjuk rekan kerja pengganti untuk kelancaran transisi tugas & aset.\n\n'
          '4. Surat Resmi: Unggah surat pernyataan resign bertanda tangan basah atau digital.',
      confirmText: 'Saya Mengerti',
    );
  }

  Future<void> _handlePickDate(CreateResignationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final initialDate = state.selectedEffectiveDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      context
          .read<CreateResignationBloc>()
          .add(CreateResignationDateChanged(picked));
    }
  }

  Future<void> _handleSelectCategory(CreateResignationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalContext).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Pilih Kategori Alasan',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _kResignationCategories.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final item = _kResignationCategories[index];
                      final isSelected = item.key == state.selectedCategory;

                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 18,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        title: Text(
                          item.label,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                LucideIcons.checkCircle2,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () => Navigator.of(modalContext).pop(item.key),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      context
          .read<CreateResignationBloc>()
          .add(CreateResignationCategoryChanged(selected));
    }
  }

  Future<void> _handleSelectColleague(CreateResignationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final colleagues = state.initialData?.colleagues ?? [];
    if (colleagues.isEmpty) {
      AppDialogUtil.showWarning(
        context,
        title: 'Rekan Kerja Tidak Tersedia',
        message: 'Tidak ada daftar rekan kerja yang dapat dipilih.',
      );
      return;
    }

    final selected = await showResignationColleaguePickerModal(
      context,
      colleagues: colleagues,
      selectedColleague: state.selectedColleague,
    );

    if (selected != null && mounted) {
      context
          .read<CreateResignationBloc>()
          .add(CreateResignationColleagueSelected(selected));
    }
  }

  Future<void> _handlePickAttachment() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lampirkan Surat Resign',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Ambil Foto Fisik (Kamera)'),
                  subtitle: const Text('Foto surat resign bertanda tangan'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final perm =
                        await PermissionUtil.requestCameraPermission(
                      context: context,
                    );
                    if (!perm.isGranted) return;
                    final photo = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (photo != null && mounted) {
                      context
                          .read<CreateResignationBloc>()
                          .add(CreateResignationFileChanged(photo));
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.image,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  subtitle: const Text('Format JPG, JPEG, PNG, WEBP'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final perm =
                        await PermissionUtil.requestGalleryPermission(
                      context: context,
                    );
                    if (!perm.isGranted) return;
                    final photo = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (photo != null && mounted) {
                      context
                          .read<CreateResignationBloc>()
                          .add(CreateResignationFileChanged(photo));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSubmit(CreateResignationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (state.selectedEffectiveDate == null) {
      AppDialogUtil.showWarning(
        context,
        title: 'Tanggal Belum Dipilih',
        message: 'Silakan tentukan tanggal efektif terakhir bekerja.',
      );
      return;
    }

    if (state.isEarlyNoticeTriggered) {
      if (!state.isEarlyNotice) {
        AppDialogUtil.showWarning(
          context,
          title: 'Early Notice Diperlukan',
          message:
              'Tanggal efektif kurang dari ketentuan notice period. Silakan centang Early Waiver.',
        );
        return;
      }
      if (state.earlyNoticeReason.trim().isEmpty) {
        AppDialogUtil.showWarning(
          context,
          title: 'Alasan Percepatan Wajib',
          message:
              'Silakan isi alasan percepatan pengunduran diri Anda.',
        );
        return;
      }
    }

    if (state.reasonNotes.trim().isEmpty) {
      AppDialogUtil.showWarning(
        context,
        title: 'Alasan Resign Wajib Diisi',
        message: 'Silakan isi penjelasan rinci alasan pengunduran diri.',
      );
      return;
    }

    if (!state.isAgreed) {
      AppDialogUtil.showWarning(
        context,
        title: 'Pernyataan Belum Disetujui',
        message:
            'Anda wajib mencentang pernyataan sukarela sebelum mengirim pengajuan.',
      );
      return;
    }

    final formattedDate = DateFormat('d MMMM yyyy', 'id_ID')
        .format(state.selectedEffectiveDate!);

    final confirmed = await AppDialogUtil.showConfirmation(
      context,
      title: 'Konfirmasi Pengunduran Diri',
      message:
          'Apakah Anda yakin ingin mengajukan pengunduran diri dengan tanggal efektif $formattedDate? Pengajuan ini akan diteruskan ke atasan langsung dan HR.',
      confirmText: 'Ya, Kirim',
      cancelText: 'Batal',
      confirmButtonColor: AppColors.primary,
      icon: LucideIcons.send,
    );

    if (confirmed == true && mounted) {
      context
          .read<CreateResignationBloc>()
          .add(const CreateResignationSubmitted());
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = true}) {
    if (!isRequired) {
      return Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        children: const [
          TextSpan(text: ' '),
          TextSpan(
            text: '*',
            style: TextStyle(
              color: AppColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return BlocConsumer<CreateResignationBloc, CreateResignationState>(
      listener: (context, state) {
        if (state.status == CreateResignationStatus.failure &&
            state.errorMessage != null) {
          AppDialogUtil.showError(
            context,
            message: state.errorMessage!,
          );
        }

        if (state.status == CreateResignationStatus.success) {
          AppDialogUtil.showSuccess(
            context,
            title: 'Pengajuan Berhasil',
            message:
                'Pengajuan pengunduran diri Anda telah berhasil dikirim dan akan segera diproses oleh manajemen.',
            buttonText: 'Tutup',
          ).then((_) {
            if (context.mounted) {
              context.pop(true);
            }
          });
        }
      },
      builder: (context, state) {
        final isLoadingInitial =
            state.status == CreateResignationStatus.loadingInitial;
        final isSubmitting =
            state.status == CreateResignationStatus.submitting;

        final currentCategory = _kResignationCategories.firstWhere(
          (c) => c.key == state.selectedCategory,
          orElse: () => _kResignationCategories.first,
        );

        final formattedSelectedDate = state.selectedEffectiveDate != null
            ? DateFormat('d MMMM yyyy', 'id_ID')
                .format(state.selectedEffectiveDate!)
            : 'Pilih Tanggal';

        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.arrowLeft, size: 18),
                ),
              ),
            ),
            title: Column(
              children: [
                Text(
                  'Formulir Pengunduran Diri',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Pengajuan Mandiri Karyawan',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: const Icon(LucideIcons.helpCircle, size: 18),
                  ),
                  onPressed: () => _showPolicyHelpDialog(state),
                ),
              ),
            ],
          ),
          body: isLoadingInitial
              ? _buildShimmerLoading()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Policy & Leave Balance Banner ──
                      if (state.initialData != null) ...[
                        ResignationPolicyBanner(
                          initialData: state.initialData!,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── 2. Section 1 - Tanggal Efektif Resign ──
                      _buildSectionHeader('1. TANGGAL EFEKTIF RESIGN'),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.backgroundSubtle,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: const [
                                  TextSpan(text: 'Tanggal Terakhir Bekerja'),
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
                            InkWell(
                              onTap: () => _handlePickDate(state),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        formattedSelectedDate,
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Ubah',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (state.isEarlyNoticeTriggered) ...[
                        const SizedBox(height: 12),
                        ResignationEarlyNoticeCard(
                          requiredNoticeDays: state.requiredNoticePeriodDays,
                          actualDaysDiff: state.daysDiff,
                          isEarlyNotice: state.isEarlyNotice,
                          earlyNoticeReason: state.earlyNoticeReason,
                          onEarlyWaiverChanged: (val) {
                            context.read<CreateResignationBloc>().add(
                                  CreateResignationEarlyWaiverToggled(val),
                                );
                          },
                          onReasonChanged: (val) {
                            context.read<CreateResignationBloc>().add(
                                  CreateResignationEarlyReasonChanged(val),
                                );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── 3. Section 2 - Alasan Pengunduran Diri ──
                      _buildSectionHeader('2. ALASAN PENGUNDURAN DIRI'),
                      const SizedBox(height: 10),

                      RichText(
                        text: TextSpan(
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          children: const [
                            TextSpan(text: 'Kategori Alasan'),
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
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _handleSelectCategory(state),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                currentCategory.icon,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  currentCategory.label,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                LucideIcons.chevronDown,
                                size: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkOnSurfaceVariant
                                    : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              children: const [
                                TextSpan(text: 'Penjelasan Rinci Alasan'),
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
                          Text(
                            '${state.reasonNotes.length} / 500',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        hintText:
                            'Tuliskan alasan pengunduran diri secara profesional dan rinci...',
                        controller: _notesController,
                        maxLines: 4,
                        onChanged: (val) {
                          context.read<CreateResignationBloc>().add(
                                CreateResignationReasonNotesChanged(val),
                              );
                        },
                        onTapOutside: (event) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                      ),

                      const SizedBox(height: 24),

                      // ── 4. Section 3 - Serah Terima Pekerjaan ──
                      _buildSectionHeader('3. SERAH TERIMA PEKERJAAN'),
                      const SizedBox(height: 10),

                      RichText(
                        text: TextSpan(
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          children: const [
                            TextSpan(
                                text:
                                    'Pilih Rekan Pengganti (Handover Successor)'),
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
                      const SizedBox(height: 6),

                      if (state.selectedColleague != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  state.selectedColleague!.name.isNotEmpty
                                      ? state.selectedColleague!.name[0]
                                          .toUpperCase()
                                      : '?',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          state.selectedColleague!.name,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          LucideIcons.checkCircle2,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (state.selectedColleague!
                                                .positionName !=
                                            null)
                                          state.selectedColleague!
                                              .positionName!,
                                        if (state.selectedColleague!
                                                .departmentName !=
                                            null)
                                          state.selectedColleague!
                                              .departmentName!,
                                      ].join(' • '),
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkOnSurfaceVariant
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _handleSelectColleague(state),
                                child: Text(
                                  'Ganti',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        InkWell(
                          onTap: () => _handleSelectColleague(state),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.userPlus,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Pilih Rekan Pengganti...',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.chevronRight,
                                  size: 18,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      _buildFieldLabel(
                        'Catatan Rencana Handover & Dokumentasi Proyek',
                        isRequired: false,
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        hintText:
                            'Contoh: Dokumentasi API, repositori arsitektur, dan kredensial staging diserahkan...',
                        controller: _handoverNotesController,
                        maxLines: 3,
                        onChanged: (val) {
                          context.read<CreateResignationBloc>().add(
                                CreateResignationHandoverNotesChanged(val),
                              );
                        },
                        onTapOutside: (event) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                      ),

                      const SizedBox(height: 24),

                      // ── 5. Section 4 - Lampiran Surat Resign ──
                      _buildSectionHeader('4. LAMPIRAN SURAT RESIGN'),
                      const SizedBox(height: 10),

                      if (state.file == null) ...[
                        InkWell(
                          onTap: _handlePickAttachment,
                          borderRadius: BorderRadius.circular(16),
                          child: DottedBorder(
                            options: RoundedRectDottedBorderOptions(
                              radius: const Radius.circular(16),
                              dashPattern: const [6, 4],
                              color: AppColors.primary.withValues(alpha: 0.6),
                              strokeWidth: 1.2,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      LucideIcons.fileUp,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Unggah Surat Resign Bertanda Tangan',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Format PDF, JPG, PNG (Maksimal 2MB)',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkOnSurfaceVariant
                                          : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.fileText,
                                  color: AppColors.errorRed,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.file!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'Dokumen',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: isDark
                                                ? AppColors.darkOnSurfaceVariant
                                                : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '•',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: isDark
                                                ? AppColors.darkOnSurfaceVariant
                                                : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          LucideIcons.check,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Terlampir',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  color: AppColors.errorRed,
                                  size: 18,
                                ),
                                onPressed: () {
                                  context.read<CreateResignationBloc>().add(
                                        const CreateResignationFileChanged(null),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── 6. Section 5 - Pernyataan Sukarela ──
                      InkWell(
                        onTap: () {
                          context.read<CreateResignationBloc>().add(
                                CreateResignationAgreementToggled(
                                  !state.isAgreed,
                                ),
                              );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.backgroundSubtle,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: state.isAgreed
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: state.isAgreed,
                                onChanged: (val) {
                                  context.read<CreateResignationBloc>().add(
                                        CreateResignationAgreementToggled(
                                          val ?? false,
                                        ),
                                      );
                                },
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Saya menyatakan bahwa pengajuan pengunduran diri ini dibuat secara sadar dan sukarela tanpa paksaan dari pihak mana pun, serta bersedia menyelesaikan seluruh tanggung jawab transisi.',
                                  style: AppTypography.bodySmall.copyWith(
                                    height: 1.45,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: const Border(
                  top: BorderSide(
                    color: AppColors.border,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: AppButton(
                      text: 'Batal',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: 'Kirim Pengajuan',
                      variant: AppButtonVariant.primary,
                      leadingIcon: LucideIcons.send,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting ? null : () => _handleSubmit(state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
