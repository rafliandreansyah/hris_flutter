import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/announcement_detail_screen.dart';

class _FakeAnnouncementDetailRepo implements AnnouncementRepository {
  final bool shouldFail;
  final int failStatus;
  bool acknowledged = false;

  _FakeAnnouncementDetailRepo({
    this.shouldFail = false,
    this.failStatus = 404,
  });

  @override
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id) async {
    if (shouldFail) {
      throw ApiException(
        message: 'Pengumuman tidak ditemukan',
        statusCode: failStatus,
      );
    }

    return AnnouncementDetailResponse(
      success: true,
      message: 'OK',
      data: AnnouncementDetailModel(
            id: id,
            title: 'Kebijakan Kerja Fleksibel (WFA)',
            content: '<p>Detail pengumuman kebijakan WFA.</p>',
            priority: 'urgent',
            category: 'hr_policy',
            isPinned: true,
            requiresAcknowledgment: true,
            userReadStatus: AnnouncementUserReadStatus(
              isRead: true,
              isAcknowledged: acknowledged,
            ),
            attachments: const [
              AnnouncementAttachment(
                id: 'att-1',
                fileName: 'Pedoman_WFA_2026.pdf',
                fileUrl: 'https://example.com/pedoman.pdf',
                fileSize: 1048576,
                fileType: 'application/pdf',
              ),
            ],
            author: const AnnouncementAuthor(
              id: 'auth-1',
              firstName: 'Jessica',
              lastName: 'Pranata',
              employeeNumber: 'HR-001',
              department: AnnouncementOrgItem(id: 'd1', name: 'Human Resources'),
              position: AnnouncementOrgItem(id: 'p1', name: 'Head of HR'),
            ),
          ),
    );
  }

  @override
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(String id) async {
    acknowledged = true;
    return const AnnouncementAcknowledgeResponse(
      success: true,
      message: 'Pengumuman berhasil dikonfirmasi',
      data: AnnouncementAcknowledgeData(
        message: 'Sukses',
      ),
    );
  }
}

void main() {
  Widget buildTestableWidget({
    required AnnouncementRepository repository,
    String id = 'ann-123',
  }) {
    return MaterialApp(
      home: AnnouncementDetailScreen(
        id: id,
        repository: repository,
      ),
    );
  }

  group('AnnouncementDetailScreen Widget Tests', () {
    testWidgets('renders all details, author card, and attachment list on success',
        (tester) async {
      final repo = _FakeAnnouncementDetailRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Kebijakan Kerja Fleksibel (WFA)'), findsOneWidget);
      expect(find.text('Jessica Pranata'), findsOneWidget);
      expect(find.text('Pedoman_WFA_2026.pdf'), findsOneWidget);
      expect(
        find.text('Saya Mengerti & Telah Membaca (Acknowledge)'),
        findsOneWidget,
      );
    });

    testWidgets('tapping acknowledge button shows confirmation and calls repository',
        (tester) async {
      final repo = _FakeAnnouncementDetailRepo();

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      final acknowledgeBtn = find.widgetWithText(
        AppButton,
        'Saya Mengerti & Telah Membaca (Acknowledge)',
      );
      expect(acknowledgeBtn, findsOneWidget);

      await tester.tap(acknowledgeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation dialog should be visible
      expect(find.text('Konfirmasi Pembacaan'), findsOneWidget);
      expect(find.text('Ya, Konfirmasi'), findsOneWidget);

      await tester.tap(find.text('Ya, Konfirmasi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.acknowledged, isTrue);
    });

    testWidgets('renders error state when repository throws exception',
        (tester) async {
      final repo = _FakeAnnouncementDetailRepo(shouldFail: true);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pengumuman tidak ditemukan'), findsOneWidget);
      // 404: hanya "Kembali", tanpa tombol retry (AGENTS.md #5).
      expect(find.widgetWithText(AppButton, 'Kembali'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('error 500 menampilkan pesan API dan tombol Coba Lagi',
        (tester) async {
      final repo = _FakeAnnouncementDetailRepo(shouldFail: true, failStatus: 500);

      await tester.pumpWidget(buildTestableWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Pengumuman tidak ditemukan'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Coba Lagi'), findsOneWidget);
      expect(find.text('Kembali'), findsNothing);
    });
  });
}
