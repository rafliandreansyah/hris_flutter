import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('AppImagePreviewDialog Widget Tests', () {
    late File tempImageFile;

    setUp(() async {
      tempImageFile = File('${Directory.systemTemp.path}/preview_test_image.jpg');
      await tempImageFile.writeAsBytes(
        List.generate(50000, (index) => index % 256), // ~48.8 KB
      );
    });

    tearDown(() async {
      if (await tempImageFile.exists()) {
        await tempImageFile.delete();
      }
    });

    testWidgets('renders dialog with XFile, file name, and size badge', (tester) async {
      final xFile = XFile(tempImageFile.path);

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppImagePreviewDialog.show(
                  context,
                  xFile: xFile,
                  title: 'surat_dokter.jpg',
                  fileSizeBytes: 50000,
                  subtitle: 'Tervalidasi',
                );
              },
              child: const Text('Buka Pratinjau'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Buka Pratinjau'));
      await tester.pumpAndSettle();

      // Verify title, size badge, and instructions
      expect(find.text('surat_dokter.jpg'), findsOneWidget);
      expect(find.textContaining('48.8 KB (Maks 100 KB)'), findsOneWidget);
      expect(find.text('Tervalidasi'), findsOneWidget);
      expect(find.text('Cubit atau geser untuk memperbesar foto'), findsOneWidget);
      expect(find.byKey(const ValueKey('close_preview_dialog_btn')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Close dialog
      await tester.tap(find.byKey(const ValueKey('close_preview_dialog_btn')));
      await tester.pumpAndSettle();

      expect(find.text('surat_dokter.jpg'), findsNothing);
    });

    testWidgets('renders error state when file is null and imageUrl is empty', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppImagePreviewDialog(
            title: 'Foto Rusak',
          ),
        ),
      );

      expect(find.text('Foto Rusak'), findsOneWidget);
      expect(find.text('Gagal memuat pratinjau gambar'), findsOneWidget);
      expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
    });
  });
}
