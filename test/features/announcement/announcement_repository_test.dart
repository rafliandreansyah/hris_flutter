import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/announcement/data/datasources/announcement_remote_datasource.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:hris_flutter/features/announcement/data/repositories/announcement_repository_impl.dart';

class _MockAnnouncementRemoteDataSource implements AnnouncementRemoteDataSource {
  int getAnnouncementsCallCount = 0;
  int getAnnouncementDetailCallCount = 0;
  int acknowledgeAnnouncementCallCount = 0;

  dynamic mockListResponse;
  dynamic mockDetailResponse;
  dynamic mockAcknowledgeResponse;

  @override
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  }) async {
    getAnnouncementsCallCount++;
    return mockListResponse as AnnouncementListResponse;
  }

  @override
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id) async {
    getAnnouncementDetailCallCount++;
    return mockDetailResponse as AnnouncementDetailResponse;
  }

  @override
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(String id) async {
    acknowledgeAnnouncementCallCount++;
    return mockAcknowledgeResponse as AnnouncementAcknowledgeResponse;
  }
}

void main() {
  group('AnnouncementRepositoryImpl Tests', () {
    late _MockAnnouncementRemoteDataSource mockRemoteDataSource;
    late AnnouncementRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = _MockAnnouncementRemoteDataSource();
      repository = AnnouncementRepositoryImpl(remoteDataSource: mockRemoteDataSource);
    });

    test('getAnnouncements delegates to remote data source and returns result', () async {
      mockRemoteDataSource.mockListResponse = const AnnouncementListResponse(
        success: true,
        message: 'Success',
        data: [
          AnnouncementItem(
            id: 'ann-1',
            title: 'SOP Baru Perusahaan',
            content: 'Harap membaca dokumen SOP terlampir',
            priority: 'urgent',
            category: 'policy',
            isPinned: true,
          ),
        ],
        meta: AnnouncementPaginationMeta(page: 1, limit: 10, total: 1, totalPages: 1),
      );

      final result = await repository.getAnnouncements(
        page: 1,
        size: 10,
        search: 'SOP',
        category: 'policy',
        priority: 'urgent',
      );

      expect(mockRemoteDataSource.getAnnouncementsCallCount, equals(1));
      expect(result.data.length, equals(1));
      expect(result.data.first.title, equals('SOP Baru Perusahaan'));
      expect(result.data.first.isPinned, isTrue);
    });

    test('getAnnouncementDetail delegates to remote data source', () async {
      mockRemoteDataSource.mockDetailResponse = const AnnouncementDetailResponse(
        success: true,
        message: 'Success',
        data: AnnouncementDetailModel(
          id: 'ann-1',
          title: 'SOP Baru Perusahaan',
          content: 'Harap membaca dokumen SOP terlampir',
          priority: 'urgent',
          category: 'policy',
          attachments: [
            AnnouncementAttachment(
              id: 'att-1',
              fileName: 'sop.pdf',
              fileUrl: 'https://example.com/sop.pdf',
              fileSize: 2048,
            ),
          ],
        ),
      );

      final result = await repository.getAnnouncementDetail('ann-1');

      expect(mockRemoteDataSource.getAnnouncementDetailCallCount, equals(1));
      expect(result.data.id, equals('ann-1'));
      expect(result.data.attachments.length, equals(1));
      expect(result.data.attachments.first.fileName, equals('sop.pdf'));
    });

    test('acknowledgeAnnouncement delegates to remote data source', () async {
      mockRemoteDataSource.mockAcknowledgeResponse = const AnnouncementAcknowledgeResponse(
        success: true,
        message: 'Pengumuman berhasil dikonfirmasi',
        data: AnnouncementAcknowledgeData(
          message: 'Confirmed',
          acknowledgedAt: '2026-10-14T08:00:00Z',
        ),
      );

      final result = await repository.acknowledgeAnnouncement('ann-1');

      expect(mockRemoteDataSource.acknowledgeAnnouncementCallCount, equals(1));
      expect(result.success, isTrue);
      expect(result.data.message, equals('Confirmed'));
    });
  });
}
