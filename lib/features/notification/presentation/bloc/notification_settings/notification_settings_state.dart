import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/notification/data/models/notification_settings_model.dart';

class NotificationSettingsState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final NotificationSettingsModel? initialSettings;
  final NotificationSettingsModel? currentSettings;
  final String? errorMessage;
  final String? successMessage;

  const NotificationSettingsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.initialSettings,
    this.currentSettings,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasChanges {
    if (initialSettings == null || currentSettings == null) return false;
    return initialSettings != currentSettings;
  }

  bool get isMasterEnabled => currentSettings?.isAllEnabled ?? false;

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    NotificationSettingsModel? initialSettings,
    NotificationSettingsModel? currentSettings,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      initialSettings: initialSettings ?? this.initialSettings,
      currentSettings: currentSettings ?? this.currentSettings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        initialSettings,
        currentSettings,
        errorMessage,
        successMessage,
      ];
}
