import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';

abstract class LiveTrackingEvent extends Equatable {
  const LiveTrackingEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal saat halaman Live Tracking dibuka
class LiveTrackingStarted extends LiveTrackingEvent {
  final bool activeOnly;

  const LiveTrackingStarted({this.activeOnly = true});

  @override
  List<Object?> get props => [activeOnly];
}

/// Refresh manual atau polling periodik 30 detik
class LiveTrackingRefreshed extends LiveTrackingEvent {
  final bool isSilent;

  const LiveTrackingRefreshed({this.isSilent = false});

  @override
  List<Object?> get props => [isSilent];
}

/// Pergantian filter perusahaan, departemen, atau status sesi
class LiveTrackingFilterChanged extends LiveTrackingEvent {
  final String? companyId;
  final String? departmentId;
  final String? status;
  final bool? activeOnly;

  const LiveTrackingFilterChanged({
    this.companyId,
    this.departmentId,
    this.status,
    this.activeOnly,
  });

  @override
  List<Object?> get props => [companyId, departmentId, status, activeOnly];
}

/// Pencarian nama atau NIK karyawan
class LiveTrackingSearchQueryChanged extends LiveTrackingEvent {
  final String query;

  const LiveTrackingSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Memilih karyawan tertentu di peta untuk memunculkan detail bottom card
class LiveTrackingEmployeeSelected extends LiveTrackingEvent {
  final LiveEmployeeLocation? employee;

  const LiveTrackingEmployeeSelected(this.employee);

  @override
  List<Object?> get props => [employee];
}

/// Mengambil riwayat jejak rute GPS (polyline) untuk karyawan terpilih
class LiveTrackingRouteRequested extends LiveTrackingEvent {
  final String sourceType;
  final String referenceId;
  final String? employeeId;

  const LiveTrackingRouteRequested({
    required this.sourceType,
    required this.referenceId,
    this.employeeId,
  });

  @override
  List<Object?> get props => [sourceType, referenceId, employeeId];
}
