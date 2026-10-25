import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_bloc.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_detail/asset_detail_state.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_current_holder_card.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_detail_hero_card.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_detail_spec_card.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_direct_transfer_modal.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_handover_timeline_card.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_pool_handover_modal.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_reject_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Detail Fasilitas & Riwayat Handover (Chain of Custody Timeline)
class AssetDetailScreen extends StatelessWidget {
  final String assetId;
  final AssetRepository? repository;

  const AssetDetailScreen({
    super.key,
    required this.assetId,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssetDetailBloc>(
      create: (context) => AssetDetailBloc(repository: repository)
        ..add(AssetDetailStarted(assetId)),
      child: const _AssetDetailView(),
    );
  }
}

class _AssetDetailView extends StatelessWidget {
  const _AssetDetailView();

  Future<void> _handleAccept(BuildContext context, AssetDetailState state) async {
    final pending = state.asset?.pendingAssignment;
    if (pending == null) return;

    final confirmed = await AppDialogUtil.showConfirmation(
      context,
      title: 'Terima Penyerahan Fasilitas',
      message:
          'Apakah Anda yakin ingin menerima fasilitas "${state.asset!.name}"? Fasilitas ini akan menjadi tanggung jawab fisik Anda.',
      confirmText: 'Terima Aset',
      confirmIcon: LucideIcons.check,
      confirmButtonColor: AppColors.brandTeal,
    );

    if (confirmed && context.mounted) {
      context.read<AssetDetailBloc>().add(
            AssetDetailAssignmentApproved(
              assignmentId: pending.id,
            ),
          );
    }
  }

  Future<void> _handleReject(BuildContext context, AssetDetailState state) async {
    final pending = state.asset?.pendingAssignment;
    if (pending == null) return;

    // Gunakan wrapper AssetListItem minimal untuk bottom sheet penolakan
    final mockItem = AssetListItem(
      id: state.asset!.id,
      assignmentId: pending.id,
      assetCode: state.asset!.assetCode,
      name: state.asset!.name,
      status: pending.status,
      condition: pending.conditionOnCheckout,
    );

    await AssetRejectBottomSheet.show(
      context,
      asset: mockItem,
      onReject: (reason) async {
        context.read<AssetDetailBloc>().add(
              AssetDetailAssignmentRejected(
                assignmentId: pending.id,
                reason: reason,
              ),
            );
      },
    );
  }

  void _openDirectTransfer(BuildContext context, AssetDetailState state) {
    if (state.asset == null) return;

    AssetDirectTransferModal.show(
      context,
      asset: state.asset!,
      onSubmit: (payload) async {
        context.read<AssetDetailBloc>().add(AssetDetailDirectTransferred(payload));
      },
    );
  }

  void _openPoolHandover(BuildContext context, AssetDetailState state) {
    if (state.asset == null) return;

    AssetPoolHandoverModal.show(
      context,
      asset: state.asset!,
      onSubmit: (payload) async {
        context.read<AssetDetailBloc>().add(AssetDetailPoolHandedOver(payload));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return BlocConsumer<AssetDetailBloc, AssetDetailState>(
      listener: (context, state) {
        if (state.actionStatus == AssetDetailActionStatus.success &&
            state.actionMessage != null) {
          AppDialogUtil.showSuccess(
            context,
            message: state.actionMessage!,
          );
        } else if (state.actionStatus == AssetDetailActionStatus.failure &&
            state.actionMessage != null) {
          AppDialogUtil.showError(
            context,
            message: state.actionMessage!,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: bgCol.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 1.5,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                color: textCol,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            titleSpacing: 0,
            title: Text(
                  'Detail Fasilitas',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 18,
                  ),
                ),
          ),
          bottomNavigationBar: _buildBottomBar(context, state),
          body: _buildBody(context, state, primaryCol, textCol, subtitleCol),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AssetDetailState state,
    Color primaryCol,
    Color textCol,
    Color subtitleCol,
  ) {
    if (state.status == AssetDetailStatus.failure && state.asset == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertCircle,
                  size: 32,
                  color: AppColors.errorRed,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Gagal Memuat Detail Fasilitas',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.errorMessage ?? 'Terjadi kesalahan pada sistem',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.errorStatusCode == 404)
                AppButton(
                  text: 'Kembali',
                  leadingIcon: LucideIcons.arrowLeft,
                  onPressed: () => Navigator.of(context).maybePop(),
                  width: 140,
                  height: 42,
                )
              else
                AppButton(
                  text: 'Coba Lagi',
                  leadingIcon: LucideIcons.rotateCcw,
                  onPressed: () {
                    context.read<AssetDetailBloc>().add(const AssetDetailRefreshed());
                  },
                  width: 140,
                  height: 42,
                ),
            ],
          ),
        ),
      );
    }

    if (state.asset == null) {
      if (state.status == AssetDetailStatus.success) {
        return const Center(child: Text('Data aset tidak tersedia'));
      }
      return const RequestCardShimmerLoading(itemCount: 3);
    }

    final asset = state.asset!;

    return RefreshIndicator(
      color: primaryCol,
      onRefresh: () async {
        context.read<AssetDetailBloc>().add(const AssetDetailRefreshed());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card
            AssetDetailHeroCard(asset: asset),
            const SizedBox(height: AppSpacing.md),

            // 2. Pemegang Fasilitas Saat Ini
            AssetCurrentHolderCard(asset: asset),
            const SizedBox(height: AppSpacing.md),

            // 3. Spesifikasi Teknis Unit
            AssetDetailSpecCard(asset: asset),
            const SizedBox(height: AppSpacing.md),

            // 4. Riwayat Handover (Chain of Custody Timeline)
            AssetHandoverTimelineCard(assignments: asset.assignments),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context, AssetDetailState state) {
    if (state.asset == null) return null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    // Kasus 1: User adalah penerima penugasan PENDING_ACCEPTANCE (Approve / Reject)
    if (state.isPendingRecipient) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderCol)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Tolak',
                  leadingIcon: LucideIcons.x,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _handleReject(context, state),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Terima Aset',
                  leadingIcon: LucideIcons.check,
                  isLoading:
                      state.actionStatus == AssetDetailActionStatus.loading,
                  onPressed: () => _handleAccept(context, state),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Kasus 2: User adalah pemegang aktif saat ini (Oper Fasilitas / Direct Transfer)
    if (state.isCurrentHolder &&
        state.asset!.status == 'ASSIGNED' &&
        state.asset!.pendingAssignment == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderCol)),
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            text: 'Oper Fasilitas ke Rekan Kerja',
            leadingIcon: LucideIcons.arrowRightLeft,
            onPressed: () => _openDirectTransfer(context, state),
          ),
        ),
      );
    }

    // Kasus 3: Unit tersedia di gudang dan user punya hak serah terima (Pool Handover)
    if (state.isAvailableInWarehouse && state.canHandover) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderCol)),
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            text: 'Serah Terima ke Karyawan',
            leadingIcon: LucideIcons.userPlus,
            onPressed: () => _openPoolHandover(context, state),
          ),
        ),
      );
    }

    return null;
  }
}
