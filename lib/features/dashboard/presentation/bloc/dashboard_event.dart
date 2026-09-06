import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memicu pengambilan data dashboard dan daftar menu
class DashboardFetchRequested extends DashboardEvent {
  final bool isRefresh;

  const DashboardFetchRequested({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Event tick waktu realtime setiap detik berdasarkan sinkronisasi jam server
class DashboardTimerTicked extends DashboardEvent {
  final DateTime currentServerTime;

  const DashboardTimerTicked(this.currentServerTime);

  @override
  List<Object?> get props => [currentServerTime];
}
