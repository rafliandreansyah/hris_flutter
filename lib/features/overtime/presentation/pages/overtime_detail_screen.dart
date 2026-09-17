import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:hris_flutter/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_bloc.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_event.dart';
import 'package:hris_flutter/features/overtime/presentation/bloc/overtime_detail/overtime_detail_state.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_action_dialog.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_approver_card.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_employee_card.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_evidence_card.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_detail_overview_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Halaman Detail Pengajuan Lembur (Overtime Request Detail)
/// Sesuai spesifikasi desain Google Stitch: "Oasish Overtime Request Detail" (M3 Teal Oasis).
///
/// Logika Akses & Approval:
/// - 3 Status Utama: `requested`, `approved`, `rejected`.
/// - Sebagai Approver (`isApprover: true`):
///   Jika status masih `requested`, muncul tombol aksi "Reject" dan "Approve Overtime" di Bottom Bar.
/// - Sebagai Pengaju (`isApprover: false`):
///   Jika status masih `requested`, muncul opsi "Hapus Pengajuan" di AppBar.
/// - Jika status sudah final (`approved` atau `rejected`):
///   Seluruh tombol aksi (Approve, Reject, Delete) disembunyikan.
/// - Card Assigned Approver disembunyikan otomatis jika data `approver` adalah `null`.
class OvertimeDetailScreen extends StatelessWidget {
  final String id;
  final bool isApprover;
  final OvertimeRepository? repository;
  final OvertimeDetailBloc? bloc;

  const OvertimeDetailScreen({
    super.key,
    required this.id,
    this.isApprover = false,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<OvertimeDetailBloc>.value(
        value: bloc!,
        child: _OvertimeDetailView(id: id, isApprover: isApprover),
      );
    }

    return BlocProvider<OvertimeDetailBloc>(
      create: (context) => OvertimeDetailBloc(repository: repository)
        ..add(OvertimeDetailStarted(id: id, isApprover: isApprover)),
      child: _OvertimeDetailView(id: id, isApprover: isApprover),
    );
  }
}

class _OvertimeDetailView extends StatefulWidget {
  final String id;
  final bool isApprover;

  const _OvertimeDetailView({required this.id, required this.isApprover});

  @override
  State<_OvertimeDetailView> createState() => _OvertimeDetailViewState();
}

class _OvertimeDetailViewState extends State<_OvertimeDetailView> {
  bool _hasChanged = false;
  bool? _submittingIsApproved;

  void _handlePop() {
    if (context.canPop()) {
      context.pop(_hasChanged);
    } else {
      context.go('/overtime');
    }
  }

  void _handleShare(OvertimeDetailData detail) {
    final text = StringBuffer()
      ..writeln('📋 DETAIL PENGAJUAN LEMBUR')
      ..writeln('ID: ${detail.id}')
      ..writeln('Karyawan: ${detail.employee.fullName}')
      ..writeln('Departemen: ${detail.employee.department?.name ?? '-'}')
      ..writeln('Status: ${detail.statusLabel}')
      ..writeln('Tanggal: ${detail.formattedDate}')
      ..writeln('Waktu: ${detail.formattedTimeRange}')
      ..writeln('Durasi: ${detail.durationHoursLabel}')
      ..writeln('Catatan: ${detail.notes ?? '-'}');

    SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: 'Detail Pengajuan Lembur: ${detail.employee.fullName}',
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await AppDialogUtil.showWarning<bool>(
      context,
      title: 'Hapus Pengajuan',
      message: 'Apakah Anda yakin ingin menghapus pengajuan lembur ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      onConfirm: () {},
    );

    if (confirmed == true && context.mounted) {
      context.read<OvertimeDetailBloc>().add(const OvertimeDetailDeleteSubmitted());
    }
  }

  Future<void> _handleApprove(BuildContext context, bool isApproved) async {
    final notes = await OvertimeActionDialog.show(context, isApproved: isApproved);
    if (notes != null && context.mounted) {
      setState(() {
        _submittingIsApproved = isApproved;
      });
      context.read<OvertimeDetailBloc>().add(
            OvertimeDetailApproveSubmitted(
              isApproved: isApproved,
              approverNotes: notes,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return BlocConsumer<OvertimeDetailBloc, OvertimeDetailState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.actionMessage != curr.actionMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.status == OvertimeDetailStatus.actionSuccess) {
          _submittingIsApproved = null;
          _hasChanged = true;
          if (state.actionMessage != null) {
            AppDialogUtil.showSuccess(
              context,
              message: state.actionMessage!,
            );
          }
        } else if (state.status == OvertimeDetailStatus.deleteSuccess) {
          _submittingIsApproved = null;
          _hasChanged = true;
          AppDialogUtil.showSuccess(
            context,
            message: state.actionMessage ?? 'Pengajuan lembur berhasil dihapus',
            onOk: () {
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/overtime');
              }
            },
          );
        } else if (state.status == OvertimeDetailStatus.actionFailure) {
          _submittingIsApproved = null;
          if (state.errorMessage != null) {
            AppDialogUtil.showError(
              context,
              message: state.errorMessage!,
            );
          }
        }
      },
      builder: (context, state) {
        final detail = state.detail;
        final shortId = detail != null && detail.id.isNotEmpty
            ? (detail.id.length >= 8 ? detail.id.substring(0, 8) : detail.id)
            : widget.id;
        final statusText = detail?.status ?? 'requested';

        // Tampilkan bottom bar aksi HANYA jika:
        // 1. User membuka sebagai approver (state.isApprover == true)
        // 2. Status masih requested (belum approved/rejected)
        final canApproveReject = state.isApprover &&
            detail != null &&
            detail.isRequested;

        // Opsi delete hanya untuk pengaju sendiri dan status masih requested
        final canDelete = !state.isApprover &&
            detail != null &&
            detail.isRequested;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handlePop();
          },
          child: Scaffold(
            backgroundColor: bgCol,
            appBar: AppBar(
              backgroundColor: cardBg,
              elevation: 0,
              scrolledUnderElevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              leading: IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
                onPressed: _handlePop,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Overtime Request Detail',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Request ID: $shortId • $statusText',
                    style: AppTypography.labelSmall.copyWith(
                      color: subtitleCol,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                if (detail != null)
                  IconButton(
                    icon: Icon(LucideIcons.share2, color: textCol, size: 20),
                    tooltip: 'Bagikan',
                    onPressed: () => _handleShare(detail),
                  ),
                // Menu pojok kanan atas: Opsi Hapus bila pengajuan milik sendiri & status masih requested
                if (canDelete)
                  PopupMenuButton<String>(
                    icon: Icon(LucideIcons.ellipsisVertical, color: textCol, size: 20),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _handleDelete(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2,
                                color: Color(0xFFEF4444), size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Hapus Pengajuan',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: _buildBody(context, state, canApproveReject),
            bottomNavigationBar: canApproveReject
                ? _buildBottomActionBar(context, state, isDark, borderCol, cardBg)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    OvertimeDetailState state,
    bool showBottomBar,
  ) {
    // 1. Loading State
    if (state.status == OvertimeDetailStatus.loading ||
        (state.status == OvertimeDetailStatus.initial && state.detail == null)) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandTeal,
          strokeWidth: 2.5,
        ),
      );
    }

    // 2. Failure State
    if (state.status == OvertimeDetailStatus.failure && state.detail == null) {
      final is404 = state.statusCode == 404;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                is404 ? LucideIcons.fileQuestion : LucideIcons.alertCircle,
                size: 54,
                color: is404
                    ? AppColors.onSurfaceVariant
                    : const Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                is404
                    ? 'Pengajuan Lembur Tidak Ditemukan'
                    : 'Gagal Memuat Detail',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Terjadi kesalahan saat memuat data.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (is404)
                ElevatedButton.icon(
                  onPressed: _handlePop,
                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
                  label: const Text('Kembali'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<OvertimeDetailBloc>().add(
                          OvertimeDetailStarted(
                            id: widget.id,
                            isApprover: widget.isApprover,
                          ),
                        );
                  },
                  icon: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final detail = state.detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    final hasApprover = detail.approver != null;

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<OvertimeDetailBloc>()
            .add(const OvertimeDetailRefreshRequested());
        await Future.delayed(const Duration(milliseconds: 300));
      },
      color: AppColors.brandTeal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Card 1: Overview & Schedule Highlight ─────────────────────
          OvertimeDetailOverviewCard(detail: detail),
          const SizedBox(height: 14),

          // ── Card 2: Requester Employee Information ──────────────────
          OvertimeDetailEmployeeCard(employee: detail.employee),
          const SizedBox(height: 14),

          // ── Card 3: Assigned Approver (Sembunyi jika approver == null)
          if (hasApprover) ...[
            OvertimeDetailApproverCard(approver: detail.approver!),
            const SizedBox(height: 14),
          ],

          // ── Card 4: Work Evidence Photo ──────────────────────────────
          OvertimeDetailEvidenceCard(
            imageUrl: detail.resolvedFilePath,
          ),

          // Space cadangan bila bottom action bar muncul
          if (showBottomBar) const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    OvertimeDetailState state,
    bool isDark,
    Color borderCol,
    Color cardBg,
  ) {
    final isSubmitting =
        state.status == OvertimeDetailStatus.submittingAction;
    final isApproving = isSubmitting && _submittingIsApproved == true;
    final isRejecting = isSubmitting && _submittingIsApproved == false;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderCol, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          // ── Tombol Reject ───────────────────────────────────────────
          Expanded(
            child: AppButton(
              key: const ValueKey('overtime_detail_reject_button'),
              text: isRejecting ? 'Memproses...' : 'Reject',
              leadingIcon: isRejecting ? null : LucideIcons.x,
              isLoading: isRejecting,
              variant: AppButtonVariant.outlined,
              foregroundColor: const Color(0xFFEF4444),
              borderColor: const Color(0xFFEF4444),
              height: 48,
              borderRadius: 100,
              onPressed:
                  isSubmitting ? null : () => _handleApprove(context, false),
            ),
          ),
          const SizedBox(width: 14),

          // ── Tombol Approve Overtime ─────────────────────────────────
          Expanded(
            flex: 1,
            child: AppButton(
              key: const ValueKey('overtime_detail_approve_button'),
              text: isApproving ? 'Memproses...' : 'Approve Overtime',
              leadingIcon: isApproving ? null : LucideIcons.check,
              isLoading: isApproving,
              variant: AppButtonVariant.primary,
              height: 48,
              borderRadius: 100,
              onPressed:
                  isSubmitting ? null : () => _handleApprove(context, true),
            ),
          ),
        ],
      ),
    );
  }
}
