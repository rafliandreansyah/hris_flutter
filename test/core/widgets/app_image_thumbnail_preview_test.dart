import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/app_image_thumbnail_preview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('AppImageThumbnailPreview Widget Tests', () {
    testWidgets('returns SizedBox.shrink when neither imageUrl nor file is provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppImageThumbnailPreview(
            height: 140,
            title: 'Empty Preview',
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.zoomIn), findsNothing);
    });

    testWidgets('renders center zoom indicator and hint text for image url', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppImageThumbnailPreview(
            imageUrl: 'https://example.com/test_evidence.jpg',
            height: 150,
            title: 'Bukti Tugas Lembur',
            hintText: 'Ketuk untuk memperbesar foto bukti',
          ),
        ),
      );

      // Center zoom icon
      expect(find.byIcon(LucideIcons.zoomIn), findsOneWidget);
      // Bottom-left hint pill
      expect(find.text('Ketuk untuk memperbesar foto bukti'), findsOneWidget);
    });

    testWidgets('renders custom watermark overlay when provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppImageThumbnailPreview(
            imageUrl: 'https://example.com/attendance.jpg',
            height: 200,
            title: 'Bukti Foto Presensi',
            customOverlay: Positioned(
              bottom: 8,
              left: 8,
              child: Text('Senin, 16 Sep 2026 • 08:30'),
            ),
          ),
        ),
      );

      expect(find.text('Senin, 16 Sep 2026 • 08:30'), findsOneWidget);
      expect(find.byIcon(LucideIcons.zoomIn), findsOneWidget);
    });

    testWidgets('tapping thumbnail triggers image preview dialog', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppImageThumbnailPreview(
            file: File('/tmp/local_photo.jpg'),
            height: 160,
            title: 'Foto Surat Cuti Dokter',
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.zoomIn), findsOneWidget);

      await tester.tap(find.byType(AppImageThumbnailPreview));
      await tester.pumpAndSettle();

      // Dialog opens with title & close button
      expect(find.text('Foto Surat Cuti Dokter'), findsWidgets);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.x), findsNothing);
    });
  });
}
