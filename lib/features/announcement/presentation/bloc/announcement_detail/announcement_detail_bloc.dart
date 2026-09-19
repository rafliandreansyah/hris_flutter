import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/data/repositories/announcement_repository_impl.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_event.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_state.dart';

class AnnouncementDetailBloc
    extends Bloc<AnnouncementDetailEvent, AnnouncementDetailState> {
  final AnnouncementRepository _repository;
  String? _currentId;

  AnnouncementDetailBloc({
    AnnouncementRepository? repository,
  })  : _repository = repository ?? AnnouncementRepositoryImpl(),
        super(const AnnouncementDetailState()) {
    on<AnnouncementDetailStarted>(_onStarted);
    on<AnnouncementDetailRefreshed>(_onRefreshed);
    on<AnnouncementDetailAcknowledgeSubmitted>(_onAcknowledgeSubmitted);
  }

  Future<void> _onStarted(
    AnnouncementDetailStarted event,
    Emitter<AnnouncementDetailState> emit,
  ) async {
    _currentId = event.id;
    emit(state.copyWith(
      status: AnnouncementDetailStatus.loading,
      errorMessage: null,
    ));

    try {
      final response = await _repository.getAnnouncementDetail(event.id);
      emit(state.copyWith(
        status: AnnouncementDetailStatus.success,
        detail: response.data,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AnnouncementDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AnnouncementDetailStatus.failure,
        errorMessage: 'Gagal memuat detail pengumuman: $e',
      ));
    }
  }

  Future<void> _onRefreshed(
    AnnouncementDetailRefreshed event,
    Emitter<AnnouncementDetailState> emit,
  ) async {
    final id = _currentId ?? state.detail?.id;
    if (id == null) return;

    try {
      final response = await _repository.getAnnouncementDetail(id);
      emit(state.copyWith(
        status: AnnouncementDetailStatus.success,
        detail: response.data,
      ));
    } catch (_) {
      // Keep existing data on pull to refresh error
    }
  }

  Future<void> _onAcknowledgeSubmitted(
    AnnouncementDetailAcknowledgeSubmitted event,
    Emitter<AnnouncementDetailState> emit,
  ) async {
    final detail = state.detail;
    if (detail == null || state.isAcknowledging) return;

    emit(state.copyWith(
      isAcknowledging: true,
      errorMessage: null,
      actionMessage: null,
    ));

    try {
      final response = await _repository.acknowledgeAnnouncement(detail.id);

      final updatedReadStatus = (detail.userReadStatus ??
              const AnnouncementUserReadStatus())
          .copyWith(
        isRead: true,
        isAcknowledged: true,
        acknowledgedAt: response.data.acknowledgedAt ??
            DateTime.now().toIso8601String(),
      );

      final updatedDetail = detail.copyWith(
        userReadStatus: updatedReadStatus,
      );

      emit(state.copyWith(
        isAcknowledging: false,
        isAcknowledgedSuccess: true,
        detail: updatedDetail,
        actionMessage: response.message.isNotEmpty
            ? response.message
            : 'Pengumuman berhasil dikonfirmasi.',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isAcknowledging: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isAcknowledging: false,
        errorMessage: 'Gagal mengonfirmasi pengumuman: $e',
      ));
    }
  }
}
