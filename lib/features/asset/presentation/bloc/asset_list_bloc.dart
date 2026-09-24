import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/features/asset/data/models/asset_category_model.dart';
import 'package:hris_flutter/features/asset/data/models/asset_filter_criteria.dart';
import 'package:hris_flutter/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:hris_flutter/features/asset/domain/repositories/asset_repository.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_event.dart';
import 'package:hris_flutter/features/asset/presentation/bloc/asset_list_state.dart';

class AssetListBloc extends Bloc<AssetListEvent, AssetListState> {
  final AssetRepository _repository;

  static const int defaultPageSize = 10;

  AssetListBloc({AssetRepository? repository})
      : _repository = repository ?? AssetRepositoryImpl(),
        super(const AssetListState()) {
    on<AssetListStarted>(_onStarted);
    on<AssetListRefreshed>(_onRefreshed);
    on<AssetListLoadMore>(_onLoadMore);
    on<AssetListSearchChanged>(
      _onSearchChanged,
      transformer: debounceRestartable(),
    );
    on<AssetListFilterApplied>(_onFilterApplied);
    on<AssetListFilterReset>(_onFilterReset);
    on<AssetListCategorySelected>(_onCategorySelected);
    on<AssetAssignmentApproved>(_onAssignmentApproved);
    on<AssetAssignmentRejected>(_onAssignmentRejected);
  }

  Future<void> _onStarted(
    AssetListStarted event,
    Emitter<AssetListState> emit,
  ) async {
    emit(state.copyWith(
      status: AssetListStatus.loading,
      categoriesLoading: true,
      clearError: true,
    ));

    // 1. Muat Kategori Aset (Background)
    List<AssetCategoryModel> categories = state.categories;
    try {
      categories = await _repository.getAssetCategories();
    } catch (_) {
      // Abaikan kegagalan kategori agar tidak memblokir list aset utama
    }

    // 2. Muat Daftar Fasilitas Aset
    try {
      final response = await _repository.getAssets(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
        categoryId: state.filter.categoryId,
        status: state.filter.status,
      );

      final total = response.meta?.total ?? response.data.length;
      final limit = response.meta?.limit ?? defaultPageSize;
      final hasReachedMax = response.data.length < limit ||
          response.data.length >= total;

      emit(state.copyWith(
        status: AssetListStatus.success,
        assets: response.data,
        categories: categories,
        categoriesLoading: false,
        page: 1,
        total: total,
        hasReachedMax: hasReachedMax,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        categories: categories,
        categoriesLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        categories: categories,
        categoriesLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshed(
    AssetListRefreshed event,
    Emitter<AssetListState> emit,
  ) async {
    try {
      final response = await _repository.getAssets(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
        categoryId: state.filter.categoryId,
        status: state.filter.status,
      );

      final total = response.meta?.total ?? response.data.length;
      final limit = response.meta?.limit ?? defaultPageSize;
      final hasReachedMax = response.data.length < limit ||
          response.data.length >= total;

      emit(state.copyWith(
        status: AssetListStatus.success,
        assets: response.data,
        page: 1,
        total: total,
        hasReachedMax: hasReachedMax,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMore(
    AssetListLoadMore event,
    Emitter<AssetListState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.page + 1;

    try {
      final response = await _repository.getAssets(
        page: nextPage,
        size: defaultPageSize,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
        categoryId: state.filter.categoryId,
        status: state.filter.status,
      );

      final newItems = response.data;
      final combined = [...state.assets, ...newItems];
      final total = response.meta?.total ?? combined.length;
      final limit = response.meta?.limit ?? defaultPageSize;
      final hasReachedMax = newItems.length < limit || combined.length >= total;

      emit(state.copyWith(
        assets: combined,
        page: nextPage,
        total: total,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSearchChanged(
    AssetListSearchChanged event,
    Emitter<AssetListState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: event.query,
      status: AssetListStatus.loading,
      page: 1,
      clearError: true,
    ));

    try {
      final response = await _repository.getAssets(
        page: 1,
        size: defaultPageSize,
        search: event.query.trim().isNotEmpty ? event.query.trim() : null,
        categoryId: state.filter.categoryId,
        status: state.filter.status,
      );

      final total = response.meta?.total ?? response.data.length;
      final limit = response.meta?.limit ?? defaultPageSize;
      final hasReachedMax = response.data.length < limit ||
          response.data.length >= total;

      emit(state.copyWith(
        status: AssetListStatus.success,
        assets: response.data,
        page: 1,
        total: total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFilterApplied(
    AssetListFilterApplied event,
    Emitter<AssetListState> emit,
  ) async {
    emit(state.copyWith(
      filter: event.criteria,
      status: AssetListStatus.loading,
      page: 1,
      clearError: true,
    ));

    try {
      final response = await _repository.getAssets(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
        categoryId: event.criteria.categoryId,
        status: event.criteria.status,
      );

      final total = response.meta?.total ?? response.data.length;
      final limit = response.meta?.limit ?? defaultPageSize;
      final hasReachedMax = response.data.length < limit ||
          response.data.length >= total;

      emit(state.copyWith(
        status: AssetListStatus.success,
        assets: response.data,
        page: 1,
        total: total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFilterReset(
    AssetListFilterReset event,
    Emitter<AssetListState> emit,
  ) async {
    final defaultFilter = AssetFilterCriteria.initial();
    emit(state.copyWith(
      filter: defaultFilter,
      status: AssetListStatus.loading,
      page: 1,
      clearError: true,
    ));

    try {
      final response = await _repository.getAssets(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
        categoryId: null,
        status: defaultFilter.status,
      );

      final total = response.meta?.total ?? response.data.length;
      final limit = response.meta?.limit ?? defaultPageSize;
      final hasReachedMax = response.data.length < limit ||
          response.data.length >= total;

      emit(state.copyWith(
        status: AssetListStatus.success,
        assets: response.data,
        page: 1,
        total: total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCategorySelected(
    AssetListCategorySelected event,
    Emitter<AssetListState> emit,
  ) async {
    final isAlreadySelected = state.filter.categoryId == event.categoryId;
    final updatedFilter = isAlreadySelected
        ? state.filter.copyWith(clearCategory: true)
        : state.filter.copyWith(
            categoryId: event.categoryId,
            categoryName: event.categoryName,
          );

    emit(state.copyWith(
      filter: updatedFilter,
      status: AssetListStatus.loading,
      page: 1,
      clearError: true,
    ));

    try {
      final response = await _repository.getAssets(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery.trim().isNotEmpty
            ? state.searchQuery.trim()
            : null,
        categoryId: updatedFilter.categoryId,
        status: updatedFilter.status,
      );

      final total = response.meta?.total ?? response.data.length;
      final limit = response.meta?.limit ?? defaultPageSize;
      final hasReachedMax = response.data.length < limit ||
          response.data.length >= total;

      emit(state.copyWith(
        status: AssetListStatus.success,
        assets: response.data,
        page: 1,
        total: total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssetListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAssignmentApproved(
    AssetAssignmentApproved event,
    Emitter<AssetListState> emit,
  ) async {
    emit(state.copyWith(
      actionStatus: AssetActionStatus.loading,
      clearActionMessage: true,
    ));

    try {
      await _repository.approveAssignment(
        assignmentId: event.assignmentId,
      );

      emit(state.copyWith(
        actionStatus: AssetActionStatus.success,
        actionMessage:
            'Fasilitas berhasil diterima dan menjadi tanggung jawab Anda.',
      ));

      add(const AssetListRefreshed());
    } on ApiException catch (e) {
      emit(state.copyWith(
        actionStatus: AssetActionStatus.failure,
        actionMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AssetActionStatus.failure,
        actionMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAssignmentRejected(
    AssetAssignmentRejected event,
    Emitter<AssetListState> emit,
  ) async {
    emit(state.copyWith(
      actionStatus: AssetActionStatus.loading,
      clearActionMessage: true,
    ));

    try {
      await _repository.rejectAssignment(
        assignmentId: event.assignmentId,
        rejectionReason: event.reason,
      );

      emit(state.copyWith(
        actionStatus: AssetActionStatus.success,
        actionMessage: 'Penyerahan fasilitas telah ditolak.',
      ));

      add(const AssetListRefreshed());
    } on ApiException catch (e) {
      emit(state.copyWith(
        actionStatus: AssetActionStatus.failure,
        actionMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: AssetActionStatus.failure,
        actionMessage: e.toString(),
      ));
    }
  }
}
