import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_bloc.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/activity_detail/activity_detail_state.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_map_card.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_timeline_section.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Halaman Detail Aktivitas & Verifikasi (Activity Detail & Verification)
/// Sesuai Clean Architecture & BLoC Pattern.
/// - Memuat detail aktivitas dari `GET /activity/{id}` via ActivityDetailBloc
/// - Mendukung Timeline 2-Fase Dinamis
/// - Mode Approver: View-only (tanpa tombol aksi)
/// - Mode Pembuat: Jika ongoing, menampilkan tombol Batalkan & Selesaikan aktivitas dengan modal upload gambar & notes
class ActivityDetailScreen extends StatelessWidget {
  final ActivityItem? activity;
  final String? activityId;
  final ActivityRepository? activityRepository;
  final ActivityDetailBloc? activityDetailBloc;

  const ActivityDetailScreen({
    super.key,
    this.activity,
    this.activityId,
    this.activityRepository,
    this.activityDetailBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (activityDetailBloc != null) {
      return BlocProvider<ActivityDetailBloc>.value(
        value: activityDetailBloc!,
        child: const _ActivityDetailView(),
      );
    }
    return BlocProvider<ActivityDetailBloc>(
      create: (context) => ActivityDetailBloc(
        repository: activityRepository,
        initialActivity: ActivityDetailBloc.resolveInitialActivity(
          activity: activity,
          activityId: activityId,
        ),
      )..add(ActivityDetailStarted(
          initialActivity: activity,
          activityId: activityId,
        )),
      child: const _ActivityDetailView(),
    );
  }
}

class _ActivityDetailView extends StatelessWidget {
  const _ActivityDetailView();

  void _handlePop(BuildContext context, bool hasChanged) {
    if (context.canPop()) {
      context.pop(hasChanged);
    } else {
      context.go('/activity');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivityDetailBloc, ActivityDetailState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.actionMessage != current.actionMessage ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.status == ActivityDetailStatus.actionSuccess &&
            state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(state.actionMessage!),
                  ),
                ],
              ),
              backgroundColor: state.actionMessage!.contains('selesai')
                  ? AppColors.brandTeal
                  : const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state.status == ActivityDetailStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memproses aksi: ${state.errorMessage}'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final item = state.activity;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgCol = isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.backgroundSubtle;
        final cardBg = isDark
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.surfaceContainerLowest;
        final borderCol =
            isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
        final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
        final subtitleCol =
            isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

        // Periksa status ongoing & loading
        final isOngoing = item.status == ActivityStatus.ongoing;
        final isLoading = state.status == ActivityDetailStatus.loading ||
            state.status == ActivityDetailStatus.submitting;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _handlePop(context, state.hasChanged);
            }
          },
          child: Scaffold(
            backgroundColor: bgCol,
            // 1. TopAppBar: Back Button, Title & Subtitle, ONLY Share Action
            appBar: AppBar(
              backgroundColor: bgCol,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: textCol,
                  size: 20,
                ),
                onPressed: () => _handlePop(context, state.hasChanged),
                tooltip: 'Kembali',
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Detail',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${item.id} • ${item.status.label}',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 12,
                      color: subtitleCol,
                    ),
                  ),
                ],
              ),
              actions: [
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    LucideIcons.share2,
                    color: textCol,
                    size: 20,
                  ),
                  tooltip: 'Bagikan Aktivitas',
                  onPressed: () => _handleShare(context, item),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // 2. Body Scrollable Content with Pull-To-Refresh
            body: SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ActivityDetailBloc>().add(
                        ActivityDetailFetchRequested(
                          id: item.id,
                          showLoading: false,
                        ),
                      );
                },
                color: AppColors.brandTeal,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Header Status & Employee Profile Card
                      _buildProfileStatusCard(
                        context: context,
                        item: item,
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Google Maps Card
                      ActivityMapCard(activity: item),

                      const SizedBox(height: 24),

                      // Section 3: 2-Phase Progress Timeline
                      ActivityTimelineSection(phases: item.activePhases),

                      const SizedBox(height: 24),

                      // Section 4: Export Summary Button (PDF)
                      _buildExportButton(
                          context, item, cardBg, borderCol, isDark),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Creator Action Bar (Only when user is creator and status is ongoing)
            bottomNavigationBar: (state.isCreator && isOngoing)
                ? _buildCreatorActionBar(context, item, isDark)
                : null,
          ),
        );
      },
    );
  }

  /// Bottom Action Bar untuk pembuat aktivitas saat status masih Ongoing
  Widget _buildCreatorActionBar(
    BuildContext context,
    ActivityItem item,
    bool isDark,
  ) {
    final barBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderCol, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 1. Batalkan Aktivitas (Outline Red)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const ValueKey('cancel_activity_btn'),
                  onPressed: () => _showActionBottomSheet(
                    context: context,
                    item: item,
                    isFinish: false,
                  ),
                  icon: const Icon(LucideIcons.xCircle, size: 18),
                  label: const Text(
                    'Batalkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFF87171), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Selesaikan Aktivitas (Solid Teal Brand)
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const ValueKey('complete_activity_btn'),
                  onPressed: () => _showActionBottomSheet(
                    context: context,
                    item: item,
                    isFinish: true,
                  ),
                  icon: const Icon(LucideIcons.checkCircle2, size: 18),
                  label: const Text(
                    'Selesaikan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan Bottom Sheet Modal untuk menyelesaikan atau membatalkan aktivitas
  Future<void> _showActionBottomSheet({
    required BuildContext context,
    required ActivityItem item,
    required bool isFinish,
  }) async {
    final bloc = context.read<ActivityDetailBloc>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final fieldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final actionColor =
        isFinish ? AppColors.brandTeal : const Color(0xFFDC2626);

    XFile? selectedFile;
    final notesController = TextEditingController(
      text: isFinish ? 'Aktivitas meeting dengan klien selesai dikerjakan.' : '',
    );
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: borderCol,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header Modal
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFinish
                                    ? LucideIcons.checkCircle2
                                    : LucideIcons.xCircle,
                                color: actionColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isFinish
                                        ? 'Selesaikan Aktivitas'
                                        : 'Batalkan Aktivitas',
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: textCol,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isFinish
                                        ? 'Unggah foto bukti penyelesaian dan tulis catatan.'
                                        : 'Unggah bukti (opsional) dan tulis alasan pembatalan.',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: subtitleCol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(LucideIcons.x,
                                  color: subtitleCol, size: 20),
                              onPressed: () => Navigator.of(sheetCtx).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section Foto Bukti
                        Text(
                          isFinish
                              ? 'Foto Bukti Penyelesaian (Opsional)'
                              : 'Foto Bukti Pembatalan (Opsional)',
                          style: AppTypography.labelMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (selectedFile == null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderCol, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(
                                        source: ImageSource.camera,
                                        maxWidth: 1600,
                                        maxHeight: 1600,
                                        imageQuality: 85,
                                      );
                                      if (picked != null) {
                                        setModalState(
                                            () => selectedFile = picked);
                                      }
                                    },
                                    icon: const Icon(LucideIcons.camera,
                                        size: 16),
                                    label: const Text('Kamera',
                                        style: TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textCol,
                                      side: BorderSide(color: borderCol),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 1600,
                                        maxHeight: 1600,
                                        imageQuality: 85,
                                      );
                                      if (picked != null) {
                                        setModalState(
                                            () => selectedFile = picked);
                                      }
                                    },
                                    icon: const Icon(LucideIcons.image,
                                        size: 16),
                                    label: const Text('Galeri',
                                        style: TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textCol,
                                      side: BorderSide(color: borderCol),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: actionColor.withValues(alpha: 0.5),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: kIsWeb
                                      ? Image.network(
                                          selectedFile!.path,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(LucideIcons.image,
                                                  size: 30),
                                        )
                                      : Image.file(
                                          File(selectedFile!.path),
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(LucideIcons.image,
                                                  size: 30),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFile!.name.isNotEmpty
                                            ? selectedFile!.name
                                            : 'Foto bukti terpilih',
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: textCol,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Foto siap diunggah',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2,
                                      color: Color(0xFFEF4444), size: 18),
                                  onPressed: () {
                                    setModalState(() => selectedFile = null);
                                  },
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 18),

                        // Section Notes
                        Text(
                          isFinish
                              ? 'Catatan Pekerjaan (Wajib)'
                              : 'Alasan Pembatalan (Wajib)',
                          style: AppTypography.labelMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const ValueKey('action_notes_field'),
                          controller: notesController,
                          maxLines: 4,
                          minLines: 3,
                          style:
                              AppTypography.bodyMedium.copyWith(color: textCol),
                          decoration: InputDecoration(
                            hintText: isFinish
                                ? 'Contoh: Aktivitas meeting dengan klien selesai dikerjakan.'
                                : 'Tuliskan alasan pembatalan aktivitas...',
                            hintStyle: AppTypography.bodySmall
                                .copyWith(color: subtitleCol),
                            filled: true,
                            fillColor: fieldBg,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderCol),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                   BorderSide(color: actionColor, width: 1.5),
                            ),
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            errorText!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Tombol Submit
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            key: const ValueKey('submit_action_confirm_btn'),
                            onPressed: () async {
                              final notes = notesController.text.trim();
                              if (notes.isEmpty) {
                                setModalState(() {
                                  errorText = 'Catatan tidak boleh kosong!';
                                });
                                return;
                              }

                              Navigator.of(sheetCtx).pop();

                              if (isFinish) {
                                bloc.add(ActivityDetailFinishSubmitted(
                                  id: item.id,
                                  notes: notes,
                                  file: selectedFile,
                                ));
                              } else {
                                bloc.add(ActivityDetailCancelSubmitted(
                                  id: item.id,
                                  notes: notes,
                                  file: selectedFile,
                                ));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: actionColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isFinish
                                  ? 'Selesaikan Aktivitas'
                                  : 'Konfirmasi Batalkan',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Card Status & Profil Karyawan
  Widget _buildProfileStatusCard({
    required BuildContext context,
    required ActivityItem item,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required bool isDark,
  }) {
    final categoryText = item.category ?? item.title;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category Badge & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category Chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.brandTeal.withValues(alpha: 0.15)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categoryText,
                  style: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item.status.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.status.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.status.label,
                      style: TextStyle(
                        color: item.status.textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Avatar + Name + Role & Department
          Row(
            children: [
              AppAvatar(
                name: item.userName,
                initials: item.initials,
                imageUrl: item.avatarUrl,
                size: 48,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                textColor: textCol,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.userRole,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: subtitleCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.department} • ${item.company}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        color: subtitleCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 3: Bottom Location
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderCol, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  color: Color(0xFF0D9488),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.location,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  /// Tombol Export PDF
  Widget _buildExportButton(
    BuildContext context,
    ActivityItem item,
    Color cardBg,
    Color borderCol,
    bool isDark,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    LucideIcons.fileText,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mengunduh ringkasan PDF untuk aktivitas ${item.id}...',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.brandTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(
          LucideIcons.download,
          size: 18,
          color: Color(0xFF0D9488),
        ),
        label: const Text(
          'Export Activity Summary (PDF)',
          style: TextStyle(
            color: Color(0xFF0D9488),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: cardBg,
          side: BorderSide(color: borderCol, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  /// Menangani aksi share laporan aktivitas
  void _handleShare(BuildContext context, ActivityItem item) {
    final shareContent = StringBuffer()
      ..writeln('📋 LAPORAN AKTIVITAS OASISH HRIS')
      ..writeln('ID: ${item.id}')
      ..writeln('Judul: ${item.title}')
      ..writeln('Karyawan: ${item.userName} (${item.userRole})')
      ..writeln('Departemen: ${item.department}')
      ..writeln('Status: ${item.status.label}')
      ..writeln('Lokasi: ${item.location}')
      ..writeln('Waktu: ${item.time}')
      ..writeln('\nDeskripsi:')
      ..writeln(item.description);

    SharePlus.instance.share(
      ShareParams(
        text: shareContent.toString(),
        subject: 'Laporan Aktivitas: ${item.title} (${item.id})',
      ),
    );
  }
}
