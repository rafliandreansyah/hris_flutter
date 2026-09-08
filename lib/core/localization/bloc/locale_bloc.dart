import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hris_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'locale_event.dart';
import 'locale_state.dart';

export 'locale_event.dart';
export 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final AuthRepository _authRepository;
  final SecureStorageService _storageService;

  LocaleBloc({
    AuthRepository? authRepository,
    SecureStorageService? storageService,
    Locale initialLocale = const Locale('id'),
  })  : _authRepository = authRepository ?? AuthRepositoryImpl(),
        _storageService = storageService ?? SecureStorageService.instance,
        super(LocaleState(locale: initialLocale)) {
    on<LocaleStarted>(_onStarted);
    on<LocaleChanged>(_onChanged);
    on<LocaleSynced>(_onSynced);
  }

  Future<void> _onStarted(
    LocaleStarted event,
    Emitter<LocaleState> emit,
  ) async {
    final saved = await _storageService.getUserLanguage();
    if (saved != null && (saved == 'en' || saved == 'id')) {
      emit(state.copyWith(locale: Locale(saved)));
    }
  }

  Future<void> _onChanged(
    LocaleChanged event,
    Emitter<LocaleState> emit,
  ) async {
    final newCode = event.languageCode.toLowerCase();
    if (newCode != 'id' && newCode != 'en') return;

    emit(state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      successMessage: null,
    ));

    try {
      await _authRepository.updateLanguage(newCode);
      await _storageService.saveUserLanguage(newCode);
      emit(state.copyWith(
        locale: Locale(newCode),
        isSubmitting: false,
        successMessage: newCode == 'en'
            ? 'Language changed to English'
            : 'Bahasa diubah ke Bahasa Indonesia',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSynced(
    LocaleSynced event,
    Emitter<LocaleState> emit,
  ) async {
    final serverLang = event.languageCode.toLowerCase();
    if (serverLang == 'en' || serverLang == 'id') {
      await _storageService.saveUserLanguage(serverLang);
      if (state.locale.languageCode != serverLang) {
        emit(state.copyWith(locale: Locale(serverLang)));
      }
    }
  }
}
