import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_bloc.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_event.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/leave_detail/leave_detail_state.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_action_dialog.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_approver_card.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_document_card.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_employee_card.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_detail_overview_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Halaman Detail Pengajuan Cuti / Izin (Leave Request Detail)
/// Sesuai desain Google Stitch: "Oasish Leave Request Detail - Photo Proof Style".
///
/// Logika Akses & Approval:
/// - Jika dibuka sebagai Approver (`isApprover: true`) dan status masih pending/requested,
///   muncul tombol aksi "Reject" dan "Approve" di bottom bar.
/// - Jika sudah di-approve/reject ATAU dibuka sebagai pengaju sendiri (`isApprover: false`),
///   tombol aksi disembunyikan.
/// - Pengaju sendiri dapat menghapus pengajuan melalui menu pojok kanan atas (`DELETE /leave-request/{id}`).
/// - Card Assigned Approver disembunyikan secara otomatis jika data `approver` adalah `null`.
class LeaveDetailScreen extends StatelessWidget {
  final String id;
  final bool isApprover;
  final LeaveRepository? repository;
  final LeaveDetailBloc? bloc;

  const LeaveDetailScreen({
    super.key,
    required this.id,
    this.isApprover = false,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<LeaveDetailBloc>.value(
        value: bloc!,
        child: _LeaveDetailView(id: id, isApprover: isApprover),
      );
    }

    return BlocProvider<LeaveDetailBloc>(
      create: (context) => LeaveDetailBloc(repository: repository)
        ..add(LeaveDetailStarted(id: id, isApprover: isApprover)),
      child: _LeaveDetailView(id: id, isApprover: isApprover),
    );
  }
}

class _LeaveDetailView extends StatefulWidget {
  final String id;
  final bool isApprover;

  const _LeaveDetailView({required this.id, required this.isApprover});

  @override
  State<_LeaveDetailView> createState() => _LeaveDetailViewState();
}

class _LeaveDetailViewState extends State<_LeaveDetailView> {
  bool _hasChanged = false;

  void _handlePop() {
    if (context.canPop()) {
      context.pop(_hasChanged);
    } else {
      context.go('/leave');
    }
  }

  void _handleShare(LeaveRequestDetailData detail) {
    final text = StringBuffer()
      ..writeln('📋 DETAIL PENGAJUAN CUTI')
      ..writeln('ID: ${detail.id}')
      ..writeln('Jenis: ${detail.leaveType.name}')
      ..writeln('Karyawan: ${detail.employee.fullName}')
      ..writeln('Departemen: ${detail.employee.department?.name ?? '-'}')
      ..writeln('Status: ${detail.statusLabel}')
      ..writeln('Tanggal: ${detail.formattedDateRange}')
      ..writeln('Durasi: ${detail.durationLabel}')
      ..writeln('Alasan: ${detail.notes ?? '-'}');

    SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: 'Detail Pengajuan Cuti: ${detail.employee.fullName}',
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await AppDialogUtil.showWarning<bool>(
      context,
      title: 'Hapus Pengajuan',
      message: 'Apakah Anda yakin ingin menghapus pengajuan cuti ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      onConfirm: () {},
    );

    if (confirmed == true && context.mounted) {
      context.read<LeaveDetailBloc>().add(const LeaveDetailDeleteSubmitted());
    }
  }

  Future<void> _handleApprove(BuildContext context, bool isApproved) async {
    final notes = await LeaveActionDialog.show(context, isApproved: isApproved);
    if (notes != null && context.mounted) {
      context.read<LeaveDetailBloc>().add(
            LeaveDetailApproveSubmitted(
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

    return BlocConsumer<LeaveDetailBloc, LeaveDetailState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.actionMessage != curr.actionMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.status == LeaveDetailStatus.actionSuccess) {
          _hasChanged = true;
          if (state.actionMessage != null) {
            AppDialogUtil.showSuccess(
              context,
              message: state.actionMessage!,
            );
          }
        } else if (state.status == LeaveDetailStatus.deleteSuccess) {
          _hasChanged = true;
          AppDialogUtil.showSuccess(
            context,
            message: state.actionMessage ?? 'Pengajuan cuti berhasil dihapus',
            onOk: () {
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/leave');
              }
            },
          );
        } else if (state.status == LeaveDetailStatus.actionFailure &&
            state.errorMessage != null) {
          AppDialogUtil.showError(
            context,
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final detail = state.detail;
        final shortId = detail != null && detail.id.isNotEmpty
            ? (detail.id.length >= 8 ? detail.id.substring(0, 8) : detail.id)
            : widget.id;
        final leaveTypeName = detail?.leaveType.name ?? 'Leave';

        // Tampilkan bottom bar aksi HANYA jika:
        // 1. User membuka dalam konteks approver (state.isApprover == true)
        // 2. Pengajuan masih berstatus pending/requested
        final canApproveReject = state.isApprover &&
            detail != null &&
            detail.isPending;

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
                    'Leave Request Detail',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Request ID: $shortId • $leaveTypeName',
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
                // Menu pojok kanan atas: Opsi Hapus bila pengajuan milik sendiri
                if (!state.isApprover && detail != null)
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
    LeaveDetailState state,
    bool showBottomBar,
  ) {
    // 1. Loading State
    if (state.status == LeaveDetailStatus.loading ||
        (state.status == LeaveDetailStatus.initial && state.detail == null)) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandTeal,
          strokeWidth: 2.5,
        ),
      );
    }

    // 2. Failure State
    if (state.status == LeaveDetailStatus.failure && state.detail == null) {
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
                    ? 'Pengajuan Cuti Tidak Ditemukan'
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
                    context.read<LeaveDetailBloc>().add(
                          LeaveDetailStarted(
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

    final hasDocument =
        detail.filePath != null && detail.filePath!.trim().isNotEmpty;
    final hasApprover = detail.approver != null;

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<LeaveDetailBloc>()
            .add(const LeaveDetailRefreshRequested());
        await Future.delayed(const Duration(milliseconds: 300));
      },
      color: AppColors.brandTeal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Card 1: Overview & Status Banner ────────────────────────
          LeaveDetailOverviewCard(detail: detail),
          const SizedBox(height: 14),

          // ── Card 2: Requester Employee Information ──────────────────
          LeaveDetailEmployeeCard(employee: detail.employee),
          const SizedBox(height: 14),

          // ── Card 3: Assigned Approver (Sembunyi jika approver == null)
          if (hasApprover) ...[
            LeaveDetailApproverCard(
              approver: detail.approver!,
              approverNotes: detail.approverNotes,
            ),
            const SizedBox(height: 14),
          ],

          // ── Card 4: Supporting Document (Sembunyi jika filePath == null)
          if (hasDocument) ...[
            LeaveDetailDocumentCard(
              imageUrl: detail.resolvedFilePath ?? detail.filePath!,
            ),
            const SizedBox(height: 14),
          ],

          // Space cadangan bila bottom action bar muncul
          if (showBottomBar) const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    LeaveDetailState state,
    bool isDark,
    Color borderCol,
    Color cardBg,
  ) {
    final isSubmitting =
        state.status == LeaveDetailStatus.submittingAction;

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
            child: OutlinedButton.icon(
              onPressed:
                  isSubmitting ? null : () => _handleApprove(context, false),
              icon: const Icon(LucideIcons.x, size: 18),
              label: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Tombol Approve ──────────────────────────────────────────
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  isSubmitting ? null : () => _handleApprove(context, true),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(LucideIcons.check, size: 18),
              label: Text(
                isSubmitting ? 'Memproses...' : 'Approve',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.inversePrimary
                    : AppColors.brandTeal,
                foregroundColor: isDark ? const Color(0xFF003732) : Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
