import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/features/announcement/presentation/pages/pdf_viewer_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget buildTestableWidget({
    String title = 'Surat Edaran Direksi',
    String fileName = 'SE_Direksi_2026.pdf',
    String fileUrl = 'https://example.com/se_direksi.pdf',
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: PdfViewerScreen(
        title: title,
        fileName: fileName,
        fileUrl: fileUrl,
        pdfViewer: const SizedBox(key: Key('pdf_view_content')),
      ),
    );
  }

  group('PdfViewerScreen Widget Tests', () {
    testWidgets('renders app bar with file title, file name and actions', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('SE_Direksi_2026.pdf'), findsOneWidget);
      expect(find.text('Surat Edaran Direksi'), findsOneWidget);
      expect(find.byIcon(LucideIcons.share2), findsOneWidget);
      expect(find.byIcon(LucideIcons.download), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byKey(const Key('pdf_view_content')), findsOneWidget);
    });

    testWidgets('renders in dark mode without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(themeMode: ThemeMode.dark),
      );
      await tester.pump();

      expect(find.text('SE_Direksi_2026.pdf'), findsOneWidget);
      expect(find.byKey(const Key('pdf_view_content')), findsOneWidget);
    });
  });
}
