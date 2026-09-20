import 'package:equatable/equatable.dart';

enum NotificationSettingKey {
  attendanceRequest,
  leave,
  overtime,
  payroll,
  announcement,
  warningLetter,
}

abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationSettingsStarted extends NotificationSettingsEvent {
  const NotificationSettingsStarted();
}

class NotificationSettingsRefreshed extends NotificationSettingsEvent {
  const NotificationSettingsRefreshed();
}

class NotificationSettingsToggled extends NotificationSettingsEvent {
  final NotificationSettingKey key;
  final bool value;

  const NotificationSettingsToggled({
    required this.key,
    required this.value,
  });

  @override
  List<Object?> get props => [key, value];
}

class NotificationSettingsMasterToggled extends NotificationSettingsEvent {
  final bool value;

  const NotificationSettingsMasterToggled(this.value);

  @override
  List<Object?> get props => [value];
}

class NotificationSettingsReset extends NotificationSettingsEvent {
  const NotificationSettingsReset();
}

class NotificationSettingsSubmitted extends NotificationSettingsEvent {
  const NotificationSettingsSubmitted();
}
