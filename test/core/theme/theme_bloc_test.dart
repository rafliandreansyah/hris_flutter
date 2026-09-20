import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/theme/bloc/theme_bloc.dart';

class MockSecureStorageService implements SecureStorageService {
  String? savedTheme;
  bool throwOnSave = false;

  @override
  Future<void> saveThemeMode(String themeMode) async {
    if (throwOnSave) {
      throw Exception('Failed to write to storage');
    }
    savedTheme = themeMode;
  }

  @override
  Future<String?> getThemeMode() async {
    return savedTheme;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ThemeBloc Tests', () {
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    test('initial state has default themeMode system', () {
      final bloc = ThemeBloc(storageService: mockStorage);
      expect(bloc.state.themeMode, ThemeMode.system);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.successMessage, isNull);
      bloc.close();
    });

    test('initial state respects custom initialThemeMode', () {
      final bloc = ThemeBloc(
        storageService: mockStorage,
        initialThemeMode: ThemeMode.dark,
      );
      expect(bloc.state.themeMode, ThemeMode.dark);
      bloc.close();
    });

    test('ThemeStarted loads saved dark theme from storage', () async {
      mockStorage.savedTheme = 'dark';
      final bloc = ThemeBloc(storageService: mockStorage);

      bloc.add(const ThemeStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.themeMode, ThemeMode.dark);
      bloc.close();
    });

    test('ThemeStarted loads saved light theme from storage', () async {
      mockStorage.savedTheme = 'light';
      final bloc = ThemeBloc(storageService: mockStorage);

      bloc.add(const ThemeStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.themeMode, ThemeMode.light);
      bloc.close();
    });

    test('ThemeStarted falls back to system when saved value is invalid or null',
        () async {
      mockStorage.savedTheme = 'unknown_value';
      final bloc = ThemeBloc(storageService: mockStorage);

      bloc.add(const ThemeStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    test('ThemeChanged updates themeMode to dark and persists to storage',
        () async {
      final bloc = ThemeBloc(storageService: mockStorage);

      bloc.add(const ThemeChanged(ThemeMode.dark));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.themeMode, ThemeMode.dark);
      expect(mockStorage.savedTheme, 'dark');
      expect(bloc.state.successMessage, 'Theme changed successfully');
      bloc.close();
    });

    test('ThemeChanged updates themeMode to light and persists to storage',
        () async {
      final bloc = ThemeBloc(storageService: mockStorage);

      bloc.add(const ThemeChanged(ThemeMode.light));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.themeMode, ThemeMode.light);
      expect(mockStorage.savedTheme, 'light');
      bloc.close();
    });

    test('ThemeChanged updates themeMode to system and persists to storage',
        () async {
      final bloc = ThemeBloc(storageService: mockStorage);

      bloc.add(const ThemeChanged(ThemeMode.system));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.themeMode, ThemeMode.system);
      expect(mockStorage.savedTheme, 'system');
      bloc.close();
    });

    test('ThemeChanged sets errorMessage when storage throws', () async {
      mockStorage.throwOnSave = true;
      final bloc = ThemeBloc(storageService: mockStorage);

      bloc.add(const ThemeChanged(ThemeMode.dark));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.errorMessage, isNotNull);
      bloc.close();
    });

    test('ThemeState copyWith works correctly', () {
      const state = ThemeState(themeMode: ThemeMode.light);
      final updated = state.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
    });
  });
}
