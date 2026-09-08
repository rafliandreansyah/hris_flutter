import 'dart:ui';
import 'package:equatable/equatable.dart';

class LocaleState extends Equatable {
  final Locale locale;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const LocaleState({
    required this.locale,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  LocaleState copyWith({
    Locale? locale,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [locale, isSubmitting, errorMessage, successMessage];
}
