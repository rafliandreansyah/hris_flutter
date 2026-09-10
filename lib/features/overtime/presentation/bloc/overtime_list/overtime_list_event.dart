import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/overtime/presentation/widgets/overtime_filter_bottom_sheet.dart';

abstract class OvertimeListEvent extends Equatable {
  const OvertimeListEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman Overtime Requests pertama kali dibuka.
class OvertimeListStarted extends OvertimeListEvent {
  const OvertimeListStarted();
}

/// Event saat tab berpindah (0: My Overtime, 1: Team Overtime).
class OvertimeListTabChanged extends OvertimeListEvent {
  final int tabIndex;

  const OvertimeListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

/// Event pemuatan data (pull to refresh atau fetch awal).
/// `isTeam: false` = My Overtime (approver=false),
/// `isTeam: true` = Team Overtime (approver=true, bisa 403).
class OvertimeListFetchRequested extends OvertimeListEvent {
  final bool isRefresh;
  final bool isTeam;

  const OvertimeListFetchRequested({
    this.isRefresh = false,
    required this.isTeam,
  });

  @override
  List<Object?> get props => [isRefresh, isTeam];
}

/// Event infinite scroll pagination untuk memuat halaman berikutnya.
class OvertimeListLoadMoreRequested extends OvertimeListEvent {
  final bool isTeam;

  const OvertimeListLoadMoreRequested({required this.isTeam});

  @override
  List<Object?> get props => [isTeam];
}

/// Event pencarian kata kunci (dipanggil setelah debounce di UI layer).
class OvertimeListSearchChanged extends OvertimeListEvent {
  final String query;

  const OvertimeListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event penerapan kriteria filter dari bottom sheet.
class OvertimeListFilterApplied extends OvertimeListEvent {
  final OvertimeFilterCriteria criteria;

  const OvertimeListFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

/// Event reset seluruh kriteria filter ke default.
class OvertimeListFilterReset extends OvertimeListEvent {
  const OvertimeListFilterReset();
}
