import 'package:equatable/equatable.dart';

abstract class NotificationCountEvent extends Equatable {
  const NotificationCountEvent();

  @override
  List<Object?> get props => [];
}

class NotificationCountFetchRequested extends NotificationCountEvent {
  const NotificationCountFetchRequested();
}

class NotificationCountUpdated extends NotificationCountEvent {
  final int count;

  const NotificationCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

class NotificationCountDecremented extends NotificationCountEvent {
  const NotificationCountDecremented();
}

class NotificationCountReset extends NotificationCountEvent {
  const NotificationCountReset();
}
