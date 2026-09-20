import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/notification/data/models/notification_settings_model.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_settings/notification_settings_bloc.dart';
import 'package:hris_flutter/features/notification/presentation/pages/notification_settings_screen.dart';

class _FakeNotificationSettingsRepository implements NotificationRepository {
  NotificationSettingsModel settings;
  bool shouldThrow;
  bool submitCalled = false;

  _FakeNotificationSettingsRepository({
    NotificationSettingsModel? settings,
    this.shouldThrow = false,
  }) : settings = settings ??
            NotificationSettingsModel(
              id: 'set-1',
              employeeId: 'emp-1',
              pushAttendanceRequest: true,
              pushLeave: true,
              pushOvertime: false,
              pushPayroll: true,
              pushAnnouncement: true,
              pushWarningLetter: false,
              updatedAt: DateTime(2026, 8, 28, 14, 15),
            );

  @override
  Future<NotificationSettingsResponse> getNotificationSettings() async {
    if (shouldThrow) {
      throw const ApiException(message: 'Koneksi internet bermasalah');
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
      throw const ApiException(message: 'Gagal memperbarui');
    }
    submitCalled = true;
    return NotificationSettingsResponse(
      success: true,
      message: 'Preferensi berhasil disimpan',
      data: settings,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget createTestableWidget({
    NotificationRepository? repository,
    NotificationSettingsBloc? bloc,
  }) {
    return MaterialApp(
      home: NotificationSettingsScreen(
        repository: repository,
        bloc: bloc,
      ),
    );
  }

  group('NotificationSettingsScreen Widget Tests', () {
    testWidgets('renders AppBar with title, subtitle, and reset action',
        (WidgetTester tester) async {
      configureViewport(tester);
      final repository = _FakeNotificationSettingsRepository();
      await tester.pumpWidget(createTestableWidget(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
      expect(
        find.text('Kelola preferensi pemberitahuan & alarm push'),
        findsOneWidget,
      );
      expect(find.byTooltip('Reset'), findsOneWidget);
    });

    testWidgets('renders all section cards and switch titles',
        (WidgetTester tester) async {
      configureViewport(tester);
      final repository = _FakeNotificationSettingsRepository();
      await tester.pumpWidget(createTestableWidget(repository: repository));
      await tester.pumpAndSettle();

      // Master Card
      expect(find.text('Semua Notifikasi Push'), findsOneWidget);
      expect(
        find.text('Aktifkan atau matikan seluruh notifikasi sekaligus'),
        findsOneWidget,
      );

      // Section Headers
      expect(find.text('KEHADIRAN & JAM KERJA'), findsOneWidget);
      expect(find.text('IZIN, CUTI & PAYROLL'), findsOneWidget);
      expect(find.text('INFORMASI RESMI & KEPATUHAN'), findsOneWidget);

      // Switch Titles
      expect(find.text('Persetujuan Presensi'), findsOneWidget);
      expect(find.text('Lembur & Ekstra Shift'), findsOneWidget);
      expect(find.text('Cuti & Izin Kerja'), findsOneWidget);
      expect(find.text('Slip Gaji & Pembayaran'), findsOneWidget);
      expect(find.text('Pengumuman Kantor'), findsOneWidget);
      expect(find.text('Surat Peringatan & Teguran'), findsOneWidget);

      // Save Button and Timestamp
      expect(find.text('Simpan Preferensi Notifikasi'), findsOneWidget);
      expect(find.textContaining('Terakhir diperbarui:'), findsOneWidget);
    });

    testWidgets('renders error state and handles retry button',
        (WidgetTester tester) async {
      configureViewport(tester);
      final repository = _FakeNotificationSettingsRepository(shouldThrow: true);
      await tester.pumpWidget(createTestableWidget(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Koneksi internet bermasalah'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Fix repository error and tap Coba Lagi in body
      repository.shouldThrow = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Semua Notifikasi Push'), findsOneWidget);
    });

    testWidgets('toggling a switch updates state', (WidgetTester tester) async {
      configureViewport(tester);
      final repository = _FakeNotificationSettingsRepository();
      final bloc = NotificationSettingsBloc(repository: repository)
        ..add(const NotificationSettingsStarted());
      await tester.pumpWidget(createTestableWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Overtime is initially false
      expect(bloc.state.currentSettings!.pushOvertime, isFalse);

      // Tap switch for overtime
      await tester.tap(find.byKey(const Key('switch_overtime')));
      await tester.pumpAndSettle();

      expect(bloc.state.currentSettings!.pushOvertime, isTrue);
    });

    testWidgets('toggling master switch toggles all switches',
        (WidgetTester tester) async {
      configureViewport(tester);
      final repository = _FakeNotificationSettingsRepository();
      final bloc = NotificationSettingsBloc(repository: repository)
        ..add(const NotificationSettingsStarted());
      await tester.pumpWidget(createTestableWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Tap master switch to turn all on
      await tester.tap(find.byKey(const Key('master_notification_switch')));
      await tester.pumpAndSettle();

      expect(bloc.state.currentSettings!.isAllEnabled, isTrue);
    });

    testWidgets('tapping Reset button resets settings',
        (WidgetTester tester) async {
      configureViewport(tester);
      final repository = _FakeNotificationSettingsRepository();
      final bloc = NotificationSettingsBloc(repository: repository)
        ..add(const NotificationSettingsStarted());
      await tester.pumpWidget(createTestableWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Change a switch
      bloc.add(const NotificationSettingsMasterToggled(false));
      await tester.pumpAndSettle();
      expect(bloc.state.hasChanges, isTrue);

      // Tap reset
      await tester.tap(find.byTooltip('Reset'));
      await tester.pumpAndSettle();

      expect(bloc.state.hasChanges, isFalse);
      expect(find.text('Pengaturan dikembalikan ke awal'), findsOneWidget);
    });

    testWidgets('tapping save button calls updateNotificationSettings',
        (WidgetTester tester) async {
      configureViewport(tester);
      final repository = _FakeNotificationSettingsRepository();
      await tester.pumpWidget(createTestableWidget(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Preferensi Notifikasi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.submitCalled, isTrue);
      expect(find.text('Preferensi berhasil disimpan'), findsOneWidget);
    });
  });
}
