import 'package:equatable/equatable.dart';

enum NotificationFilterType { all, unread }

abstract class NotificationListEvent extends Equatable {
  const NotificationListEvent();

  @override
  List<Object?> get props => [];
}

class NotificationListStarted extends NotificationListEvent {
  final NotificationFilterType? filter;

  const NotificationListStarted({this.filter});

  @override
  List<Object?> get props => [filter];
}

class NotificationListRefreshed extends NotificationListEvent {
  const NotificationListRefreshed();
}

class NotificationListLoadMore extends NotificationListEvent {
  const NotificationListLoadMore();
}

class NotificationListFilterChanged extends NotificationListEvent {
  final NotificationFilterType filter;

  const NotificationListFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

class NotificationMarkAsReadRequested extends NotificationListEvent {
  final String id;

  const NotificationMarkAsReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class NotificationMarkAllAsReadRequested extends NotificationListEvent {
  const NotificationMarkAllAsReadRequested();
}
