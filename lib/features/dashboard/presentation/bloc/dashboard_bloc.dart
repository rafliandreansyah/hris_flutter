import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/dashboard/data/models/dashboard_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:hris_flutter/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:hris_flutter/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:hris_flutter/features/dashboard/presentation/bloc/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;
  final AuthRepository _authRepository;
  Timer? _timer;
  Duration _serverTimeOffset = Duration.zero;

  DashboardBloc({
    DashboardRepository? dashboardRepository,
    AuthRepository? authRepository,
  }) : _dashboardRepository = dashboardRepository ?? DashboardRepositoryImpl(),
       _authRepository = authRepository ?? AuthRepositoryImpl(),
       super(const DashboardInitial()) {
    on<DashboardFetchRequested>(_onFetchRequested);
    on<DashboardTimerTicked>(_onTimerTicked);
  }

  Future<void> _onFetchRequested(
    DashboardFetchRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (!event.isRefresh && state is! DashboardLoaded) {
      emit(const DashboardLoading());
    }

    try {
      final results = await Future.wait([
        _dashboardRepository.getDashboardData(),
        _dashboardRepository.getMenus(),
        _authRepository
            .getProfile()
            .then<UserProfileData?>((p) => p)
            .catchError((_) => null),
      ]);

      final dashboardData = results[0] as DashboardData;
      final menus = results[1] as List<MenuItemModel>;
      final userProfile = results[2] as UserProfileData?;

      // 1. Hitung selisih waktu server dengan waktu lokal (Zero Time Drift)
      DateTime serverTime = DateTime.now();
      if (dashboardData.timeServer != null &&
          dashboardData.timeServer!.isNotEmpty) {
        serverTime =
            DateTime.tryParse(dashboardData.timeServer!) ?? DateTime.now();
      }
      _serverTimeOffset = serverTime.difference(DateTime.now());

      // 2. Mulai timer realtime 1 detik
      _startClockTimer();

      final currentServerTime = DateTime.now().add(_serverTimeOffset);

      emit(
        DashboardLoaded(
          dashboardData: dashboardData,
          menus: menus,
          currentServerTime: currentServerTime,
          userProfile: userProfile,
        ),
      );
    } on ApiException catch (e) {
      emit(DashboardError(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(DashboardError(message: 'Terjadi kesalahan: $e'));
    }
  }

  void _onTimerTicked(
    DashboardTimerTicked event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(currentServerTime: event.currentServerTime));
    }
  }

  void _startClockTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentRealtime = DateTime.now().add(_serverTimeOffset);
      add(DashboardTimerTicked(currentRealtime));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
