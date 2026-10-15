import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/announcement_list_screen.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeAnnouncementRepository implements AnnouncementRepository {
  final bool shouldFail;
  final List<AnnouncementItem> items;

  _FakeAnnouncementRepository({
    this.shouldFail = false,
    this.items = const [],
  });

  @override
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        message: 'Gagal memuat pengumuman',
        statusCode: 500,
      );
    }

    var result = items;
    if (search != null && search.isNotEmpty) {
      result = result
          .where((item) =>
              item.title.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    if (category != null && category.isNotEmpty) {
      result = result.where((item) => item.category == category).toList();
    }

    return AnnouncementListResponse(
      success: true,
      message: 'OK',
      data: result,
      meta: AnnouncementPaginationMeta(
        page: page,
        totalPages: 1,
        total: result.length,
        limit: size,
      ),
    );
  }

  @override
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(String id) async {
    throw UnimplementedError();
  }
}

void main() {
  Widget buildTestableWidget({
    required AnnouncementRepository repository,
  }) {
    return MaterialApp(
      home: AnnouncementListScreen(repository: repository),
    );
  }

  final sampleAnnouncements = [
    const AnnouncementItem(
      id: 'ann-1',
      title: 'Kebijakan Jam Kerja Fleksibel',
      summary: 'Penyesuaian jam kerja efektif mulai bulan depan.',
      content: '<p>Penyesuaian jam kerja efektif mulai bulan depan.</p>',
      priority: 'urgent',
      category: 'hr_policy',
      isPinned: true,
      createdAt: '2026-09-18T10:00:00.000Z',
    ),
    const AnnouncementItem(
      id: 'ann-2',
      title: 'Update Sistem Kehadiran',
      summary: 'Fitur baru absensi geofence telah aktif.',
      content: '<p>Fitur baru absensi geofence telah aktif.</p>',
      priority: 'normal',
      category: 'general',
      isPinned: false,
      createdAt: '2026-09-19T10:00:00.000Z',
    ),
  ];

  group('AnnouncementListScreen Widget Tests', () {
    testWidgets('renders list of announcements and search bar on success', (tester) async {
      final repo = _FakeAnnouncementRepository(items: sampleAnnouncements);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pengumuman'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Kebijakan Jam Kerja Fleksibel'), findsOneWidget);
      expect(find.text('Update Sistem Kehadiran'), findsOneWidget);
      expect(find.byType(AnnouncementCard), findsNWidgets(2));
    });

    testWidgets('renders empty state when no announcements are returned', (tester) async {
      final repo = _FakeAnnouncementRepository(items: const []);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum Ada Pengumuman'), findsOneWidget);
    });

    testWidgets('renders error state and retry button on repository exception', (tester) async {
      final repo = _FakeAnnouncementRepository(shouldFail: true);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat pengumuman'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('filters list when query is entered in search bar', (tester) async {
      final repo = _FakeAnnouncementRepository(items: sampleAnnouncements);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Fleksibel');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Kebijakan Jam Kerja Fleksibel'), findsOneWidget);
      expect(find.text('Update Sistem Kehadiran'), findsNothing);
    });

    testWidgets('tapping filter button opens filter bottom sheet', (tester) async {
      final repo = _FakeAnnouncementRepository(items: sampleAnnouncements);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      final filterButton = find.byIcon(LucideIcons.slidersHorizontal);
      expect(filterButton, findsOneWidget);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      expect(find.text('Filter Pengumuman'), findsOneWidget);
      expect(find.text('Terapkan Filter'), findsOneWidget);
    });
  });
}
