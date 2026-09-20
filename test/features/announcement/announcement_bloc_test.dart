import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_bloc.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_event.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_list_state.dart';

class _FakeAnnouncementRepository implements AnnouncementRepository {
  List<AnnouncementItem> items;
  bool shouldThrow;
  String? lastSearch;
  String? lastCategory;
  String? lastPriority;

  _FakeAnnouncementRepository({
    List<AnnouncementItem>? items,
    this.shouldThrow = false,
  }) : items = items ?? [
          const AnnouncementItem(
            id: 'ann-1',
            title: 'Pinned Policy Announcement',
            content: 'Konten penting',
            isPinned: true,
            priority: 'urgent',
            category: 'hr_policy',
          ),
          const AnnouncementItem(
            id: 'ann-2',
            title: 'General Office Announcement',
            content: 'Konten umum',
            isPinned: false,
            priority: 'low',
            category: 'general',
          ),
        ];

  @override
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  }) async {
    lastSearch = search;
    lastCategory = category;
    lastPriority = priority;

    if (shouldThrow) {
      throw const ApiException(message: 'Gagal memuat pengumuman dari server');
    }

    if (page == 1) {
      return AnnouncementListResponse(
        success: true,
        message: 'OK',
        data: items,
        meta: AnnouncementPaginationMeta(
          page: 1,
          limit: size,
          total: items.length + 1,
          totalPages: 2,
        ),
      );
    } else {
      return AnnouncementListResponse(
        success: true,
        message: 'OK',
        data: const [
          AnnouncementItem(
            id: 'ann-3',
            title: 'Page 2 Announcement',
            content: 'Konten halaman 2',
            isPinned: false,
          ),
        ],
        meta: AnnouncementPaginationMeta(
          page: 2,
          limit: size,
          total: items.length + 1,
          totalPages: 2,
        ),
      );
    }
  }

  @override
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id) async {
    return const AnnouncementDetailResponse(
      success: true,
      message: 'OK',
      data: AnnouncementDetailModel(
        id: '1',
        title: 'Title',
        content: 'Content',
      ),
    );
  }

  @override
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(
    String id,
  ) async {
    return const AnnouncementAcknowledgeResponse(
      success: true,
      message: 'OK',
      data: AnnouncementAcknowledgeData(),
    );
  }
}

void main() {
  group('AnnouncementListBloc Tests', () {
    test('emits [loading, success] on AnnouncementListStarted success', () async {
      final repo = _FakeAnnouncementRepository();
      final bloc = AnnouncementListBloc(repository: repo);
      final states = <AnnouncementListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementListStarted());
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, AnnouncementStatus.loading);
      expect(states[1].status, AnnouncementStatus.success);
      expect(states[1].announcements.length, 2);
      expect(states[1].page, 1);
      expect(states[1].hasReachedMax, false);

      await bloc.close();
    });

    test('emits [loading, failure] on AnnouncementListStarted failure', () async {
      final repo = _FakeAnnouncementRepository(shouldThrow: true);
      final bloc = AnnouncementListBloc(repository: repo);
      final states = <AnnouncementListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementListStarted());
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, AnnouncementStatus.loading);
      expect(states[1].status, AnnouncementStatus.failure);
      expect(states[1].errorMessage, contains('Gagal memuat pengumuman'));

      await bloc.close();
    });

    test('refreshes announcements on AnnouncementListRefreshed', () async {
      final repo = _FakeAnnouncementRepository();
      final bloc = AnnouncementListBloc(repository: repo);
      bloc.add(const AnnouncementListStarted());
      await pumpEventQueue();

      final states = <AnnouncementListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementListRefreshed());
      await pumpEventQueue();

      expect(states.any((s) => s.isRefreshing), isTrue);
      expect(states.last.isRefreshing, isFalse);
      expect(states.last.status, AnnouncementStatus.success);

      await bloc.close();
    });

    test('loads more announcements on AnnouncementListLoadMore', () async {
      final repo = _FakeAnnouncementRepository();
      final bloc = AnnouncementListBloc(repository: repo);
      bloc.add(const AnnouncementListStarted());
      await pumpEventQueue();

      final states = <AnnouncementListState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementListLoadMore());
      await pumpEventQueue();

      expect(states.last.announcements.length, 3);
      expect(states.last.page, 2);
      expect(states.last.hasReachedMax, isTrue);

      await bloc.close();
    });

    test('applies filter on AnnouncementFilterApplied and resets on AnnouncementFilterReset', () async {
      final repo = _FakeAnnouncementRepository();
      final bloc = AnnouncementListBloc(repository: repo);
      bloc.add(const AnnouncementListStarted());
      await pumpEventQueue();

      bloc.add(const AnnouncementFilterApplied(category: 'hr_policy', priority: 'urgent'));
      await pumpEventQueue();

      expect(bloc.state.selectedCategory, 'hr_policy');
      expect(bloc.state.selectedPriority, 'urgent');
      expect(bloc.state.hasActiveFilter, isTrue);
      expect(bloc.state.activeFilterCount, 2);
      expect(repo.lastCategory, 'hr_policy');
      expect(repo.lastPriority, 'urgent');

      bloc.add(const AnnouncementFilterReset());
      await pumpEventQueue();

      expect(bloc.state.selectedCategory, isNull);
      expect(bloc.state.selectedPriority, isNull);
      expect(bloc.state.hasActiveFilter, isFalse);
      expect(repo.lastCategory, isNull);
      expect(repo.lastPriority, isNull);

      await bloc.close();
    });

    test('searches announcements on AnnouncementSearchChanged', () async {
      final repo = _FakeAnnouncementRepository();
      final bloc = AnnouncementListBloc(repository: repo);
      bloc.add(const AnnouncementListStarted());
      await pumpEventQueue();

      bloc.add(const AnnouncementSearchChanged('libur nasional'));
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(bloc.state.searchQuery, 'libur nasional');
      expect(repo.lastSearch, 'libur nasional');

      await bloc.close();
    });
  });
}
