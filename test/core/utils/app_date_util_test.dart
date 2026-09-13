import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';

void main() {
  group('AppDateUtil', () {
    group('formatTimeHHmm', () {
      test('returns fallback for null, empty, or placeholder inputs', () {
        expect(AppDateUtil.formatTimeHHmm(null), equals('--:--'));
        expect(AppDateUtil.formatTimeHHmm(''), equals('--:--'));
        expect(AppDateUtil.formatTimeHHmm('   '), equals('--:--'));
        expect(AppDateUtil.formatTimeHHmm('--:--'), equals('--:--'));
        expect(AppDateUtil.formatTimeHHmm('-'), equals('--:--'));
        expect(AppDateUtil.formatTimeHHmm(null, fallback: '-'), equals('-'));
      });

      test('formats standard 24h time strings (HH:mm and HH:mm:ss)', () {
        expect(AppDateUtil.formatTimeHHmm('08:30'), equals('08:30'));
        expect(AppDateUtil.formatTimeHHmm('08:30:00'), equals('08:30'));
        expect(AppDateUtil.formatTimeHHmm('17:45:59'), equals('17:45'));
        expect(AppDateUtil.formatTimeHHmm('00:00:00'), equals('00:00'));
      });

      test('formats single-digit hour time strings', () {
        expect(AppDateUtil.formatTimeHHmm('8:30'), equals('08:30'));
        expect(AppDateUtil.formatTimeHHmm('8:05:00'), equals('08:05'));
        expect(AppDateUtil.formatTimeHHmm('9:00'), equals('09:00'));
      });

      test('formats 12-hour AM/PM time strings into 24-hour format', () {
        expect(AppDateUtil.formatTimeHHmm('08:30 AM'), equals('08:30'));
        expect(AppDateUtil.formatTimeHHmm('08:30 PM'), equals('20:30'));
        expect(AppDateUtil.formatTimeHHmm('1:15 PM'), equals('13:15'));
      });

      test('formats ISO 8601 strings and handles local conversion', () {
        final parsed = AppDateUtil.formatTimeHHmm('2026-09-09T08:30:00');
        expect(parsed, isNotEmpty);
        expect(parsed.length, equals(5));
        expect(parsed.contains(':'), isTrue);

        final utcParsed = AppDateUtil.formatTimeHHmm('2026-09-09T05:30:00.000Z');
        expect(utcParsed, isNotEmpty);
        expect(utcParsed.length, equals(5));
        expect(utcParsed.contains(':'), isTrue);
      });

      test('returns fallback for completely invalid strings', () {
        expect(AppDateUtil.formatTimeHHmm('invalid_time'), equals('--:--'));
        expect(AppDateUtil.formatTimeHHmm('abc:def'), equals('--:--'));
      });
    });

    group('formatTimeWithSeconds', () {
      test('formats DateTime into HH:mm:ss format', () {
        final dt = DateTime(2026, 9, 13, 8, 5, 9);
        expect(AppDateUtil.formatTimeWithSeconds(dt), equals('08:05:09'));
      });
    });

    group('formatDateIso', () {
      test('formats DateTime into yyyy-MM-dd format', () {
        final dt = DateTime(2026, 9, 13);
        expect(AppDateUtil.formatDateIso(dt), equals('2026-09-13'));
      });
    });

    group('tryParseDateTime', () {
      test('safely parses valid ISO dates to local DateTime', () {
        final dt = AppDateUtil.tryParseDateTime('2026-09-13T10:00:00.000Z');
        expect(dt, isNotNull);
        expect(dt!.isUtc, isFalse);
      });

      test('returns null for invalid or null inputs', () {
        expect(AppDateUtil.tryParseDateTime(null), isNull);
        expect(AppDateUtil.tryParseDateTime(''), isNull);
        expect(AppDateUtil.tryParseDateTime('not-a-date'), isNull);
      });
    });
  });
}
