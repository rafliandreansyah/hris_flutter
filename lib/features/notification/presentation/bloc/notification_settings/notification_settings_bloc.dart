import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/models/notification_settings_model.dart';
import 'package:hris_flutter/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

export 'notification_settings_event.dart';
export 'notification_settings_state.dart';

class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  final NotificationRepository _repository;

  NotificationSettingsBloc({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepositoryImpl(),
        super(const NotificationSettingsState()) {
    on<NotificationSettingsStarted>(_onStarted);
    on<NotificationSettingsRefreshed>(_onRefreshed);
    on<NotificationSettingsToggled>(_onToggled);
    on<NotificationSettingsMasterToggled>(_onMasterToggled);
    on<NotificationSettingsReset>(_onReset);
    on<NotificationSettingsSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    NotificationSettingsStarted event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final response = await _repository.getNotificationSettings();
      emit(state.copyWith(
        isLoading: false,
        initialSettings: response.data,
        currentSettings: response.data,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    NotificationSettingsRefreshed event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    try {
      final response = await _repository.getNotificationSettings();
      emit(state.copyWith(
        initialSettings: response.data,
        currentSettings: response.data,
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onToggled(
    NotificationSettingsToggled event,
    Emitter<NotificationSettingsState> emit,
  ) {
    final current = state.currentSettings ?? const NotificationSettingsModel();
    NotificationSettingsModel updated;

    switch (event.key) {
      case NotificationSettingKey.attendanceRequest:
        updated = current.copyWith(pushAttendanceRequest: event.value);
        break;
      case NotificationSettingKey.leave:
        updated = current.copyWith(pushLeave: event.value);
        break;
      case NotificationSettingKey.overtime:
        updated = current.copyWith(pushOvertime: event.value);
        break;
      case NotificationSettingKey.payroll:
        updated = current.copyWith(pushPayroll: event.value);
        break;
      case NotificationSettingKey.announcement:
        updated = current.copyWith(pushAnnouncement: event.value);
        break;
      case NotificationSettingKey.warningLetter:
        updated = current.copyWith(pushWarningLetter: event.value);
        break;
    }

    emit(state.copyWith(
      currentSettings: updated,
      clearError: true,
      clearSuccess: true,
    ));
  }

  void _onMasterToggled(
    NotificationSettingsMasterToggled event,
    Emitter<NotificationSettingsState> emit,
  ) {
    final current = state.currentSettings ?? const NotificationSettingsModel();
    final updated = current.toggleAll(event.value);

    emit(state.copyWith(
      currentSettings: updated,
      clearError: true,
      clearSuccess: true,
    ));
  }

  void _onReset(
    NotificationSettingsReset event,
    Emitter<NotificationSettingsState> emit,
  ) {
    if (state.initialSettings != null) {
      emit(state.copyWith(
        currentSettings: state.initialSettings,
        clearError: true,
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onSubmitted(
    NotificationSettingsSubmitted event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final toSave = state.currentSettings;
    if (toSave == null) return;

    emit(state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final response = await _repository.updateNotificationSettings(
        toSave.toUpdatePayload(),
      );
      final updatedData = response.data ?? toSave;
      emit(state.copyWith(
        isSubmitting: false,
        initialSettings: updatedData,
        currentSettings: updatedData,
        successMessage: response.message ?? 'Pengaturan notifikasi berhasil diperbarui',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
