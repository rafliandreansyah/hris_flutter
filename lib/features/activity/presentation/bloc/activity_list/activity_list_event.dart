import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:hris_flutter/features/activity/presentation/widgets/activity_filter_bottom_sheet.dart';

abstract class ActivityListEvent extends Equatable {
  const ActivityListEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman pertama kali dibuka atau diinisialisasi dengan custom data
class ActivityListStarted extends ActivityListEvent {
  final List<ActivityItem>? customActivities;

  const ActivityListStarted({this.customActivities});

  @override
  List<Object?> get props => [customActivities];
}

/// Event saat tab berpindah (0: Aktivitasku, 1: Aktivitas Tim/Pegawai Lain)
class ActivityListTabChanged extends ActivityListEvent {
  final int tabIndex;

  const ActivityListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

/// Event pemuatan data aktivitas (pull to refresh atau fetch awal)
class ActivityListFetchRequested extends ActivityListEvent {
  final bool isRefresh;
  final bool isTeam;

  const ActivityListFetchRequested({
    this.isRefresh = false,
    required this.isTeam,
  });

  @override
  List<Object?> get props => [isRefresh, isTeam];
}

/// Event infinite scroll pagination untuk memuat halaman berikutnya
class ActivityListLoadMoreRequested extends ActivityListEvent {
  final bool isTeam;

  const ActivityListLoadMoreRequested({required this.isTeam});

  @override
  List<Object?> get props => [isTeam];
}

/// Event pencarian kata kunci dengan debouncing
class ActivityListSearchChanged extends ActivityListEvent {
  final String query;

  const ActivityListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event penerapan kriteria filter (status, tanggal, organisasi)
class ActivityListFilterApplied extends ActivityListEvent {
  final ActivityFilterCriteria criteria;

  const ActivityListFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

/// Event penambahan aktivitas baru setelah pembuatan berhasil
class ActivityListActivityAdded extends ActivityListEvent {
  final ActivityItem activity;

  const ActivityListActivityAdded(this.activity);

  @override
  List<Object?> get props => [activity];
}
