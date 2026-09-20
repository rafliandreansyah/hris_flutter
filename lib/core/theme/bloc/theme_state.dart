import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final String? successMessage;
  final String? errorMessage;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.successMessage,
    this.errorMessage,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    String? successMessage,
    String? errorMessage,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [themeMode, successMessage, errorMessage];
}
