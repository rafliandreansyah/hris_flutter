import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:hris_flutter/features/notification/domain/repositories/notification_repository.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_count/notification_count_event.dart';
import 'package:hris_flutter/features/notification/presentation/bloc/notification_count/notification_count_state.dart';

class NotificationCountBloc
    extends Bloc<NotificationCountEvent, NotificationCountState> {
  final NotificationRepository _repository;

  NotificationCountBloc({
    NotificationRepository? repository,
  })  : _repository = repository ?? NotificationRepositoryImpl(),
        super(const NotificationCountState()) {
    on<NotificationCountFetchRequested>(_onFetchRequested);
    on<NotificationCountUpdated>(_onUpdated);
    on<NotificationCountDecremented>(_onDecremented);
    on<NotificationCountReset>(_onReset);
  }

  Future<void> _onFetchRequested(
    NotificationCountFetchRequested event,
    Emitter<NotificationCountState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _repository.getUnreadCount();
      emit(state.copyWith(
        count: response.unreadCount,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onUpdated(
    NotificationCountUpdated event,
    Emitter<NotificationCountState> emit,
  ) {
    emit(state.copyWith(count: event.count));
  }

  void _onDecremented(
    NotificationCountDecremented event,
    Emitter<NotificationCountState> emit,
  ) {
    final next = state.count > 0 ? state.count - 1 : 0;
    emit(state.copyWith(count: next));
  }

  void _onReset(
    NotificationCountReset event,
    Emitter<NotificationCountState> emit,
  ) {
    emit(state.copyWith(count: 0));
  }
}
