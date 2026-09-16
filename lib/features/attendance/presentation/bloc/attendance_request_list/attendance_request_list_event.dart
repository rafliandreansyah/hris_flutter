import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_filter_bottom_sheet.dart';

abstract class AttendanceRequestListEvent extends Equatable {
  const AttendanceRequestListEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman pertama kali dibuka:
/// memuat daftar pengajuan milik sendiri (Tab 0) dan tim (Tab 1).
class AttendanceRequestListStarted extends AttendanceRequestListEvent {
  const AttendanceRequestListStarted();
}

/// Meminta fetch/refresh data untuk tab yang ditentukan (`isTeam`).
class AttendanceRequestListFetchRequested extends AttendanceRequestListEvent {
  final bool isRefresh;
  final bool isTeam;

  const AttendanceRequestListFetchRequested({
    this.isRefresh = false,
    required this.isTeam,
  });

  @override
  List<Object?> get props => [isRefresh, isTeam];
}

/// Memuat halaman berikutnya (infinite scroll).
class AttendanceRequestListLoadMoreRequested
    extends AttendanceRequestListEvent {
  final bool isTeam;

  const AttendanceRequestListLoadMoreRequested({required this.isTeam});

  @override
  List<Object?> get props => [isTeam];
}

/// Berpindah tab antara Tab 0 (Pengajuan Saya) dan Tab 1 (Persetujuan Tim).
class AttendanceRequestListTabChanged extends AttendanceRequestListEvent {
  final int tabIndex;

  const AttendanceRequestListTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

/// Mengubah teks pencarian (search bar dinamis pada tab tim).
class AttendanceRequestListSearchChanged extends AttendanceRequestListEvent {
  final String query;

  const AttendanceRequestListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Menerapkan kriteria filter baru dari bottom sheet.
class AttendanceRequestListFilterApplied extends AttendanceRequestListEvent {
  final AttendanceRequestFilterCriteria criteria;

  const AttendanceRequestListFilterApplied(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

/// Mereset kriteria filter ke kondisi awal.
class AttendanceRequestListFilterReset extends AttendanceRequestListEvent {
  const AttendanceRequestListFilterReset();
}
