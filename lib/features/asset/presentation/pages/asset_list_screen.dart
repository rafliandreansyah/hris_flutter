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
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_bloc.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_state.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_card.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_reject_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Fasilitas Saya (Unified Asset List).
/// Sesuai Stitch Screen: "Oasish Fasilitas Saya (Unified Asset List)"
/// (ID: fa2fa6bde7d648aabb74209dbd5dde63).
class AssetListScreen extends StatelessWidget {
  final AssetRepository? repository;

  const AssetListScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssetListBloc>(
      create: (context) =>
          AssetListBloc(repository: repository)..add(const AssetListStarted()),
      child: const _AssetListScreenView(),
    );
  }
}

class _AssetListScreenView extends StatefulWidget {
  const _AssetListScreenView();

  @override
  State<_AssetListScreenView> createState() => _AssetListScreenViewState();
}

class _AssetListScreenViewState extends State<_AssetListScreenView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AssetListBloc>().add(const AssetListLoadMore());
    }
  }

  Future<void> _handleAccept(AssetListItem item) async {
    final assignmentId = item.assignmentId ?? item.id;
    final confirmed = await AppDialogUtil.showConfirmation(
      context,
      title: 'Terima Penyerahan Fasilitas',
      message:
          'Apakah Anda yakin ingin menerima fasilitas "${item.name}"? Fasilitas ini akan menjadi tanggung jawab fisik Anda.',
      confirmText: 'Terima Aset',
      confirmIcon: LucideIcons.check,
      confirmButtonColor: const Color(0xFF0D9488),
    );

    if (confirmed && mounted) {
      context
          .read<AssetListBloc>()
          .add(AssetAssignmentApproved(assignmentId));
    }
  }

  Future<void> _handleReject(AssetListItem item) async {
    final assignmentId = item.assignmentId ?? item.id;
    await AssetRejectBottomSheet.show(
      context,
      asset: item,
      onReject: (reason) async {
        context.read<AssetListBloc>().add(
              AssetAssignmentRejected(
                assignmentId: assignmentId,
                reason: reason,
              ),
            );
      },
    );
  }

  void _openFilter(AssetListState state) {
    AssetFilterBottomSheet.show(
      context,
      initialCriteria: state.filter,
      categories: state.categories,
      onApply: (criteria) {
        context.read<AssetListBloc>().add(AssetListFilterApplied(criteria));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return BlocConsumer<AssetListBloc, AssetListState>(
      listener: (context, state) {
        if (state.actionStatus == AssetActionStatus.success &&
            state.actionMessage != null) {
          AppDialogUtil.showSuccess(
            context,
            message: state.actionMessage!,
          );
        } else if (state.actionStatus == AssetActionStatus.failure &&
            state.actionMessage != null) {
          AppDialogUtil.showError(
            context,
            message: state.actionMessage!,
          );
        }
      },
      builder: (context, state) {
        final sortedAssets = state.sortedAssets;
        final hasActiveFilter = state.filter.hasActiveFilter;

        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: surfaceCol,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowLeft,
                color: textCol,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fasilitas Saya',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Inventaris & Serah Terima Aset',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.slidersHorizontal,
                      color: hasActiveFilter ? primaryCol : textCol,
                      size: 20,
                    ),
                    onPressed: () => _openFilter(state),
                  ),
                  if (hasActiveFilter)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: surfaceCol, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: borderCol,
                height: 1,
              ),
            ),
          ),
          body: Column(
            children: [
              // 1. Search Bar & Active Filter Chips
              Container(
                color: surfaceCol,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackgroundSubtle
                            : AppColors.backgroundSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          context
                              .read<AssetListBloc>()
                              .add(AssetListSearchChanged(val));
                        },
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: AppTypography.bodyMedium.copyWith(color: textCol),
                        decoration: InputDecoration(
                          hintText: 'Cari nama aset, kode, atau kategori...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: subtitleCol.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 18,
                            color: primaryCol,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    LucideIcons.circleX,
                                    size: 16,
                                  ),
                                  color: subtitleCol,
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<AssetListBloc>()
                                        .add(const AssetListSearchChanged(''));
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    // Active Filter Chip Row (Horizontal Scroll)
                    if (state.filter.status != 'all' ||
                        state.filter.categoryId != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (state.filter.status != 'all')
                              _buildActiveFilterChip(
                                label:
                                    'Status: ${_getStatusDisplay(state.filter.status)}',
                                onRemove: () {
                                  context.read<AssetListBloc>().add(
                                        AssetListFilterApplied(
                                          state.filter.copyWith(status: 'all'),
                                        ),
                                      );
                                },
                              ),
                            if (state.filter.categoryId != null) ...[
                              const SizedBox(width: 6),
                              _buildActiveFilterChip(
                                label:
                                    'Kategori: ${state.filter.categoryName ?? "Kategori"}',
                                onRemove: () {
                                  context.read<AssetListBloc>().add(
                                        AssetListFilterApplied(
                                          state.filter.copyWith(
                                            clearCategory: true,
                                          ),
                                        ),
                                      );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Summary & Result Count Row
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm + 2,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.pendingActionCount > 0)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${state.pendingActionCount} perlu tindakan persetujuan',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Text(
                      'Menampilkan ${sortedAssets.length} fasilitas',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Asset Cards List View
              Expanded(
                child: RefreshIndicator(
                  color: primaryCol,
                  onRefresh: () async {
                    context
                        .read<AssetListBloc>()
                        .add(const AssetListRefreshed());
                  },
                  child: _buildListContent(
                    context,
                    state: state,
                    sortedAssets: sortedAssets,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryCol.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: primaryCol,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: Icon(
              LucideIcons.x,
              size: 13,
              color: primaryCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context, {
    required AssetListState state,
    required List<AssetListItem> sortedAssets,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    // Loading Shimmer State
    if (state.status == AssetListStatus.loading && state.assets.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const RequestCardShimmerLoading(),
      );
    }

    // Failure / Error State
    if (state.status == AssetListStatus.failure && state.assets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Container(
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
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Gagal Memuat Fasilitas',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.errorMessage ?? 'Terjadi kesalahan pada server',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: AppButton(
              text: 'Coba Lagi',
              leadingIcon: LucideIcons.rotateCcw,
              onPressed: () {
                context.read<AssetListBloc>().add(const AssetListStarted());
              },
              width: 140,
              height: 42,
            ),
          ),
        ],
      );
    }

    // Empty State
    if (sortedAssets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.packageOpen,
                size: 32,
                color: AppColors.brandTeal,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tidak Ada Fasilitas',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.filter.hasActiveFilter
                ? 'Tidak ada aset yang cocok dengan filter atau kata kunci pencarian.'
                : 'Belum ada fasilitas kerja yang ditugaskan kepada Anda.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
            ),
          ),
          if (state.filter.hasActiveFilter) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context
                      .read<AssetListBloc>()
                      .add(const AssetListFilterReset());
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
                label: const Text('Reset Filter'),
              ),
            ),
          ],
        ],
      );
    }

    // List of Asset Cards
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: sortedAssets.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index >= sortedAssets.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        final item = sortedAssets[index];
        return AssetCard(
          asset: item,
          onAccept: () => _handleAccept(item),
          onReject: () => _handleReject(item),
        );
      },
    );
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'PENDING_ACCEPTANCE':
        return 'Menunggu Konfirmasi';
      case 'ACTIVE':
        return 'Aktif';
      case 'RETURNED':
        return 'Dikembalikan';
      case 'REJECTED':
        return 'Ditolak';
      case 'AVAILABLE':
        return 'Tersedia';
      default:
        return status;
    }
  }
}
