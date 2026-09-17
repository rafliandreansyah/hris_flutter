import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';

void main() {
  testWidgets(
      'showError does not throw RenderFlex overflow with long text on narrow screen (auto-vertical)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialogUtil.showError(
                    context,
                    title: 'Di Luar Radius Kantor',
                    message:
                        'Anda berada di luar radius lokasi kerja (50m). Silakan mendekat ke area kantor.',
                    retryText: 'Laporkan Kendala',
                    onRetry: () {},
                    closeText: 'Kembali',
                    onClose: () {},
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Laporkan Kendala'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'showError does not throw RenderFlex overflow even when forced Axis.horizontal on narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialogUtil.showError(
                    context,
                    title: 'Di Luar Radius Kantor',
                    message: 'Lokasi tidak sesuai.',
                    retryText: 'Laporkan Kendala',
                    onRetry: () {},
                    closeText: 'Kembali',
                    onClose: () {},
                    buttonsAxis: Axis.horizontal,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Laporkan Kendala'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'showError with single button renders correctly and dismisses',
      (tester) async {
    bool closeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialogUtil.showError(
                    context,
                    title: 'Kesalahan Sistem',
                    message: 'Terjadi kegagalan server.',
                    closeText: 'Tutup Saja',
                    onClose: () => closeCalled = true,
                  );
                },
                child: const Text('Show Error Single'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error Single'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tutup Saja'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tutup Saja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(closeCalled, isTrue);
    expect(find.text('Tutup Saja'), findsNothing);
  });

  testWidgets(
      'showError triggers onRetry and onClose callbacks and dismisses dialog',
      (tester) async {
    bool retryCalled = false;
    bool closeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialogUtil.showError(
                    context,
                    title: 'Error',
                    message: 'Terjadi kegagalan.',
                    retryText: 'Coba Lagi',
                    onRetry: () => retryCalled = true,
                    closeText: 'Tutup',
                    onClose: () => closeCalled = true,
                  );
                },
                child: const Text('Show Error'),
              );
            },
          ),
        ),
      ),
    );

    // Test onRetry
    await tester.tap(find.text('Show Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Coba Lagi'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(retryCalled, isTrue);
    expect(find.text('Coba Lagi'), findsNothing);

    // Test onClose
    await tester.tap(find.text('Show Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tutup'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(closeCalled, isTrue);
    expect(find.text('Tutup'), findsNothing);
  });

  testWidgets(
      'showWarning returns boolean value when confirmed or cancelled',
      (tester) async {
    bool? warningResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  warningResult = await AppDialogUtil.showWarning<bool>(
                    context,
                    title: 'Peringatan',
                    message: 'Yakin menghapus data?',
                    confirmText: 'Hapus',
                    cancelText: 'Batal',
                  );
                },
                child: const Text('Show Warning'),
              );
            },
          ),
        ),
      ),
    );

    // Test Confirm
    await tester.tap(find.text('Show Warning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Hapus'), findsOneWidget);
    await tester.tap(find.text('Hapus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(warningResult, isTrue);
    expect(find.text('Hapus'), findsNothing);

    // Test Cancel
    await tester.tap(find.text('Show Warning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Batal'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(warningResult, isFalse);
    expect(find.text('Batal'), findsNothing);
  });

  testWidgets('showSuccess triggers onOk and dismisses dialog', (tester) async {
    bool okCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialogUtil.showSuccess(
                    context,
                    title: 'Berhasil',
                    message: 'Data berhasil disimpan.',
                    buttonText: 'OK',
                    onOk: () => okCalled = true,
                  );
                },
                child: const Text('Show Success'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('OK'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(okCalled, isTrue);
    expect(find.text('OK'), findsNothing);
  });

  testWidgets('showLoading displays loading dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialogUtil.showLoading(
                    context,
                    title: 'Menyimpan Data...',
                    message: 'Harap tunggu beberapa saat.',
                  );
                },
                child: const Text('Show Loading'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Loading'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Menyimpan Data...'), findsOneWidget);
    expect(find.text('Harap tunggu beberapa saat.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showPermissionDialog renders permissions, cannot dismiss outside, and handles Deny/Allow', (
    tester,
  ) async {
    bool? permissionResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  permissionResult = await AppDialogUtil.showPermissionDialog(
                    context,
                    title: 'Izin Akses Presensi',
                    description: 'Mohon izinkan akses berikut untuk mencatat kehadiran:',
                    permissions: [
                      AppPermissionItem.location(),
                      AppPermissionItem.camera(),
                    ],
                    allowText: 'Izinkan Semua',
                    denyText: 'Tolak Akses',
                  );
                },
                child: const Text('Request Permissions'),
              );
            },
          ),
        ),
      ),
    );

    // Open permission dialog
    await tester.tap(find.text('Request Permissions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Title & Description
    expect(find.text('Izin Akses Presensi'), findsOneWidget);
    expect(find.text('Mohon izinkan akses berikut untuk mencatat kehadiran:'), findsOneWidget);

    // Verify Items
    expect(find.text('Lokasi & GPS'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);

    // Verify Buttons
    expect(find.text('Tolak Akses'), findsOneWidget);
    expect(find.text('Izinkan Semua'), findsOneWidget);

    // Verify cannot be dismissed by tapping outside (barrier)
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Izin Akses Presensi'), findsOneWidget);

    // Tap Deny
    await tester.tap(find.byKey(const ValueKey('permission_dialog_deny_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(permissionResult, isFalse);
    expect(find.text('Izin Akses Presensi'), findsNothing);

    // Reopen dialog to test Allow
    await tester.tap(find.text('Request Permissions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Izin Akses Presensi'), findsOneWidget);

    // Tap Allow
    await tester.tap(find.byKey(const ValueKey('permission_dialog_allow_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(permissionResult, isTrue);
    expect(find.text('Izin Akses Presensi'), findsNothing);
  });

  testWidgets('showConfirmation returns boolean on confirm and cancel', (
    tester,
  ) async {
    bool? confirmResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  confirmResult = await AppDialogUtil.showConfirmation(
                    context,
                    title: 'Konfirmasi Aksi',
                    message: 'Apakah Anda yakin ingin melanjutkan?',
                    confirmText: 'Lanjutkan',
                    cancelText: 'Batal',
                  );
                },
                child: const Text('Show Confirmation'),
              );
            },
          ),
        ),
      ),
    );

    // Open confirmation dialog
    await tester.tap(find.text('Show Confirmation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Konfirmasi Aksi'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin melanjutkan?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Batal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(confirmResult, isFalse);
    expect(find.text('Konfirmasi Aksi'), findsNothing);

    // Reopen and tap Confirm
    await tester.tap(find.text('Show Confirmation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Lanjutkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(confirmResult, isTrue);
    expect(find.text('Konfirmasi Aksi'), findsNothing);
  });

  testWidgets('showLogoutDialog renders logout title, message, and buttons', (
    tester,
  ) async {
    bool? logoutResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  logoutResult = await AppDialogUtil.showLogoutDialog(
                    context,
                  );
                },
                child: const Text('Show Logout'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Logout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Konfirmasi Logout'), findsOneWidget);
    expect(
      find.text('Apakah Anda yakin ingin keluar dari sesi akun ini?'),
      findsOneWidget,
    );
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // Tap Keluar
    await tester.tap(find.text('Keluar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(logoutResult, isTrue);
    expect(find.text('Konfirmasi Logout'), findsNothing);
  });
}
