import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/localization/bloc/locale_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  String currentLang = 'id';
  bool shouldFail = false;

  @override
  Future<String> updateLanguage(String language) async {
    if (shouldFail) {
      throw ApiException(message: 'Failed to update language', statusCode: 500);
    }
    currentLang = language;
    return language;
  }

  @override
  Future<UserProfileData> getProfile() async {
    return UserProfileData(
      user: UserModel(id: 'u1', email: 'u@test.com', language: currentLang),
      dataScope: 'ALL',
      permissions: const ['all'],
    );
  }

  @override
  Future<LoginResponseData> login(LoginRequestModel request) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> getSavedToken() async => 'dummy-token';

  @override
  Future<bool> hasActiveSession() async => true;

  @override
  Future<void> logout() async {}
}

class MockSecureStorageService implements SecureStorageService {
  String? savedLang;

  @override
  Future<void> saveUserLanguage(String language) async {
    savedLang = language;
  }

  @override
  Future<String?> getUserLanguage() async {
    return savedLang;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LocaleBloc Tests', () {
    late MockAuthRepository mockAuthRepo;
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      mockStorage = MockSecureStorageService();
    });

    test('initial state has default locale id', () {
      final bloc = LocaleBloc(
        authRepository: mockAuthRepo,
        storageService: mockStorage,
      );
      expect(bloc.state.locale, const Locale('id'));
      expect(bloc.state.isSubmitting, false);
      bloc.close();
    });

    test('LocaleStarted loads saved language from storage', () async {
      mockStorage.savedLang = 'en';
      final bloc = LocaleBloc(
        authRepository: mockAuthRepo,
        storageService: mockStorage,
      );

      bloc.add(const LocaleStarted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.locale, const Locale('en'));
      bloc.close();
    });

    test('LocaleChanged updates language and persists to storage on success',
        () async {
      final bloc = LocaleBloc(
        authRepository: mockAuthRepo,
        storageService: mockStorage,
      );

      final expectedStates = [
        const LocaleState(
          locale: Locale('id'),
          isSubmitting: true,
          errorMessage: null,
          successMessage: null,
        ),
        const LocaleState(
          locale: Locale('en'),
          isSubmitting: false,
          errorMessage: null,
          successMessage: 'Language changed to English',
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LocaleChanged('en'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockStorage.savedLang, 'en');
      expect(mockAuthRepo.currentLang, 'en');
      bloc.close();
    });

    test('LocaleChanged emits error on API failure', () async {
      mockAuthRepo.shouldFail = true;
      final bloc = LocaleBloc(
        authRepository: mockAuthRepo,
        storageService: mockStorage,
      );

      final expectedStates = [
        const LocaleState(
          locale: Locale('id'),
          isSubmitting: true,
          errorMessage: null,
          successMessage: null,
        ),
        const LocaleState(
          locale: Locale('id'),
          isSubmitting: false,
          errorMessage: 'Failed to update language',
          successMessage: null,
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LocaleChanged('en'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockStorage.savedLang, null);
      bloc.close();
    });

    test('LocaleChanged ignores unsupported language code', () async {
      final bloc = LocaleBloc(
        authRepository: mockAuthRepo,
        storageService: mockStorage,
      );

      bloc.add(const LocaleChanged('fr'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.locale, const Locale('id'));
      bloc.close();
    });

    test('LocaleSynced updates locale when server language differs', () async {
      final bloc = LocaleBloc(
        authRepository: mockAuthRepo,
        storageService: mockStorage,
        initialLocale: const Locale('id'),
      );

      bloc.add(const LocaleSynced('en'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.locale, const Locale('en'));
      expect(mockStorage.savedLang, 'en');
      bloc.close();
    });

    test('LocaleSynced does not emit if server language is identical', () async {
      final bloc = LocaleBloc(
        authRepository: mockAuthRepo,
        storageService: mockStorage,
        initialLocale: const Locale('id'),
      );

      var emitCount = 0;
      bloc.stream.listen((_) => emitCount++);

      bloc.add(const LocaleSynced('id'));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(emitCount, 0);
      bloc.close();
    });
  });
}
