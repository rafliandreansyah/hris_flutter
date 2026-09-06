import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData dashboardData;
  final List<MenuItemModel> menus;
  final DateTime currentServerTime;

  const DashboardLoaded({
    required this.dashboardData,
    required this.menus,
    required this.currentServerTime,
  });

  DashboardLoaded copyWith({
    DashboardData? dashboardData,
    List<MenuItemModel>? menus,
    DateTime? currentServerTime,
  }) {
    return DashboardLoaded(
      dashboardData: dashboardData ?? this.dashboardData,
      menus: menus ?? this.menus,
      currentServerTime: currentServerTime ?? this.currentServerTime,
    );
  }

  @override
  List<Object?> get props => [dashboardData, menus, currentServerTime];
}

class DashboardError extends DashboardState {
  final String message;
  final int? statusCode;

  const DashboardError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
