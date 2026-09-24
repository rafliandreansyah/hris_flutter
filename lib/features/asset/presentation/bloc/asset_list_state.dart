import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_filter_criteria.dart';
import 'package:hris_flutter/features/asset/data/models/asset_list_model.dart';

enum AssetListStatus { initial, loading, success, failure }

enum AssetActionStatus { idle, loading, success, failure }

class AssetListState extends Equatable {
  final AssetListStatus status;
  final AssetActionStatus actionStatus;
  final String? actionMessage;
  final List<AssetListItem> assets;
  final List<AssetCategoryModel> categories;
  final bool categoriesLoading;
  final AssetFilterCriteria filter;
  final String searchQuery;
  final int page;
  final bool hasReachedMax;
  final int total;
  final bool isLoadingMore;
  final String? errorMessage;

  const AssetListState({
    this.status = AssetListStatus.initial,
    this.actionStatus = AssetActionStatus.idle,
    this.actionMessage,
    this.assets = const [],
    this.categories = const [],
    this.categoriesLoading = false,
    this.filter = const AssetFilterCriteria(),
    this.searchQuery = '',
    this.page = 1,
    this.hasReachedMax = false,
    this.total = 0,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  /// Jumlah fasilitas yang memerlukan tindakan persetujuan (status PENDING_ACCEPTANCE)
  int get pendingActionCount =>
      assets.where((item) => item.isPendingAcceptance).length;

  /// Daftar aset yang telah diurutkan sesuai kriteria filter.sortBy
  List<AssetListItem> get sortedAssets {
    final list = List<AssetListItem>.from(assets);
    switch (filter.sortBy) {
      case 'oldest':
        list.sort((a, b) {
          if (a.assignedDate == null && b.assignedDate == null) return 0;
          if (a.assignedDate == null) return 1;
          if (b.assignedDate == null) return -1;
          return a.assignedDate!.compareTo(b.assignedDate!);
        });
        break;
      case 'name_asc':
        list.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        list.sort((a, b) =>
            b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'newest':
      default:
        // Prioritaskan PENDING_ACCEPTANCE di atas sesuai Stitch Screen 2, lalu urut tanggal terbaru
        list.sort((a, b) {
          if (a.isPendingAcceptance && !b.isPendingAcceptance) return -1;
          if (!a.isPendingAcceptance && b.isPendingAcceptance) return 1;
          if (a.assignedDate == null && b.assignedDate == null) return 0;
          if (a.assignedDate == null) return 1;
          if (b.assignedDate == null) return -1;
          return b.assignedDate!.compareTo(a.assignedDate!);
        });
        break;
    }
    return list;
  }

  AssetListState copyWith({
    AssetListStatus? status,
    AssetActionStatus? actionStatus,
    String? actionMessage,
    bool clearActionMessage = false,
    List<AssetListItem>? assets,
    List<AssetCategoryModel>? categories,
    bool? categoriesLoading,
    AssetFilterCriteria? filter,
    String? searchQuery,
    int? page,
    bool? hasReachedMax,
    int? total,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssetListState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
      assets: assets ?? this.assets,
      categories: categories ?? this.categories,
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        actionMessage,
        assets,
        categories,
        categoriesLoading,
        filter,
        searchQuery,
        page,
        hasReachedMax,
        total,
        isLoadingMore,
        errorMessage,
      ];
}
