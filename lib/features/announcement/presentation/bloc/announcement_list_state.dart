import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';

enum AnnouncementStatus { initial, loading, success, failure }

class AnnouncementListState extends Equatable {
  final AnnouncementStatus status;
  final List<AnnouncementItem> announcements;
  final int page;
  final int totalPages;
  final int total;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? searchQuery;
  final String? selectedCategory;
  final String? selectedPriority;
  final String? errorMessage;
  final int? statusCode;

  const AnnouncementListState({
    this.status = AnnouncementStatus.initial,
    this.announcements = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.searchQuery,
    this.selectedCategory,
    this.selectedPriority,
    this.errorMessage,
    this.statusCode,
  });

  bool get hasActiveFilter {
    return (selectedCategory != null &&
            selectedCategory!.isNotEmpty &&
            selectedCategory!.toLowerCase() != 'all') ||
        (selectedPriority != null &&
            selectedPriority!.isNotEmpty &&
            selectedPriority!.toLowerCase() != 'all');
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedCategory != null &&
        selectedCategory!.isNotEmpty &&
        selectedCategory!.toLowerCase() != 'all') {
      count++;
    }
    if (selectedPriority != null &&
        selectedPriority!.isNotEmpty &&
        selectedPriority!.toLowerCase() != 'all') {
      count++;
    }
    return count;
  }

  AnnouncementListState copyWith({
    AnnouncementStatus? status,
    List<AnnouncementItem>? announcements,
    int? page,
    int? totalPages,
    int? total,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    String? selectedPriority,
    bool clearPriority = false,
    String? errorMessage,
    int? statusCode,
  }) {
    return AnnouncementListState(
      status: status ?? this.status,
      announcements: announcements ?? this.announcements,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedPriority:
          clearPriority ? null : (selectedPriority ?? this.selectedPriority),
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        announcements,
        page,
        totalPages,
        total,
        hasReachedMax,
        isLoadingMore,
        isRefreshing,
        searchQuery,
        selectedCategory,
        selectedPriority,
        errorMessage,
        statusCode,
      ];
}
