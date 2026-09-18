import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_request_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_event.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_request_detail/attendance_request_detail_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_action_dialog.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_approver_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_employee_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_location_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_overview_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_photo_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Halaman Detail Permohonan Presensi Luar Kantor
/// Sesuai spesifikasi desain Google Stitch: "Oasish Outside Attendance Request Detail Screen" (M3 Teal Oasis).
///
/// Logika Akses & Approval:
/// - 3 Status Utama: `requested`, `approved`, `rejected`.
/// - Sebagai Approver (`isApprover: true`):
///   Jika status masih `requested`, muncul tombol aksi "Tolak" dan "Setujui Presensi" di Bottom Bar.
///   Jika status sudah `approved` atau `rejected`, tombol disembunyikan.
/// - Sebagai Pengaju (`isApprover: false`):
///   Jika status masih `requested`, muncul opsi "Hapus Pengajuan" di AppBar menu.
///   Jika status sudah `approved` atau `rejected`, opsi hapus disembunyikan.
/// - Konfirmasi: Setiap aksi Approve, Reject, dan Delete selalu menampilkan dialog konfirmasi terlebih dahulu.
/// - Foto Bukti: Jika metode kehadiran bukan foto (`method != 'photo'`), kartu foto bukti otomatis disembunyikan.
class AttendanceRequestDetailScreen extends StatelessWidget {
  final String id;
  final bool isApprover;
  final AttendanceRequestRepository? repository;
  final AttendanceRequestDetailBloc? bloc;

  const AttendanceRequestDetailScreen({
    super.key,
    required this.id,
    this.isApprover = false,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<AttendanceRequestDetailBloc>.value(
        value: bloc!,
        child: _AttendanceRequestDetailView(id: id, isApprover: isApprover),
      );
    }

    return BlocProvider<AttendanceRequestDetailBloc>(
      create: (context) => AttendanceRequestDetailBloc(repository: repository)
        ..add(AttendanceRequestDetailStarted(id: id, isApprover: isApprover)),
      child: _AttendanceRequestDetailView(id: id, isApprover: isApprover),
    );
  }
}

class _AttendanceRequestDetailView extends StatefulWidget {
  final String id;
  final bool isApprover;

  const _AttendanceRequestDetailView({
    required this.id,
    required this.isApprover,
  });

  @override
  State<_AttendanceRequestDetailView> createState() =>
      _AttendanceRequestDetailViewState();
}

class _AttendanceRequestDetailViewState
    extends State<_AttendanceRequestDetailView> {
  bool _hasChanged = false;
  bool? _submittingIsApproved;

  void _handlePop() {
    if (context.canPop()) {
      context.pop(_hasChanged);
    } else {
      context.go('/attendance-requests');
    }
  }

  void _handleShare(AttendanceRequestDetailData detail) {
    final text = StringBuffer()
      ..writeln('📋 DETAIL PRESENSI LUAR KANTOR')
      ..writeln('ID: ${detail.id}')
      ..writeln('Pegawai: ${detail.employee.fullName}')
      ..writeln('Departemen: ${detail.employee.department?.name ?? '-'}')
      ..writeln('Status: ${detail.statusLabel}')
      ..writeln('Tanggal: ${detail.formattedDate}')
      ..writeln('Tipe: ${detail.attendanceTypeLabel}')
      ..writeln('Metode: ${detail.method.toUpperCase()}')
      ..writeln('Masuk: ${detail.formattedInTime}')
      ..writeln('Pulang: ${detail.formattedOutTime}')
      ..writeln('Lokasi: ${detail.address ?? "-"}')
      ..writeln('Alasan: ${detail.reason ?? '-'}');

    SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: 'Detail Presensi Luar Kantor: ${detail.employee.fullName}',
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await AppDialogUtil.showWarning<bool>(
      context,
      title: 'Hapus Pengajuan',
      message:
          'Apakah Anda yakin ingin menghapus permohonan presensi luar kantor ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      onConfirm: () {},
    );

    if (confirmed == true && context.mounted) {
      context
          .read<AttendanceRequestDetailBloc>()
          .add(const AttendanceRequestDetailDeleteSubmitted());
    }
  }

  Future<void> _handleApprove(BuildContext context, bool isApproved) async {
    final notes = await AttendanceRequestActionDialog.show(
      context,
      isApproved: isApproved,
    );
    if (notes != null && context.mounted) {
      setState(() {
        _submittingIsApproved = isApproved;
      });
      context.read<AttendanceRequestDetailBloc>().add(
            AttendanceRequestDetailApproveSubmitted(
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
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return BlocConsumer<AttendanceRequestDetailBloc, AttendanceRequestDetailState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.actionMessage != curr.actionMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.status == AttendanceRequestDetailStatus.actionSuccess) {
          _submittingIsApproved = null;
          _hasChanged = true;
          if (state.actionMessage != null) {
            AppDialogUtil.showSuccess(
              context,
              message: state.actionMessage!,
            );
          }
        } else if (state.status == AttendanceRequestDetailStatus.deleteSuccess) {
          _submittingIsApproved = null;
          _hasChanged = true;
          AppDialogUtil.showSuccess(
            context,
            message: state.actionMessage ?? 'Permohonan presensi berhasil dihapus',
            onOk: () {
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/attendance-requests');
              }
            },
          );
        } else if (state.status == AttendanceRequestDetailStatus.actionFailure) {
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
        final statusText = detail?.status.toUpperCase() ?? 'REQUESTED';

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
                    'Detail Presensi Luar',
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
                    icon: Icon(
                      LucideIcons.ellipsisVertical,
                      color: textCol,
                      size: 20,
                    ),
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
                            Icon(
                              LucideIcons.trash2,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
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
            body: _buildBody(context, state),
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
    AttendanceRequestDetailState state,
  ) {
    // 1. Loading State
    if (state.status == AttendanceRequestDetailStatus.loading ||
        (state.status == AttendanceRequestDetailStatus.initial &&
            state.detail == null)) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandTeal,
          strokeWidth: 2.5,
        ),
      );
    }

    // 2. Failure State
    if (state.status == AttendanceRequestDetailStatus.failure &&
        state.detail == null) {
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
                    ? 'Permohonan Presensi Tidak Ditemukan'
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
                    context.read<AttendanceRequestDetailBloc>().add(
                          const AttendanceRequestDetailRefreshRequested(),
                        );
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
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

    // 3. Success / Content View
    final detail = state.detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<AttendanceRequestDetailBloc>()
            .add(const AttendanceRequestDetailRefreshRequested());
      },
      color: AppColors.brandTeal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Section 1: Overview & Status Card
          AttendanceRequestOverviewCard(detail: detail),
          const SizedBox(height: 16),

          // Section 2: Geo-Location Card
          AttendanceRequestLocationCard(detail: detail),
          const SizedBox(height: 16),

          // Section 3: Requester Profile Card
          AttendanceRequestEmployeeCard(employee: detail.employee),
          const SizedBox(height: 16),

          // Section 4: Approver Profile Card
          AttendanceRequestApproverCard(approver: detail.approver),

          // Section 5: Photo Proof Card (otomatis tersembunyi jika bukan metode foto)
          if (detail.isPhotoMethod) ...[
            const SizedBox(height: 16),
            AttendanceRequestPhotoCard(detail: detail),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    AttendanceRequestDetailState state,
    bool isDark,
    Color borderCol,
    Color cardBg,
  ) {
    final isSubmitting =
        state.status == AttendanceRequestDetailStatus.submittingAction;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderCol, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol Tolak
          Expanded(
            flex: 1,
            child: AppButton(
              text: 'Tolak',
              variant: AppButtonVariant.outlined,
              isLoading: isSubmitting && _submittingIsApproved == false,
              onPressed: isSubmitting ? null : () => _handleApprove(context, false),
            ),
          ),
          const SizedBox(width: 12),
          // Tombol Setujui Presensi
          Expanded(
            flex: 2,
            child: AppButton(
              text: 'Setujui Presensi',
              variant: AppButtonVariant.primary,
              isLoading: isSubmitting && _submittingIsApproved == true,
              onPressed: isSubmitting ? null : () => _handleApprove(context, true),
            ),
          ),
        ],
      ),
    );
  }
}
