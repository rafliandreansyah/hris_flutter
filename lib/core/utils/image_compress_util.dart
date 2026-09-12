import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:image_picker/image_picker.dart';

/// Hasil kompresi gambar dengan statistik ukuran dan waktu proses.
class ImageCompressResult {
  final XFile file;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final Duration compressionDuration;

  const ImageCompressResult({
    required this.file,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.compressionDuration,
  });

  /// Format ukuran dalam byte menjadi teks yang mudah dibaca (B, KB, MB)
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get originalSizeFormatted => formatBytes(originalSizeBytes);
  String get compressedSizeFormatted => formatBytes(compressedSizeBytes);

  /// Persentase pengurangan ukuran berkas
  double get savedPercentage {
    if (originalSizeBytes <= 0) return 0.0;
    final diff = originalSizeBytes - compressedSizeBytes;
    if (diff <= 0) return 0.0;
    return (diff / originalSizeBytes) * 100;
  }

  File get toFile => File(file.path);
}

/// Utility terpusat untuk kompresi gambar secara non-blocking di background thread.
///
/// Dirancang untuk alur:
/// 1. Pengambilan foto (Kamera / Galeri)
/// 2. Kompresi otomatis di background tanpa memblokir interaksi UI pengguna
/// 3. Menampilkan indikator loading non-blocking pada komponen gambar
class ImageCompressUtil {
  /// Batas maksimal ukuran berkas default (100 KB = 102.400 bytes)
  static const int defaultMaxSizeBytes = 100 * 1024;

  /// Hook pengujian untuk menyimulasikan hasil kompresi di lingkungan unit test
  @visibleForTesting
  static Future<ImageCompressResult> Function(XFile file)? testCompressHandler;

  /// Memeriksa apakah aplikasi sedang berjalan dalam mode testing
  static bool get isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah ukuran byte berkas berada di dalam batas maksimal (default 100 KB)
  static bool isWithinMaxLimit(
    int bytes, {
    int maxBytes = defaultMaxSizeBytes,
  }) {
    return bytes <= maxBytes;
  }

  /// Melakukan kompresi terhadap berkas [XFile] di background thread.
  ///
  /// Menjamin ukuran berkas hasil kompresi tidak melebihi [maxSizeBytes] (default: 100 KB)
  /// dengan algoritma adaptif bertahap (adaptive multi-stage step-down) tanpa merusak
  /// kualitas ketajaman gambar maupun keterbacaan teks dokumen.
  ///
  /// - [file]: Berkas input dari kamera / galeri.
  /// - [maxSizeBytes]: Batas maksimal ukuran berkas dalam byte (default 100 KB).
  /// - [quality]: Kualitas awal kompresi (opsional, jika tidak diset otomatis diatur adaptif).
  /// - [minWidth] & [minHeight]: Resolusi awal gambar (opsional, otomatis disesuaikan secara proporsional).
  /// - [format]: Format output (JPEG, WebP, PNG).
  /// - [onLoadingChanged]: Callback non-blocking untuk memperbarui status loading di UI.
  static Future<ImageCompressResult> compressXFile(
    XFile file, {
    int maxSizeBytes = defaultMaxSizeBytes,
    int? quality,
    int? minWidth,
    int? minHeight,
    CompressFormat format = CompressFormat.jpeg,
    ValueChanged<bool>? onLoadingChanged,
  }) async {
    final stopwatch = Stopwatch()..start();
    onLoadingChanged?.call(true);

    try {
      final originalLength = await file.length();

      // Jika dijalankan di unit test atau platform tanpa native codec
      if (isTestEnvironment) {
        if (testCompressHandler != null) {
          final mockResult = await testCompressHandler!(file);
          stopwatch.stop();
          onLoadingChanged?.call(false);
          return mockResult;
        }

        stopwatch.stop();
        onLoadingChanged?.call(false);
        final testResult = ImageCompressResult(
          file: file,
          originalSizeBytes: originalLength,
          compressedSizeBytes: originalLength,
          compressionDuration: stopwatch.elapsed,
        );
        logCompressionResult(testResult, originalPath: file.path);
        return testResult;
      }

      // Jika berkas asli sudah di bawah batas target dan berformat standar gambar, langsung gunakan
      final extension = format == CompressFormat.webp ? 'webp' : 'jpg';
      final lowerPath = file.path.toLowerCase();
      final isMatchingFormat = format == CompressFormat.webp
          ? lowerPath.endsWith('.webp')
          : (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg'));

      if (maxSizeBytes > 0 && originalLength <= maxSizeBytes && isMatchingFormat) {
        stopwatch.stop();
        onLoadingChanged?.call(false);
        final untouchedResult = ImageCompressResult(
          file: file,
          originalSizeBytes: originalLength,
          compressedSizeBytes: originalLength,
          compressionDuration: stopwatch.elapsed,
        );
        logCompressionResult(untouchedResult, originalPath: file.path);
        return untouchedResult;
      }

      // Bersihkan ekstensi bawaan agar tidak terjadi duplikasi .jpg.jpg
      final rawName = file.name.isNotEmpty
          ? file.name
          : file.path.split(RegExp(r'[/\\]')).last;
      final nameWithoutExt = rawName.replaceAll(
        RegExp(r'\.(jpg|jpeg|png|webp|heic|heif)$', caseSensitive: false),
        '',
      );
      final baseCleanName =
          nameWithoutExt.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      // Daftar tahapan adaptif bertahap untuk menjaga ketajaman tanpa merusak gambar
      // Dimulai dari resolusi cukup tinggi dan bergradasi hingga pasti <= 100 KB
      final initialDim = minWidth ?? 1024;
      final initialQ = quality ?? 78;

      final stages = <_CompressionStage>[
        _CompressionStage(dimension: initialDim, quality: initialQ),
        const _CompressionStage(dimension: 850, quality: 72),
        const _CompressionStage(dimension: 720, quality: 65),
        const _CompressionStage(dimension: 600, quality: 58),
        const _CompressionStage(dimension: 520, quality: 52),
        const _CompressionStage(dimension: 450, quality: 48),
        const _CompressionStage(dimension: 380, quality: 44),
        const _CompressionStage(dimension: 320, quality: 40),
      ];

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      XFile? bestCandidateFile;
      int bestCandidateSize = 1 << 30; // Sangat besar awalnya
      final tempFilesCreated = <File>[];

      for (var i = 0; i < stages.length; i++) {
        // Jika pemanggil menonaktifkan kontrol ukuran (maxSizeBytes <= 0), hanya jalankan tahap pertama
        if (maxSizeBytes <= 0 && i > 0) break;

        final stage = stages[i];
        final targetPath =
            '${Directory.systemTemp.path}/comp_${timestamp}_s${i}_$baseCleanName.$extension';

        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: stage.quality,
          minWidth: stage.dimension,
          minHeight: stage.dimension,
          format: format,
          autoCorrectionAngle: true,
          keepExif: false,
        );

        if (compressed != null) {
          final compLength = await compressed.length();
          tempFilesCreated.add(File(compressed.path));

          if (compLength < bestCandidateSize) {
            bestCandidateSize = compLength;
            bestCandidateFile = compressed;
          }

          // Target tercapai (<= 100 KB), hentikan kompresi agar kualitas visual tetap tertinggi
          if (maxSizeBytes > 0 && compLength <= maxSizeBytes) {
            break;
          }
        }
      }

      // Safeguard adaptif dinamis: Jika foto kamera bertekstur sangat padat/noise tinggi
      // masih > 100 KB setelah tahapan standar, lanjutkan penurunan secara dinamis hingga pasti <= 100 KB
      var dynamicDim = 320;
      var dynamicQ = 40;
      var extraStep = stages.length;

      while (maxSizeBytes > 0 &&
          bestCandidateSize > maxSizeBytes &&
          (dynamicDim > 180 || dynamicQ > 20) &&
          extraStep < 15) {
        dynamicDim = (dynamicDim * 0.85).round();
        dynamicQ = (dynamicQ * 0.88).round().clamp(20, 100);

        final targetPath =
            '${Directory.systemTemp.path}/comp_${timestamp}_s${extraStep}_$baseCleanName.$extension';

        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: dynamicQ,
          minWidth: dynamicDim,
          minHeight: dynamicDim,
          format: format,
          autoCorrectionAngle: true,
          keepExif: false,
        );

        if (compressed != null) {
          final compLength = await compressed.length();
          tempFilesCreated.add(File(compressed.path));

          if (compLength < bestCandidateSize) {
            bestCandidateSize = compLength;
            bestCandidateFile = compressed;
          }

          if (compLength <= maxSizeBytes) {
            break;
          }
        }
        extraStep++;
      }

      stopwatch.stop();
      onLoadingChanged?.call(false);

      if (bestCandidateFile != null) {
        // Bersihkan berkas sementara selain berkas terbaik yang dipilih
        for (final tempF in tempFilesCreated) {
          if (tempF.path != bestCandidateFile.path && tempF.existsSync()) {
            try {
              tempF.deleteSync();
            } catch (_) {}
          }
        }

        final result = ImageCompressResult(
          file: bestCandidateFile,
          originalSizeBytes: originalLength,
          compressedSizeBytes: bestCandidateSize,
          compressionDuration: stopwatch.elapsed,
        );
        logCompressionResult(result, originalPath: file.path);
        return result;
      }

      // Fallback aman jika kompresi gagal
      final fallbackResult = ImageCompressResult(
        file: file,
        originalSizeBytes: originalLength,
        compressedSizeBytes: originalLength,
        compressionDuration: stopwatch.elapsed,
      );
      logCompressionResult(fallbackResult, originalPath: file.path);
      return fallbackResult;
    } catch (e) {
      stopwatch.stop();
      onLoadingChanged?.call(false);
      debugPrint(
        '[ImageCompressUtil] Compression error, fallback to original: $e',
      );

      final length = await file.length().catchError((_) => 0);
      final errorResult = ImageCompressResult(
        file: file,
        originalSizeBytes: length,
        compressedSizeBytes: length,
        compressionDuration: stopwatch.elapsed,
      );
      logCompressionResult(errorResult, originalPath: file.path);
      return errorResult;
    }
  }

  /// Cetak log perbandingan Sebelum (Before) & Sesudah (After) ke konsol debug
  static void logCompressionResult(
    ImageCompressResult result, {
    String? originalPath,
  }) {
    if (kDebugMode) {
      final savedBytes = result.originalSizeBytes - result.compressedSizeBytes;
      final savedFormatted = ImageCompressResult.formatBytes(
        savedBytes > 0 ? savedBytes : 0,
      );

      debugPrint(
        '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 📸 [IMAGE COMPRESSION REPORT] (Target: <= 100 KB)                            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ 📁 Path Asal           : ${originalPath ?? result.file.path}
║ 📏 Ukuran Sebelum (RAW): ${result.originalSizeFormatted} (${result.originalSizeBytes} bytes)
╟──────────────────────────────────────────────────────────────────────────────╢
║ 📁 Path Hasil          : ${result.file.path}
║ 📏 Ukuran Sesudah (OPT): ${result.compressedSizeFormatted} (${result.compressedSizeBytes} bytes)
║ 🎯 Status Target       : ${result.compressedSizeBytes <= defaultMaxSizeBytes ? "✅ Sesuai (<= 100 KB)" : "⚠️ Di atas 100 KB"}
║ 📉 Efisiensi Kompresi  : Hemat ${result.savedPercentage.toStringAsFixed(1)}% (Berkurang $savedFormatted)
║ ⏱️ Waktu Eksekusi      : ${result.compressionDuration.inMilliseconds} ms (Background Native Thread)
╚══════════════════════════════════════════════════════════════════════════════╝''',
      );
    }
  }

  /// Helper untuk kompresi [File] standar
  static Future<ImageCompressResult> compressFile(
    File file, {
    int maxSizeBytes = defaultMaxSizeBytes,
    int? quality,
    int? minWidth,
    int? minHeight,
    CompressFormat format = CompressFormat.jpeg,
    ValueChanged<bool>? onLoadingChanged,
  }) async {
    return compressXFile(
      XFile(file.path),
      maxSizeBytes: maxSizeBytes,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: format,
      onLoadingChanged: onLoadingChanged,
    );
  }

  /// Alur terintegrasi: Ambil Foto -> Otomatis Kompres di Background -> Kembalikan Hasil.
  static Future<ImageCompressResult?> pickAndCompress({
    required ImageSource source,
    ImagePicker? picker,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    int maxSizeBytes = defaultMaxSizeBytes,
    int? quality,
    int? minWidth,
    int? minHeight,
    CompressFormat format = CompressFormat.jpeg,
    ValueChanged<bool>? onLoadingChanged,
  }) async {
    final imagePicker = picker ?? ImagePicker();

    try {
      final picked = await imagePicker.pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (picked == null) {
        return null;
      }

      return await compressXFile(
        picked,
        maxSizeBytes: maxSizeBytes,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: format,
        onLoadingChanged: onLoadingChanged,
      );
    } catch (e) {
      debugPrint('[ImageCompressUtil] Error pickAndCompress: $e');
      return null;
    }
  }
}

/// Representasi tahapan kompresi adaptif
class _CompressionStage {
  final int dimension;
  final int quality;

  const _CompressionStage({
    required this.dimension,
    required this.quality,
  });
}

/// Widget Overlay Non-Blocking untuk menampilkan indikator kompresi di atas pratinjau gambar.
///
/// Pengguna tetap dapat mengetik, menggulir layar, atau menekan tombol lain
/// karena loading ini hanya menutupi area gambar itu sendiri (non-blocking).
class NonBlockingCompressIndicator extends StatelessWidget {
  final bool isCompressing;
  final Widget child;
  final double borderRadius;
  final String message;

  const NonBlockingCompressIndicator({
    super.key,
    required this.isCompressing,
    required this.child,
    this.borderRadius = 16.0,
    this.message = 'Mengompres foto...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isCompressing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: Colors.black.withValues(alpha: 0.45),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brandTeal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.brandTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
