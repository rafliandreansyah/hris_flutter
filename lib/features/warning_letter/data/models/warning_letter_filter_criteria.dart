import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Kriteria filter untuk daftar surat peringatan.
class WarningLetterFilterCriteria extends Equatable {
  final DateTimeRange? dateRange;
  final String? letterTypeId;
  final String? letterTypeName;
  final String status;

  const WarningLetterFilterCriteria({
    this.dateRange,
    this.letterTypeId,
    this.letterTypeName,
    this.status = 'all',
  });

  bool get hasActiveFilter =>
      dateRange != null ||
      (letterTypeId != null && letterTypeId!.isNotEmpty) ||
      (status.isNotEmpty && status != 'all');

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if (letterTypeId != null && letterTypeId!.isNotEmpty) count++;
    if (status.isNotEmpty && status != 'all') count++;
    return count;
  }

  WarningLetterFilterCriteria copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? letterTypeId,
    bool clearLetterType = false,
    String? letterTypeName,
    String? status,
  }) {
    return WarningLetterFilterCriteria(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      letterTypeId: clearLetterType ? null : (letterTypeId ?? this.letterTypeId),
      letterTypeName:
          clearLetterType ? null : (letterTypeName ?? this.letterTypeName),
      status: status ?? this.status,
    );
  }

  /// Format 'yyyy-MM-dd' untuk query parameter API
  String? get startDateParam {
    final start = dateRange?.start;
    if (start == null) return null;
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  /// Format 'yyyy-MM-dd' untuk query parameter API
  String? get endDateParam {
    final end = dateRange?.end;
    if (end == null) return null;
    return '${end.year.toString().padLeft(4, '0')}-'
        '${end.month.toString().padLeft(2, '0')}-'
        '${end.day.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [dateRange, letterTypeId, letterTypeName, status];
}
