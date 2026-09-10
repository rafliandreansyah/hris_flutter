import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/leave/presentation/widgets/leave_filter_bottom_sheet.dart';

abstract class LeaveListEvent extends Equatable {
  const LeaveListEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman Leave & Time Off pertama kali dibuka.
class LeaveListStarted extends LeaveListEvent {
  const LeaveListStarted();
}

/// Event saat tab berpindah (0: My Requests, 1: Team Requests).
class LeaveListTabChanged extends LeaveListEvent {
  final int tabIndex;

  const LeaveListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

/// Event pemuatan data (pull to refresh atau fetch awal).
/// `isTeam: false` = My Requests (approver=false),
/// `isTeam: true` = Team Requests (approver=true, bisa 403).
class LeaveListFetchRequested extends LeaveListEvent {
  final bool isRefresh;
  final bool isTeam;

  const LeaveListFetchRequested({
    this.isRefresh = false,
    required this.isTeam,
  });

  @override
  List<Object?> get props => [isRefresh, isTeam];
}

/// Event infinite scroll pagination untuk memuat halaman berikutnya.
class LeaveListLoadMoreRequested extends LeaveListEvent {
  final bool isTeam;

  const LeaveListLoadMoreRequested({required this.isTeam});

  @override
  List<Object?> get props => [isTeam];
}

/// Event pencarian kata kunci (dipanggil setelah debounce di UI layer).
class LeaveListSearchChanged extends LeaveListEvent {
  final String query;

  const LeaveListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event penerapan kriteria filter dari bottom sheet.
class LeaveListFilterApplied extends LeaveListEvent {
  final LeaveFilterCriteria criteria;

  const LeaveListFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

/// Event reset seluruh kriteria filter ke default.
class LeaveListFilterReset extends LeaveListEvent {
  const LeaveListFilterReset();
}
