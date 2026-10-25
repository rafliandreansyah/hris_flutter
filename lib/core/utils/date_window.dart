import 'package:hris_flutter/features/submission_setting/data/models/submission_setting_model.dart';

/// Rentang tanggal untuk `showDatePicker`.
class PickerRange {
  final DateTime first;
  final DateTime last;
  const PickerRange(this.first, this.last);

  /// Menjepit [date] agar selalu berada dalam rentang (mencegah assert `initialDate` di luar range).
  DateTime clamp(DateTime date) {
    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Menggabungkan batas dari perusahaan ([window]) dengan batas bawaan form.
///
/// - Jika [window] null atau bebas, rentang bawaan form ([fallbackFirst] .. [fallbackLast]) dipakai.
/// - Jika dibatasi, rentangnya adalah irisan dengan [minFloor] / [maxCeil] milik form
///   (mis. presensi tidak boleh di masa depan, resign tidak boleh di masa lalu).
/// - Bila irisan kosong, hasil dipaksa valid (`last == first`) agar picker tidak crash.
PickerRange resolvePickerRange(
  DateWindowModel? window, {
  required DateTime fallbackFirst,
  required DateTime fallbackLast,
  DateTime? minFloor,
  DateTime? maxCeil,
}) {
  var first = fallbackFirst;
  var last = fallbackLast;

  if (window != null && !window.isUnlimited) {
    if (window.minDate != null) first = window.minDate!;
    if (window.maxDate != null) last = window.maxDate!;
  }

  if (minFloor != null && first.isBefore(minFloor)) first = minFloor;
  if (maxCeil != null && last.isAfter(maxCeil)) last = maxCeil;

  first = _dateOnly(first);
  last = _dateOnly(last);
  if (last.isBefore(first)) last = first;
  return PickerRange(first, last);
}
