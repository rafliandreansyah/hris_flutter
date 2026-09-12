import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompressResult Tests', () {
    test('formatBytes formats different byte magnitudes correctly', () {
      expect(ImageCompressResult.formatBytes(500), '500 B');
      expect(ImageCompressResult.formatBytes(1024), '1.0 KB');
      expect(ImageCompressResult.formatBytes(150 * 1024), '150.0 KB');
      expect(ImageCompressResult.formatBytes(2 * 1024 * 1024), '2.00 MB');
    });

    test('savedPercentage calculates reduction accurately', () {
      final result = ImageCompressResult(
        file: XFile('mock/path.jpg'),
        originalSizeBytes: 2000000, // 2MB
        compressedSizeBytes: 500000, // 500KB
        compressionDuration: const Duration(milliseconds: 120),
      );

      expect(result.originalSizeFormatted, '1.91 MB');
      expect(result.compressedSizeFormatted, '488.3 KB');
      expect(result.savedPercentage, 75.0);
      expect(result.toFile.path, 'mock/path.jpg');
    });

    test('savedPercentage handles edge cases when size is zero or increased', () {
      final zeroResult = ImageCompressResult(
        file: XFile('mock/path.jpg'),
        originalSizeBytes: 0,
        compressedSizeBytes: 0,
        compressionDuration: Duration.zero,
      );
      expect(zeroResult.savedPercentage, 0.0);
    });

    test('logCompressionResult outputs formatted summary for realistic compression', () {
      final realisticResult = ImageCompressResult(
        file: XFile('/data/user/0/com.oasish.hris/cache/compressed_activity.jpg'),
        originalSizeBytes: 4404019, // ~4.2 MB
        compressedSizeBytes: 388608, // ~380 KB
        compressionDuration: const Duration(milliseconds: 145),
      );

      expect(realisticResult.originalSizeFormatted, '4.20 MB');
      expect(realisticResult.compressedSizeFormatted, '379.5 KB');
      expect(realisticResult.savedPercentage, closeTo(91.17, 0.1));

      // Invoke the public log method to demonstrate console log output
      ImageCompressUtil.logCompressionResult(
        realisticResult,
        originalPath: '/storage/emulated/0/DCIM/Camera/IMG_20260908_105022.jpg',
      );
    });
  });

  group('ImageCompressUtil Tests', () {
    late File tempFile;

    setUp(() async {
      tempFile = File('${Directory.systemTemp.path}/test_image.jpg');
      await tempFile.writeAsBytes(List.generate(1000, (index) => index % 256));
    });

    tearDown(() async {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('isWithinMaxLimit correctly checks boundary of 100 KB', () {
      expect(ImageCompressUtil.defaultMaxSizeBytes, 100 * 1024);
      expect(ImageCompressUtil.isWithinMaxLimit(50 * 1024), isTrue);
      expect(ImageCompressUtil.isWithinMaxLimit(100 * 1024), isTrue);
      expect(ImageCompressUtil.isWithinMaxLimit(100 * 1024 + 1), isFalse);
      expect(ImageCompressUtil.isWithinMaxLimit(200 * 1024), isFalse);
    });

    test('compressXFile triggers onLoadingChanged lifecycle and returns result', () async {
      final loadingStates = <bool>[];

      final result = await ImageCompressUtil.compressXFile(
        XFile(tempFile.path),
        quality: 80,
        onLoadingChanged: (isLoading) => loadingStates.add(isLoading),
      );

      expect(loadingStates, [true, false]);
      expect(result.file.path, tempFile.path);
      expect(result.originalSizeBytes, 1000);
      expect(result.compressedSizeBytes, 1000);
    });

    test('compressXFile respects testCompressHandler for simulated 100KB compression', () async {
      final loadingStates = <bool>[];

      ImageCompressUtil.testCompressHandler = (file) async {
        return ImageCompressResult(
          file: file,
          originalSizeBytes: 4 * 1024 * 1024, // 4MB
          compressedSizeBytes: 85 * 1024, // 85 KB (<= 100 KB)
          compressionDuration: const Duration(milliseconds: 95),
        );
      };

      try {
        final result = await ImageCompressUtil.compressXFile(
          XFile(tempFile.path),
          onLoadingChanged: (isLoading) => loadingStates.add(isLoading),
        );

        expect(loadingStates, [true, false]);
        expect(result.compressedSizeBytes, 85 * 1024);
        expect(ImageCompressUtil.isWithinMaxLimit(result.compressedSizeBytes), isTrue);
        expect(result.savedPercentage, greaterThan(90));
      } finally {
        ImageCompressUtil.testCompressHandler = null;
      }
    });

    test('compressFile works seamlessly with File instance', () async {
      final loadingStates = <bool>[];

      final result = await ImageCompressUtil.compressFile(
        tempFile,
        onLoadingChanged: (isLoading) => loadingStates.add(isLoading),
      );

      expect(loadingStates, [true, false]);
      expect(result.file.path, tempFile.path);
      expect(result.originalSizeBytes, 1000);
    });
  });

  group('NonBlockingCompressIndicator Widget Tests', () {
    testWidgets('renders child normally when not compressing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NonBlockingCompressIndicator(
              isCompressing: false,
              child: Text('Image Preview Container'),
            ),
          ),
        ),
      );

      expect(find.text('Image Preview Container'), findsOneWidget);
      expect(find.text('Mengompres foto...'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders non-blocking loading pill when isCompressing is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NonBlockingCompressIndicator(
              isCompressing: true,
              message: 'Mengompres foto...',
              child: SizedBox(
                width: 200,
                height: 200,
                child: Text('Underneath Image'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Underneath Image'), findsOneWidget);
      expect(find.text('Mengompres foto...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
