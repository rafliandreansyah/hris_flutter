import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_photo_picker_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('AppPhotoPickerCard Widget Tests', () {
    testWidgets('renders empty state correctly with dashed border and camera icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppPhotoPickerCard(
            uploadPlaceholderTitle: 'Tap to Upload Work Evidence',
            uploadPlaceholderSubtitle: 'Kamera atau Galeri (Maksimal 100 KB)',
          ),
        ),
      );

      expect(find.text('Tap to Upload Work Evidence'), findsOneWidget);
      expect(find.text('Kamera atau Galeri (Maksimal 100 KB)'), findsOneWidget);
      expect(find.byIcon(LucideIcons.camera), findsOneWidget);
    });

    testWidgets('tapping empty state opens bottom sheet modal with camera, gallery, and sample', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppPhotoPickerCard(
            uploadBoxKey: ValueKey('test_upload_box'),
            sheetTitle: 'Pilih Sumber Foto Bukti',
            sampleTitle: 'Gunakan Foto Sampel Khusus',
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('test_upload_box')));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Sumber Foto Bukti'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
      expect(find.text('Gunakan Foto Sampel Khusus'), findsOneWidget);
    });

    testWidgets('bottom sheet respects allowSample: false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppPhotoPickerCard(
            uploadBoxKey: ValueKey('test_upload_box'),
            allowSample: false,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('test_upload_box')));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Sumber Dokumen / Foto'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
      expect(find.text('Gunakan Sampel Bukti'), findsNothing);
    });

    testWidgets('renders selected photo card with compression badge, actions, and delete', (tester) async {
      final testFile = XFile('/tmp/my_proof.jpg');
      XFile? currentFile = testFile;
      ImageCompressResult? currentResult = ImageCompressResult(
        file: testFile,
        originalSizeBytes: 400000,
        compressedSizeBytes: 100000,
        compressionDuration: const Duration(milliseconds: 50),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppPhotoPickerCard(
                file: currentFile,
                compressResult: currentResult,
                previewButtonKey: const ValueKey('test_preview_btn'),
                deleteButtonKey: const ValueKey('test_delete_btn'),
                changeButtonKey: const ValueKey('test_change_btn'),
                previewThumbnailKey: const ValueKey('test_thumbnail'),
                onFileChanged: (file, result) {
                  setState(() {
                    currentFile = file;
                    currentResult = result;
                  });
                },
              );
            },
          ),
        ),
      );

      // Verify filename, compression badge, preview, delete, and change photo buttons
      expect(find.text('my_proof.jpg'), findsOneWidget);
      expect(find.textContaining('Hemat 75%'), findsOneWidget);
      expect(find.byKey(const ValueKey('test_preview_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('test_delete_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('test_change_btn')), findsOneWidget);
      expect(find.text('Ganti Foto'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byKey(const ValueKey('test_delete_btn')));
      await tester.pumpAndSettle();

      // Returns to empty state
      expect(find.text('Tap to Capture or Upload Photo'), findsOneWidget);
      expect(find.text('my_proof.jpg'), findsNothing);
    });

    testWidgets('tapping preview button opens AppImagePreviewDialog', (tester) async {
      final testFile = XFile('/tmp/preview_photo.jpg');

      await tester.pumpWidget(
        buildTestableWidget(
          AppPhotoPickerCard(
            file: testFile,
            previewTitle: 'Pratinjau Foto Kegiatan',
            previewButtonKey: const ValueKey('preview_btn'),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('preview_btn')));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.byKey(const ValueKey('close_preview_dialog_btn')), findsOneWidget);
      expect(find.text('preview_photo.jpg'), findsWidgets);

      // Close dialog
      await tester.tap(find.byKey(const ValueKey('close_preview_dialog_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('close_preview_dialog_btn')), findsNothing);
    });

    testWidgets('displays compressing indicator and message when isCompressing is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppPhotoPickerCard(
            file: XFile('/tmp/photo.jpg'),
            isCompressing: true,
          ),
        ),
      );

      expect(find.text('Mengompresi foto...'), findsOneWidget);
      expect(find.text('Mohon tunggu sebentar (Maks 100 KB)'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
