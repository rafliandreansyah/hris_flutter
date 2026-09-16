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
}
