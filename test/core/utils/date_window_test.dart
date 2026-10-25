import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/date_window.dart';
import 'package:hris_flutter/features/submission_setting/data/models/submission_setting_model.dart';

void main() {
  final fallbackFirst = DateTime(2026, 1, 1);
  final fallbackLast = DateTime(2026, 12, 31);

  group('resolvePickerRange', () {
    test('tanpa setelan / bebas memakai rentang bawaan form', () {
      final a = resolvePickerRange(null, fallbackFirst: fallbackFirst, fallbackLast: fallbackLast);
      expect(a.first, fallbackFirst);
      expect(a.last, fallbackLast);

      final b = resolvePickerRange(
        const DateWindowModel(isUnlimited: true),
        fallbackFirst: fallbackFirst,
        fallbackLast: fallbackLast,
      );
      expect(b.first, fallbackFirst);
      expect(b.last, fallbackLast);
    });

    test('dibatasi: memakai minDate/maxDate dari perusahaan', () {
      final r = resolvePickerRange(
        DateWindowModel(
          isUnlimited: false,
          minDate: DateTime(2026, 10, 11),
          maxDate: DateTime(2026, 11, 8),
        ),
        fallbackFirst: fallbackFirst,
        fallbackLast: fallbackLast,
      );
      expect(r.first, DateTime(2026, 10, 11));
      expect(r.last, DateTime(2026, 11, 8));
    });

    test('irisan dengan minFloor / maxCeil milik form (presensi tidak boleh masa depan)', () {
      final w = DateWindowModel(
        isUnlimited: false,
        minDate: DateTime(2026, 10, 11),
        maxDate: DateTime(2026, 11, 8),
      );
      final r = resolvePickerRange(
        w,
        fallbackFirst: fallbackFirst,
        fallbackLast: fallbackLast,
        maxCeil: DateTime(2026, 10, 25),
      );
      expect(r.last, DateTime(2026, 10, 25));

      final resign = resolvePickerRange(
        w,
        fallbackFirst: fallbackFirst,
        fallbackLast: fallbackLast,
        minFloor: DateTime(2026, 10, 25),
      );
      expect(resign.first, DateTime(2026, 10, 25));
    });

    test('irisan kosong dipaksa valid agar showDatePicker tidak assert', () {
      final r = resolvePickerRange(
        DateWindowModel(
          isUnlimited: false,
          minDate: DateTime(2026, 10, 11),
          maxDate: DateTime(2026, 10, 12),
        ),
        fallbackFirst: fallbackFirst,
        fallbackLast: fallbackLast,
        minFloor: DateTime(2026, 12, 1),
      );
      expect(r.last.isBefore(r.first), isFalse);
    });

    test('clamp menjepit initialDate ke dalam rentang', () {
      final r = PickerRange(DateTime(2026, 10, 11), DateTime(2026, 11, 8));
      expect(r.clamp(DateTime(2026, 1, 1)), DateTime(2026, 10, 11));
      expect(r.clamp(DateTime(2027, 1, 1)), DateTime(2026, 11, 8));
      expect(r.clamp(DateTime(2026, 10, 20)), DateTime(2026, 10, 20));
    });
  });
}
