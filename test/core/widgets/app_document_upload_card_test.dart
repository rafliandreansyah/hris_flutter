import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_document_upload_card.dart';
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

  group('AppDocumentUploadCard Widget Tests', () {
    testWidgets('renders default state correctly (optional)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppDocumentUploadCard(),
        ),
      );

      expect(find.text('DOKUMEN PENDUKUNG'), findsOneWidget);
      expect(find.text('Opsional'), findsOneWidget);
      expect(find.text('Lampirkan Foto Bukti'), findsOneWidget);
      expect(
        find.text('Kamera atau Galeri (Maksimal 100 KB)'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.camera), findsOneWidget);
    });

    testWidgets('renders required state with custom title and badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppDocumentUploadCard(
            title: 'BUKTI TUGAS LEMBUR',
            isRequired: true,
            requiredTagText: 'Wajib Diunggah',
            uploadPlaceholderTitle: 'Pilih Foto Bukti',
          ),
        ),
      );

      expect(find.text('BUKTI TUGAS LEMBUR'), findsOneWidget);
      expect(find.text(' *'), findsOneWidget);
      expect(find.text('Wajib Diunggah'), findsOneWidget);
      expect(find.text('Pilih Foto Bukti'), findsOneWidget);
    });

    testWidgets('tapping upload box opens modal bottom sheet with options', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppDocumentUploadCard(
            uploadBoxKey: ValueKey('test_upload_box'),
            sampleTitle: 'Gunakan Sampel Bukti Cuti',
          ),
        ),
      );

      final uploadBox = find.byKey(const ValueKey('test_upload_box'));
      expect(uploadBox, findsOneWidget);

      await tester.tap(uploadBox);
      await tester.pumpAndSettle();

      expect(find.text('Pilih Sumber Dokumen / Foto'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
      expect(find.text('Gunakan Sampel Bukti Cuti'), findsOneWidget);
    });

    testWidgets('modal sheet respects allowSample: false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppDocumentUploadCard(
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

    testWidgets('renders preview when file is provided and triggers delete', (tester) async {
      final testFile = XFile('/tmp/test_image.jpg');
      XFile? selectedFile = testFile;
      ImageCompressResult? selectedResult = ImageCompressResult(
        file: testFile,
        originalSizeBytes: 2000000,
        compressedSizeBytes: 500000,
        compressionDuration: const Duration(milliseconds: 100),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppDocumentUploadCard(
                file: selectedFile,
                compressResult: selectedResult,
                deleteButtonKey: const ValueKey('test_delete_btn'),
                onFileWithCompressionChanged: (file, result) {
                  setState(() {
                    selectedFile = file;
                    selectedResult = result;
                  });
                },
              );
            },
          ),
        ),
      );

      // Verify file name, compression info, and preview button
      expect(find.text('test_image.jpg'), findsOneWidget);
      expect(find.textContaining('Hemat 75%'), findsOneWidget);
      expect(find.byKey(const ValueKey('preview_photo_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('preview_photo_thumbnail')), findsOneWidget);
      expect(find.byKey(const ValueKey('test_delete_btn')), findsOneWidget);

      // Tap delete
      await tester.tap(find.byKey(const ValueKey('test_delete_btn')));
      await tester.pumpAndSettle();

      // Should return to upload placeholder box
      expect(find.text('Lampirkan Foto Bukti'), findsOneWidget);
      expect(find.text('test_image.jpg'), findsNothing);
    });

    testWidgets('tapping preview button opens preview dialog', (tester) async {
      final testFile = XFile('/tmp/test_image.jpg');

      await tester.pumpWidget(
        buildTestableWidget(
          AppDocumentUploadCard(
            file: testFile,
            previewButtonKey: const ValueKey('test_preview_btn'),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('test_preview_btn')), findsOneWidget);

      // Tap preview
      await tester.tap(find.byKey(const ValueKey('test_preview_btn')));
      await tester.pumpAndSettle();

      // Verify dialog opened
      expect(find.byKey(const ValueKey('close_preview_dialog_btn')), findsOneWidget);
      expect(find.text('test_image.jpg'), findsWidgets);

      // Tap close dialog
      await tester.tap(find.byKey(const ValueKey('close_preview_dialog_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('close_preview_dialog_btn')), findsNothing);
    });

    testWidgets('displays compressing indicator when isCompressing is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppDocumentUploadCard(
            file: XFile('/tmp/test.jpg'),
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
