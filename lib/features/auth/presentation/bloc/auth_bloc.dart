import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/services/notification_service.dart';
import 'package:hris_flutter/core/utils/device_info_util.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:hris_flutter/features/auth/presentation/bloc/auth_state.dart';

/// BLoC untuk mengelola State autentikasi login, session check, dan logout
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final NotificationService _notificationService;

  AuthBloc({
    AuthRepository? authRepository,
    NotificationService? notificationService,
  })  : _authRepository = authRepository ?? AuthRepositoryImpl(),
        _notificationService = notificationService ?? NotificationService.instance,
        super(const AuthInitial()) {
    on<AuthCheckSessionRequested>(_onCheckSessionRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckSessionRequested(
    AuthCheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _authRepository.getSavedToken();
      if (token != null && token.isNotEmpty) {
        emit(AuthSuccess(token: token, message: 'Sesi aktif ditemukan'));
      } else {
        emit(const AuthInitial());
      }
    } catch (_) {
      emit(const AuthInitial());
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // 1. Ambil FCM Token & Info Perangkat secara asinkron
      final fcmTokenFuture = _notificationService.getFcmToken();
      final deviceInfoFuture = DeviceInfoUtil.getDeviceInfo();

      final results = await Future.wait([fcmTokenFuture, deviceInfoFuture]);
      final fcmToken = results[0] as String?;
      final deviceInfo = results[1] as DeviceInfoData;

      // 2. Susun payload request login lengkap
      final request = LoginRequestModel.withDeviceInfo(
        email: event.email.trim(),
        password: event.password,
        deviceInfo: deviceInfo,
        fcmToken: fcmToken,
      );

      // 3. Panggil API repository (otomatis simpan token ke secure storage)
      final response = await _authRepository.login(request);

      emit(AuthSuccess(token: response.token));
    } on ApiException catch (e) {
      emit(AuthFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      emit(AuthFailure(message: 'Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
    } catch (_) {}
    emit(const AuthInitial());
  }
}
