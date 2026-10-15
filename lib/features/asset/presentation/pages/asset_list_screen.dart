import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_bloc.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_state.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_card.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_reject_bottom_sheet.dart';
import 'package:hris_flutter/features/asset/presentation/widgets/asset_warehouse_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Fasilitas Saya & Gudang Fasilitas (Unified Asset Directory).
/// Mendukung Pill-Style TabBar saat pengguna memiliki wewenang akses gudang
/// (asset.view / asset.handover / asset.create / admin_system).
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
      confirmButtonColor: const AppColors.brandTeal,
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

  Future<void> _openDetail(String assetId) async {
    await context.push(Routes.ASSET_DETAIL, extra: assetId);
    if (mounted) {
      context.read<AssetListBloc>().add(const AssetListRefreshed());
    }
  }

  Future<void> _openCreateAsset() async {
    final created = await context.push<bool>(Routes.CREATE_ASSET);
    if (created == true && mounted) {
      context.read<AssetListBloc>().add(const AssetListRefreshed());
    }
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.currentTab == AssetListTab.warehouse
                      ? 'Gudang Fasilitas'
                      : 'Asset Saya',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 18,
                  ),
                ),
                Text(
                  state.currentTab == AssetListTab.warehouse
                      ? 'Inventaris Siap Pakai & Serah Terima'
                      : 'Inventaris & Serah Terima Aset',
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
          ),
          floatingActionButton: state.canCreateAsset
              ? FloatingActionButton.extended(
                  onPressed: _openCreateAsset,
                  backgroundColor: const AppColors.brandTeal,
                  foregroundColor: Colors.white,
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: Text(
                    'Daftarkan Aset',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          body: Column(
            children: [
              // 1. Pill-Style TabBar (Hanya ditampilkan jika pengguna memiliki akses gudang)
              if (state.hasWarehouseAccess) ...[
                const SizedBox(height: 8),
                _buildPillTabBar(context, state: state, isDark: isDark),
              ],

              const SizedBox(height: 8),
              AppSearchBar(
                controller: _searchController,
                hintText: state.currentTab == AssetListTab.warehouse
                    ? 'Cari aset di gudang (nama, kode, serial)...'
                    : 'Cari nama aset, kode, atau kategori...',
                onChanged: (val) {
                  context
                      .read<AssetListBloc>()
                      .add(AssetListSearchChanged(val));
                },
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),

              // 2. Active Filter Chip Row (Horizontal Scroll)
              if (state.filter.status != 'all' ||
                  state.filter.categoryId != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
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
                ),
              ],

              // 3. Summary & Result Count Row
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.currentTab == AssetListTab.myAssets &&
                        state.pendingActionCount > 0)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
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
                    else if (state.currentTab == AssetListTab.warehouse)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pool Fasilitas Siap Pakai',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF15803D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Text(
                      'Menampilkan ${sortedAssets.length} unit',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Asset Cards List View
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

  /// Unified Pill-Style TabBar sesuai standar AGENTS.md Rule 16
  Widget _buildPillTabBar(
    BuildContext context, {
    required AssetListState state,
    required bool isDark,
  }) {
    final activeTab = state.currentTab;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              context,
              label: 'Fasilitas Saya',
              icon: LucideIcons.laptop,
              isSelected: activeTab == AssetListTab.myAssets,
              isDark: isDark,
              onTap: () {
                context
                    .read<AssetListBloc>()
                    .add(const AssetListTabChanged(AssetListTab.myAssets));
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              context,
              label: 'Gudang Fasilitas',
              icon: LucideIcons.warehouse,
              isSelected: activeTab == AssetListTab.warehouse,
              isDark: isDark,
              onTap: () {
                context
                    .read<AssetListBloc>()
                    .add(const AssetListTabChanged(AssetListTab.warehouse));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final activeColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final inactiveColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.06,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
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
            state.currentTab == AssetListTab.warehouse
                ? 'Gagal Memuat Gudang Fasilitas'
                : 'Gagal Memuat Fasilitas',
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
      final isFiltered =
          state.filter.hasActiveFilter || _searchController.text.trim().isNotEmpty;
      final isWarehouse = state.currentTab == AssetListTab.warehouse;

      return AppEmptyState(
        icon: isWarehouse ? LucideIcons.warehouse : LucideIcons.packageOpen,
        title: isFiltered
            ? 'Tidak Ada Unit Ditemukan'
            : (isWarehouse ? 'Gudang Fasilitas Kosong' : 'Tidak Ada Fasilitas'),
        message: isFiltered
            ? 'Tidak ada unit yang cocok dengan filter atau kata kunci pencarian.'
            : (isWarehouse
                ? 'Saat ini seluruh fasilitas inventaris sedang digunakan oleh karyawan.'
                : 'Belum ada fasilitas kerja yang ditugaskan kepada Anda.'),
        onResetFilter: isFiltered
            ? () {
                _searchController.clear();
                context
                    .read<AssetListBloc>()
                    .add(const AssetListFilterReset());
              }
            : null,
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

        // Mode Gudang: Render AssetWarehouseCard
        if (state.currentTab == AssetListTab.warehouse) {
          return AssetWarehouseCard(
            asset: item,
            canHandover: state.canHandoverAsset,
            onHandover: () => _openDetail(item.id),
            onTap: () => _openDetail(item.id),
          );
        }

        // Mode Fasilitas Saya: Render AssetCard
        return AssetCard(
          asset: item,
          onAccept: () => _handleAccept(item),
          onReject: () => _handleReject(item),
          onTap: () => _openDetail(item.id),
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
