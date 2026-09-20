import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
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
  final UserProfileData? userProfile;

  const DashboardLoaded({
    required this.dashboardData,
    required this.menus,
    required this.currentServerTime,
    this.userProfile,
  });

  DashboardLoaded copyWith({
    DashboardData? dashboardData,
    List<MenuItemModel>? menus,
    DateTime? currentServerTime,
    UserProfileData? userProfile,
  }) {
    return DashboardLoaded(
      dashboardData: dashboardData ?? this.dashboardData,
      menus: menus ?? this.menus,
      currentServerTime: currentServerTime ?? this.currentServerTime,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  @override
  List<Object?> get props => [dashboardData, menus, currentServerTime, userProfile];
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

/// State ketika perangkat fisik saat ini tidak cocok dengan perangkat terdaftar
/// atau data perangkat di server belum terdaftar/kosong.
class DashboardDeviceMismatch extends DashboardState {
  final String message;
  final String registeredDeviceId;
  final String currentDeviceId;

  const DashboardDeviceMismatch({
    this.message =
        'Akun Anda terdaftar pada perangkat lain. Demi keamanan akun, Anda telah dikeluarkan secara otomatis.',
    required this.registeredDeviceId,
    required this.currentDeviceId,
  });

  @override
  List<Object?> get props => [message, registeredDeviceId, currentDeviceId];
}
