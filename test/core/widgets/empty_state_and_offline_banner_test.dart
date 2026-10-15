import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/services/network_connectivity_service.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/offline_status_banner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppEmptyState', () {
    testWidgets('menampilkan judul & subtitle tanpa tombol bila tidak ada callback', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            icon: LucideIcons.inbox,
            title: 'Belum ada data',
            subtitle: 'Data akan muncul di sini',
          ),
        ),
      );

      expect(find.text('Belum ada data'), findsOneWidget);
      expect(find.text('Data akan muncul di sini'), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('message dipakai sebagai alias subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            icon: LucideIcons.inbox,
            title: 'Kosong',
            message: 'Pesan alias',
          ),
        ),
      );

      expect(find.text('Pesan alias'), findsOneWidget);
    });

    testWidgets('tanpa subtitle maupun message memicu assertion', (tester) async {
      expect(
        () => AppEmptyState(icon: LucideIcons.inbox, title: 'Kosong'),
        throwsAssertionError,
      );
    });

    testWidgets('tombol Reset Filter muncul dan memanggil callback', (tester) async {
      var resetCount = 0;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: LucideIcons.searchX,
            title: 'Tidak ditemukan',
            subtitle: 'Coba ubah filter',
            hasActiveFilter: true,
            onResetFilter: () => resetCount++,
          ),
        ),
      );

      expect(find.text('Reset Filter'), findsOneWidget);
      await tester.tap(find.text('Reset Filter'));
      await tester.pump();
      expect(resetCount, 1);
    });

    testWidgets('resetFilterText kustom menggantikan label default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: LucideIcons.searchX,
            title: 'Tidak ditemukan',
            subtitle: 'x',
            hasActiveFilter: true,
            onResetFilter: () {},
            resetFilterText: 'Hapus Pencarian',
          ),
        ),
      );

      expect(find.text('Hapus Pencarian'), findsOneWidget);
      expect(find.text('Reset Filter'), findsNothing);
    });

    testWidgets('tombol aksi (actionText / actionLabel) memanggil onAction', (tester) async {
      var actionCount = 0;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: LucideIcons.plus,
            title: 'Belum ada pengajuan',
            subtitle: 'Buat pengajuan pertama Anda',
            actionLabel: 'Buat Pengajuan',
            onAction: () => actionCount++,
          ),
        ),
      );

      expect(find.text('Buat Pengajuan'), findsOneWidget);
      await tester.tap(find.text('Buat Pengajuan'));
      await tester.pump();
      expect(actionCount, 1);
    });

    testWidgets('helperText ditampilkan bila diisi', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppEmptyState(
            icon: LucideIcons.info,
            title: 'Info',
            subtitle: 'Sub',
            helperText: 'Panduan tambahan',
          ),
        ),
      );

      expect(find.text('Panduan tambahan'), findsOneWidget);
    });
  });

  group('OfflineStatusBanner', () {
    late StreamController<bool> controller;

    setUp(() {
      controller = StreamController<bool>.broadcast();
      NetworkConnectivityService.testStream = controller.stream;
    });

    tearDown(() async {
      NetworkConnectivityService.testStream = null;
      await controller.close();
    });

    testWidgets('online: banner tidak tampil dan child dirender', (tester) async {
      await tester.pumpWidget(
        _wrap(const OfflineStatusBanner(child: Text('konten'))),
      );

      expect(find.text('konten'), findsOneWidget);
      expect(find.textContaining('Tidak ada koneksi'), findsNothing);
      expect(find.textContaining('terhubung kembali'), findsNothing);
    });

    testWidgets('offline: banner "Tidak ada koneksi" muncul dan menetap', (tester) async {
      await tester.pumpWidget(
        _wrap(const OfflineStatusBanner(child: Text('konten'))),
      );

      controller.add(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 5));

      expect(find.textContaining('Tidak ada koneksi internet'), findsOneWidget);
      expect(find.text('konten'), findsOneWidget);
    });

    testWidgets('kembali online: tampil "terhubung kembali" lalu hilang setelah 2.5 detik', (tester) async {
      await tester.pumpWidget(
        _wrap(const OfflineStatusBanner(child: Text('konten'))),
      );

      controller.add(false);
      await tester.pump(const Duration(milliseconds: 400));
      controller.add(true);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('terhubung kembali'), findsOneWidget);
      expect(find.textContaining('Tidak ada koneksi'), findsNothing);

      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('terhubung kembali'), findsNothing);
    });

    testWidgets('layar sempit (320dp) tidak overflow saat offline', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(const OfflineStatusBanner(child: Text('konten'))),
      );
      controller.add(false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Tidak ada koneksi internet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('event online tanpa pernah offline tidak menampilkan banner', (tester) async {
      await tester.pumpWidget(
        _wrap(const OfflineStatusBanner(child: Text('konten'))),
      );

      controller.add(true);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('terhubung kembali'), findsNothing);
    });
  });
}
