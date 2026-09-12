import 'package:equatable/equatable.dart';

class NotificationCountState extends Equatable {
  final int count;
  final bool isLoading;
  final String? errorMessage;

  const NotificationCountState({
    this.count = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationCountState copyWith({
    int? count,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationCountState(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [count, isLoading, errorMessage];
}
