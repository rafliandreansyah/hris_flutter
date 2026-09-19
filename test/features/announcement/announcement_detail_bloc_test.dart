import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_bloc.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_event.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_state.dart';

class _FakeAnnouncementDetailRepository implements AnnouncementRepository {
  AnnouncementDetailModel detail;
  bool shouldThrowDetail;
  bool shouldThrowAcknowledge;

  _FakeAnnouncementDetailRepository({
    AnnouncementDetailModel? detail,
    this.shouldThrowDetail = false,
    this.shouldThrowAcknowledge = false,
  }) : detail = detail ??
            const AnnouncementDetailModel(
              id: 'ann-1',
              title: 'Pengumuman Penting WFA',
              content: '<p>Konten WFA</p>',
              isPinned: true,
              requiresAcknowledgment: true,
              userReadStatus: AnnouncementUserReadStatus(
                isRead: true,
                isAcknowledged: false,
              ),
            );

  @override
  Future<AnnouncementListResponse> getAnnouncements({
    required int page,
    required int size,
    String? search,
    String? category,
    String? priority,
  }) async {
    return const AnnouncementListResponse(
      success: true,
      message: 'OK',
      data: [],
      meta: AnnouncementPaginationMeta(),
    );
  }

  @override
  Future<AnnouncementDetailResponse> getAnnouncementDetail(String id) async {
    if (shouldThrowDetail) {
      throw const ApiException(message: 'Gagal mengambil detail');
    }
    return AnnouncementDetailResponse(
      success: true,
      message: 'OK',
      data: detail,
    );
  }

  @override
  Future<AnnouncementAcknowledgeResponse> acknowledgeAnnouncement(
    String id,
  ) async {
    if (shouldThrowAcknowledge) {
      throw const ApiException(message: 'Gagal mengonfirmasi');
    }
    return const AnnouncementAcknowledgeResponse(
      success: true,
      message: 'Berhasil dikonfirmasi',
      data: AnnouncementAcknowledgeData(
        message: 'OK',
        acknowledgedAt: '2026-09-18T12:00:00.000Z',
      ),
    );
  }
}

void main() {
  group('AnnouncementDetailBloc Tests', () {
    test('emits [loading, success] on AnnouncementDetailStarted success', () async {
      final repo = _FakeAnnouncementDetailRepository();
      final bloc = AnnouncementDetailBloc(repository: repo);
      final states = <AnnouncementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementDetailStarted('ann-1'));
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, AnnouncementDetailStatus.loading);
      expect(states[1].status, AnnouncementDetailStatus.success);
      expect(states[1].detail?.id, 'ann-1');
      expect(states[1].detail?.title, 'Pengumuman Penting WFA');

      await bloc.close();
    });

    test('emits [loading, failure] on AnnouncementDetailStarted failure', () async {
      final repo = _FakeAnnouncementDetailRepository(shouldThrowDetail: true);
      final bloc = AnnouncementDetailBloc(repository: repo);
      final states = <AnnouncementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementDetailStarted('ann-1'));
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].status, AnnouncementDetailStatus.loading);
      expect(states[1].status, AnnouncementDetailStatus.failure);
      expect(states[1].errorMessage, 'Gagal mengambil detail');

      await bloc.close();
    });

    test('submits acknowledge and updates userReadStatus to isAcknowledged: true', () async {
      final repo = _FakeAnnouncementDetailRepository();
      final bloc = AnnouncementDetailBloc(repository: repo);
      bloc.add(const AnnouncementDetailStarted('ann-1'));
      await pumpEventQueue();

      final states = <AnnouncementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementDetailAcknowledgeSubmitted());
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].isAcknowledging, isTrue);
      expect(states[1].isAcknowledging, isFalse);
      expect(states[1].isAcknowledgedSuccess, isTrue);
      expect(states[1].detail?.userReadStatus?.isAcknowledged, isTrue);
      expect(
        states[1].detail?.userReadStatus?.acknowledgedAt,
        '2026-09-18T12:00:00.000Z',
      );

      await bloc.close();
    });

    test('handles failure when submitting acknowledge', () async {
      final repo = _FakeAnnouncementDetailRepository(shouldThrowAcknowledge: true);
      final bloc = AnnouncementDetailBloc(repository: repo);
      bloc.add(const AnnouncementDetailStarted('ann-1'));
      await pumpEventQueue();

      final states = <AnnouncementDetailState>[];
      bloc.stream.listen(states.add);

      bloc.add(const AnnouncementDetailAcknowledgeSubmitted());
      await pumpEventQueue();

      expect(states.length, 2);
      expect(states[0].isAcknowledging, isTrue);
      expect(states[1].isAcknowledging, isFalse);
      expect(states[1].isAcknowledgedSuccess, isFalse);
      expect(states[1].errorMessage, 'Gagal mengonfirmasi');

      await bloc.close();
    });
  });
}
