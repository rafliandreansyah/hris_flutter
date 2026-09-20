import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:hris_flutter/features/announcement/data/repositories/announcement_repository_impl.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_event.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_state.dart';

class AnnouncementListBloc
    extends Bloc<AnnouncementListEvent, AnnouncementListState> {
  final AnnouncementRepository _repository;
  static const int defaultPageSize = 10;

  AnnouncementListBloc({
    AnnouncementRepository? repository,
  })  : _repository = repository ?? AnnouncementRepositoryImpl(),
        super(const AnnouncementListState()) {
    on<AnnouncementListStarted>(_onStarted);
    on<AnnouncementListRefreshed>(_onRefreshed);
    on<AnnouncementListLoadMore>(_onLoadMore);
    on<AnnouncementSearchChanged>(_onSearchChanged, transformer: debounceRestartable());
    on<AnnouncementFilterApplied>(_onFilterApplied);
    on<AnnouncementFilterReset>(_onFilterReset);
  }

  Future<void> _onStarted(
    AnnouncementListStarted event,
    Emitter<AnnouncementListState> emit,
  ) async {
    emit(state.copyWith(
      status: AnnouncementStatus.loading,
      errorMessage: null,
    ));

    try {
      final response = await _repository.getAnnouncements(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery,
        category: state.selectedCategory,
        priority: state.selectedPriority,
      );

      final hasReachedMax = response.meta.page >= response.meta.totalPages ||
          response.data.length >= response.meta.total;

      emit(state.copyWith(
        status: AnnouncementStatus.success,
        announcements: response.data,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: 'Gagal memuat pengumuman: $e',
      ));
    }
  }

  Future<void> _onRefreshed(
    AnnouncementListRefreshed event,
    Emitter<AnnouncementListState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      final response = await _repository.getAnnouncements(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery,
        category: state.selectedCategory,
        priority: state.selectedPriority,
      );

      final hasReachedMax = response.meta.page >= response.meta.totalPages ||
          response.data.length >= response.meta.total;

      emit(state.copyWith(
        status: AnnouncementStatus.success,
        announcements: response.data,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
        isRefreshing: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: 'Gagal menyegarkan pengumuman: $e',
      ));
    }
  }

  Future<void> _onLoadMore(
    AnnouncementListLoadMore event,
    Emitter<AnnouncementListState> emit,
  ) async {
    if (state.isLoadingMore ||
        state.hasReachedMax ||
        state.status != AnnouncementStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.page + 1;
      final response = await _repository.getAnnouncements(
        page: nextPage,
        size: defaultPageSize,
        search: state.searchQuery,
        category: state.selectedCategory,
        priority: state.selectedPriority,
      );

      final existingIds = state.announcements.map((a) => a.id).toSet();
      final newItems =
          response.data.where((a) => !existingIds.contains(a.id)).toList();
      final updatedList = List<AnnouncementItem>.from(state.announcements)
        ..addAll(newItems);

      final hasReachedMax = response.meta.page >= response.meta.totalPages ||
          updatedList.length >= response.meta.total;

      emit(state.copyWith(
        announcements: updatedList,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
      ));
    } on ApiException catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onSearchChanged(
    AnnouncementSearchChanged event,
    Emitter<AnnouncementListState> emit,
  ) async {
    final cleanQuery = event.query.trim().isEmpty ? null : event.query.trim();
    if (cleanQuery == state.searchQuery) return;

    emit(state.copyWith(
      searchQuery: cleanQuery,
      status: AnnouncementStatus.loading,
    ));

    try {
      final response = await _repository.getAnnouncements(
        page: 1,
        size: defaultPageSize,
        search: cleanQuery,
        category: state.selectedCategory,
        priority: state.selectedPriority,
      );

      final hasReachedMax = response.meta.page >= response.meta.totalPages ||
          response.data.length >= response.meta.total;

      emit(state.copyWith(
        status: AnnouncementStatus.success,
        announcements: response.data,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: 'Gagal mencari pengumuman: $e',
      ));
    }
  }

  Future<void> _onFilterApplied(
    AnnouncementFilterApplied event,
    Emitter<AnnouncementListState> emit,
  ) async {
    final cleanCat =
        (event.category == null || event.category!.trim().isEmpty || event.category!.toLowerCase() == 'all')
            ? null
            : event.category!.trim();
    final cleanPri =
        (event.priority == null || event.priority!.trim().isEmpty || event.priority!.toLowerCase() == 'all')
            ? null
            : event.priority!.trim();

    emit(state.copyWith(
      selectedCategory: cleanCat,
      clearCategory: cleanCat == null,
      selectedPriority: cleanPri,
      clearPriority: cleanPri == null,
      status: AnnouncementStatus.loading,
    ));

    try {
      final response = await _repository.getAnnouncements(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery,
        category: cleanCat,
        priority: cleanPri,
      );

      final hasReachedMax = response.meta.page >= response.meta.totalPages ||
          response.data.length >= response.meta.total;

      emit(state.copyWith(
        status: AnnouncementStatus.success,
        announcements: response.data,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: 'Gagal memfilter pengumuman: $e',
      ));
    }
  }

  Future<void> _onFilterReset(
    AnnouncementFilterReset event,
    Emitter<AnnouncementListState> emit,
  ) async {
    emit(state.copyWith(
      clearCategory: true,
      clearPriority: true,
      status: AnnouncementStatus.loading,
    ));

    try {
      final response = await _repository.getAnnouncements(
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery,
        category: null,
        priority: null,
      );

      final hasReachedMax = response.meta.page >= response.meta.totalPages ||
          response.data.length >= response.meta.total;

      emit(state.copyWith(
        status: AnnouncementStatus.success,
        announcements: response.data,
        page: response.meta.page,
        totalPages: response.meta.totalPages,
        total: response.meta.total,
        hasReachedMax: hasReachedMax,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AnnouncementStatus.failure,
        errorMessage: 'Gagal mereset filter: $e',
      ));
    }
  }
}
