import 'package:intl/intl.dart';

/// Utility terpusat untuk parsing dan formatting tanggal & waktu di aplikasi Oasish HRIS.
///
/// Memastikan seluruh pemformatan waktu mengikuti kaidah standar `package:intl` (`DateFormat`),
/// menghindari pemotongan string manual (`substring`), regex parsial (`RegExp`), atau `padLeft` manual.
class AppDateUtil {
  AppDateUtil._();

  static final DateFormat _timeFormatHHmm = DateFormat('HH:mm');
  static final DateFormat _timeFormatHHmmss = DateFormat('HH:mm:ss');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Format string waktu atau tanggal-waktu menjadi representasi 24 jam "HH:mm" (contoh: "08:30").
  ///
  /// Menerima berbagai format masukan dari API atau user input:
  /// - ISO 8601 UTC (contoh: `"2026-09-09T05:40:52.171Z"`) -> otomatis dikonversi ke waktu lokal user (`.toLocal()`)
  /// - SQL Datetime (contoh: `"2026-09-09 08:30:00"`)
  /// - Format waktu 24 jam dengan/tanpa detik (contoh: `"08:30:00"`, `"08:30"`)
  /// - Format waktu tanpa zero-padding (contoh: `"8:30"`, `"8:5"`)
  /// - Format waktu 12 jam AM/PM (contoh: `"08:30 AM"`, `"08:30 PM"`) -> dikonversi ke format 24 jam (misal `"20:30"`)
  ///
  /// Mengembalikan [fallback] (default: `"--:--"`) jika masukan bernilai null, kosong, atau tidak valid.
  static String formatTimeHHmm(String? timeStr, {String fallback = '--:--'}) {
    if (timeStr == null) return fallback;
    final trimmed = timeStr.trim();
    if (trimmed.isEmpty || trimmed == '--:--' || trimmed == '-') {
      return fallback;
    }

    // 1. Coba parse sebagai DateTime lengkap (ISO 8601 / ISO string dengan offset / SQL string)
    final parsedDt = DateTime.tryParse(trimmed);
    if (parsedDt != null) {
      return _timeFormatHHmm.format(parsedDt.toLocal());
    }

    // 2. Coba parse menggunakan berbagai pola waktu DateFormat
    const patterns = [
      'HH:mm:ss',
      'HH:mm',
      'h:mm:ss a',
      'h:mm a',
      'H:mm:ss',
      'H:mm',
    ];

    for (final pattern in patterns) {
      try {
        final parsed = DateFormat(pattern).parseLoose(trimmed);
        return _timeFormatHHmm.format(parsed);
      } catch (_) {}
    }

    // 3. Fallback: pasang tanggal dummy 1970-01-01 untuk parsing format ISO time (misal "08:30:00.000Z")
    final isoTimeDt = DateTime.tryParse('1970-01-01T$trimmed');
    if (isoTimeDt != null) {
      return _timeFormatHHmm.format(isoTimeDt.toLocal());
    }

    return fallback;
  }

  /// Format objek [DateTime] menjadi string jam 24-jam dengan detik "HH:mm:ss" (contoh: "08:30:45").
  static String formatTimeWithSeconds(DateTime dt) {
    return _timeFormatHHmmss.format(dt);
  }

  /// Format objek [DateTime] menjadi string jam "HH:mm" (contoh: "08:30").
  static String formatDateTimeHHmm(DateTime dt) {
    return _timeFormatHHmm.format(dt);
  }

  /// Format objek [DateTime] menjadi format ISO "yyyy-MM-dd" (contoh: "2026-09-09").
  static String formatDateIso(DateTime dt) {
    return _isoDateFormat.format(dt);
  }

  /// Format objek [DateTime] menjadi nama hari & tanggal lengkap (contoh: "Kamis, 9 September 2026").
  static String formatDateFull(DateTime dt, {String? locale}) {
    return DateFormat('EEEE, d MMMM yyyy', locale).format(dt);
  }

  /// Format objek [DateTime] menjadi nama hari & tanggal singkat (contoh: "Kamis, 9 Sep").
  static String formatDateMedium(DateTime dt, {String? locale}) {
    return DateFormat('EEEE, d MMM', locale).format(dt);
  }

  /// Format objek [DateTime] menjadi tanggal singkat (contoh: "09 Sep 2026").
  static String formatDateShort(DateTime dt, {String? locale}) {
    return DateFormat('dd MMM yyyy', locale).format(dt);
  }

  /// Parsing string tanggal atau ISO 8601 ke objek [DateTime] lokal secara aman.
  static DateTime? tryParseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(dateStr.trim());
    return parsed?.toLocal();
  }
}
