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
  /// Memeriksa apakah aplikasi sedang berjalan dalam mode testing
  static bool get isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Melakukan kompresi terhadap berkas [XFile] di background thread.
  ///
  /// - [file]: Berkas input dari kamera / galeri.
  /// - [quality]: Kualitas output (0-100), default 75 (sangat seimbang untuk dokumen & foto absensi).
  /// - [minWidth] & [minHeight]: Resolusi maksimal gambar (default 1280x1280).
  /// - [format]: Format output (JPEG, WebP, PNG).
  /// - [onLoadingChanged]: Callback non-blocking untuk memperbarui status loading di UI.
  static Future<ImageCompressResult> compressXFile(
    XFile file, {
    int quality = 75,
    int minWidth = 1280,
    int minHeight = 1280,
    CompressFormat format = CompressFormat.jpeg,
    ValueChanged<bool>? onLoadingChanged,
  }) async {
    final stopwatch = Stopwatch()..start();
    onLoadingChanged?.call(true);

    try {
      final originalLength = await file.length();

      // Jika dijalankan di unit test atau platform tanpa native codec, fallback aman ke original file
      if (isTestEnvironment) {
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

      // Buat path target unik di folder temp sistem
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = format == CompressFormat.webp ? 'webp' : 'jpg';
      final targetPath =
          '${Directory.systemTemp.path}/compressed_${timestamp}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '_')}';
      final cleanTargetPath = targetPath.endsWith('.$extension')
          ? targetPath
          : '$targetPath.$extension';

      // flutter_image_compress mengeksekusi kompresi di native background thread
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        cleanTargetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: format,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      stopwatch.stop();
      onLoadingChanged?.call(false);

      if (compressedXFile != null) {
        final compressedLength = await compressedXFile.length();
        final result = ImageCompressResult(
          file: compressedXFile,
          originalSizeBytes: originalLength,
          compressedSizeBytes: compressedLength,
          compressionDuration: stopwatch.elapsed,
        );
        logCompressionResult(result, originalPath: file.path);
        return result;
      }

      // Fallback jika kompresi mengembalikan null
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
║ 📸 [IMAGE COMPRESSION REPORT]                                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ 📁 Path Asal           : ${originalPath ?? result.file.path}
║ 📏 Ukuran Sebelum (RAW): ${result.originalSizeFormatted} (${result.originalSizeBytes} bytes)
╟──────────────────────────────────────────────────────────────────────────────╢
║ 📁 Path Hasil          : ${result.file.path}
║ 📏 Ukuran Sesudah (OPT): ${result.compressedSizeFormatted} (${result.compressedSizeBytes} bytes)
║ 📉 Efisiensi Kompresi  : Hemat ${result.savedPercentage.toStringAsFixed(1)}% (Berkurang $savedFormatted)
║ ⏱️ Waktu Eksekusi      : ${result.compressionDuration.inMilliseconds} ms (Background Native Thread)
╚══════════════════════════════════════════════════════════════════════════════╝''',
      );
    }
  }

  /// Helper untuk kompresi [File] standar
  static Future<ImageCompressResult> compressFile(
    File file, {
    int quality = 75,
    int minWidth = 1280,
    int minHeight = 1280,
    CompressFormat format = CompressFormat.jpeg,
    ValueChanged<bool>? onLoadingChanged,
  }) async {
    return compressXFile(
      XFile(file.path),
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: format,
      onLoadingChanged: onLoadingChanged,
    );
  }

  /// Alur terintegrasi: Ambil Foto -> Otomatis Kompres di Background -> Kembalikan Hasil.
  ///
  /// Menyediakan pemanggilan yang sangat ringkas untuk:
  /// - Absen selfie / face attendance
  /// - Unggah bukti aktivitas
  /// - Unggah foto profil karyawan
  ///
  /// Penggunaan:
  /// ```dart
  /// final result = await ImageCompressUtil.pickAndCompress(
  ///   source: ImageSource.camera,
  ///   onLoadingChanged: (isCompressing) => setState(() => _isCompressing = isCompressing),
  /// );
  /// if (result != null) {
  ///   setState(() => _photo = result.file);
  /// }
  /// ```
  static Future<ImageCompressResult?> pickAndCompress({
    required ImageSource source,
    ImagePicker? picker,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    int quality = 75,
    int minWidth = 1280,
    int minHeight = 1280,
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
