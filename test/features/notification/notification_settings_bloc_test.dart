import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/models/notification_settings_model.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_settings/notification_settings_bloc.dart';

class MockNotificationSettingsRepository implements NotificationRepository {
  NotificationSettingsModel settings;
  bool shouldThrow;
  Map<String, dynamic>? lastUpdatePayload;

  MockNotificationSettingsRepository({
    NotificationSettingsModel? settings,
    this.shouldThrow = false,
  }) : settings = settings ??
            const NotificationSettingsModel(
              id: 'test-id',
              employeeId: 'emp-1',
              pushAttendanceRequest: true,
              pushLeave: true,
              pushOvertime: false,
              pushPayroll: true,
              pushAnnouncement: true,
              pushWarningLetter: false,
            );

  @override
  Future<NotificationSettingsResponse> getNotificationSettings() async {
    if (shouldThrow) {
      throw const ApiException(message: 'Gagal mengambil pengaturan');
    }
    return NotificationSettingsResponse(
      success: true,
      data: settings,
    );
  }

  @override
  Future<NotificationSettingsResponse> updateNotificationSettings(
    Map<String, dynamic> body,
  ) async {
    if (shouldThrow) {
      throw const ApiException(message: 'Gagal memperbarui pengaturan');
    }
    lastUpdatePayload = body;
    settings = settings.copyWith(
      pushAttendanceRequest: body['pushAttendanceRequest'] as bool?,
      pushLeave: body['pushLeave'] as bool?,
      pushOvertime: body['pushOvertime'] as bool?,
      pushPayroll: body['pushPayroll'] as bool?,
      pushAnnouncement: body['pushAnnouncement'] as bool?,
      pushWarningLetter: body['pushWarningLetter'] as bool?,
      updatedAt: DateTime.now(),
    );
    return NotificationSettingsResponse(
      success: true,
      message: 'Pengaturan notifikasi berhasil diperbarui',
      data: settings,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NotificationSettingsBloc Tests', () {
    late MockNotificationSettingsRepository repository;

    setUp(() {
      repository = MockNotificationSettingsRepository();
    });

    test('initial state has correct default values', () {
      final bloc = NotificationSettingsBloc(repository: repository);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.currentSettings, isNull);
      expect(bloc.state.initialSettings, isNull);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.successMessage, isNull);
      bloc.close();
    });

    test('NotificationSettingsStarted loads settings successfully', () async {
      final bloc = NotificationSettingsBloc(repository: repository);

      bloc.add(const NotificationSettingsStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.currentSettings, isNotNull);
      expect(bloc.state.currentSettings!.pushAttendanceRequest, isTrue);
      expect(bloc.state.currentSettings!.pushOvertime, isFalse);
      expect(bloc.state.initialSettings, bloc.state.currentSettings);
      bloc.close();
    });

    test('NotificationSettingsStarted emits error on ApiException', () async {
      repository.shouldThrow = true;
      final bloc = NotificationSettingsBloc(repository: repository);

      bloc.add(const NotificationSettingsStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, 'Gagal mengambil pengaturan');
      bloc.close();
    });

    test('NotificationSettingsToggled updates specific toggle', () async {
      final bloc = NotificationSettingsBloc(repository: repository);
      bloc.add(const NotificationSettingsStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.currentSettings!.pushOvertime, isFalse);

      bloc.add(const NotificationSettingsToggled(
        key: NotificationSettingKey.overtime,
        value: true,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.currentSettings!.pushOvertime, isTrue);
      expect(bloc.state.hasChanges, isTrue);
      bloc.close();
    });

    test('NotificationSettingsMasterToggled toggles all options simultaneously',
        () async {
      final bloc = NotificationSettingsBloc(repository: repository);
      bloc.add(const NotificationSettingsStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      // Toggle all ON
      bloc.add(const NotificationSettingsMasterToggled(true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.currentSettings!.isAllEnabled, isTrue);

      // Toggle all OFF
      bloc.add(const NotificationSettingsMasterToggled(false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.currentSettings!.pushAttendanceRequest, isFalse);
      expect(bloc.state.currentSettings!.pushLeave, isFalse);
      expect(bloc.state.currentSettings!.pushOvertime, isFalse);
      expect(bloc.state.currentSettings!.pushPayroll, isFalse);
      expect(bloc.state.currentSettings!.pushAnnouncement, isFalse);
      expect(bloc.state.currentSettings!.pushWarningLetter, isFalse);
      bloc.close();
    });

    test('NotificationSettingsReset reverts changes to initialSettings', () async {
      final bloc = NotificationSettingsBloc(repository: repository);
      bloc.add(const NotificationSettingsStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const NotificationSettingsMasterToggled(false));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.hasChanges, isTrue);

      bloc.add(const NotificationSettingsReset());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.hasChanges, isFalse);
      expect(bloc.state.currentSettings, bloc.state.initialSettings);
      bloc.close();
    });

    test('NotificationSettingsSubmitted saves changes successfully', () async {
      final bloc = NotificationSettingsBloc(repository: repository);
      bloc.add(const NotificationSettingsStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const NotificationSettingsToggled(
        key: NotificationSettingKey.overtime,
        value: true,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const NotificationSettingsSubmitted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.successMessage, 'Pengaturan notifikasi berhasil diperbarui');
      expect(repository.lastUpdatePayload?['pushOvertime'], isTrue);
      expect(bloc.state.hasChanges, isFalse);
      bloc.close();
    });

    test('NotificationSettingsSubmitted emits error message on failure',
        () async {
      final bloc = NotificationSettingsBloc(repository: repository);
      bloc.add(const NotificationSettingsStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      repository.shouldThrow = true;
      bloc.add(const NotificationSettingsSubmitted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.errorMessage, 'Gagal memperbarui pengaturan');
      bloc.close();
    });
  });
}
