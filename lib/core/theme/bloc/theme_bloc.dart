import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'theme_event.dart';
import 'theme_state.dart';

export 'theme_event.dart';
export 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SecureStorageService _storageService;

  ThemeBloc({
    SecureStorageService? storageService,
    ThemeMode initialThemeMode = ThemeMode.system,
  })  : _storageService = storageService ?? SecureStorageService.instance,
        super(ThemeState(themeMode: initialThemeMode)) {
    on<ThemeStarted>(_onStarted);
    on<ThemeChanged>(_onChanged);
  }

  Future<void> _onStarted(
    ThemeStarted event,
    Emitter<ThemeState> emit,
  ) async {
    final saved = await _storageService.getThemeMode();
    final mode = _mapStringToThemeMode(saved);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> _onChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      await _storageService.saveThemeMode(_mapThemeModeToString(event.themeMode));
      emit(state.copyWith(
        themeMode: event.themeMode,
        successMessage: 'Theme changed successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  static ThemeMode _mapStringToThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _mapThemeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
