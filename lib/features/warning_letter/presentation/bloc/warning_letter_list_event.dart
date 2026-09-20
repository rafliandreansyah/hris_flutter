import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_filter_criteria.dart';

abstract class WarningLetterListEvent extends Equatable {
  const WarningLetterListEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman pertama kali dibuka, memuat My Letters, Team Letters, dan Tipe SP.
class WarningLetterListStarted extends WarningLetterListEvent {
  const WarningLetterListStarted();
}

/// Event saat user berpindah tab (0: Surat Diterima, 1: Diterbitkan).
class WarningLetterListTabChanged extends WarningLetterListEvent {
  final int tabIndex;

  const WarningLetterListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

/// Event saat query pencarian diubah.
class WarningLetterListSearchChanged extends WarningLetterListEvent {
  final String query;

  const WarningLetterListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event saat filter kriteria baru diterapkan.
class WarningLetterListFilterApplied extends WarningLetterListEvent {
  final WarningLetterFilterCriteria filterCriteria;

  const WarningLetterListFilterApplied(this.filterCriteria);

  @override
  List<Object?> get props => [filterCriteria];
}

/// Event untuk me-refresh data tab tertentu.
class WarningLetterListFetchRequested extends WarningLetterListEvent {
  final bool isRefresh;
  final bool isTeam;

  const WarningLetterListFetchRequested({
    this.isRefresh = false,
    required this.isTeam,
  });

  @override
  List<Object?> get props => [isRefresh, isTeam];
}

/// Event untuk memuat halaman berikutnya (infinite scroll).
class WarningLetterListLoadMoreRequested extends WarningLetterListEvent {
  final bool isTeam;

  const WarningLetterListLoadMoreRequested({required this.isTeam});

  @override
  List<Object?> get props => [isTeam];
}
