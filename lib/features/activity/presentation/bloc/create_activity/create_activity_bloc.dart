import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_activity/create_activity_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_activity/create_activity_state.dart';

export 'create_activity_event.dart';
export 'create_activity_state.dart';

class CreateActivityBloc
    extends Bloc<CreateActivityEvent, CreateActivityState> {
  final ActivityRepository _repository;

  CreateActivityBloc({ActivityRepository? repository})
      : _repository = repository ?? ActivityRepositoryImpl(),
        super(const CreateActivityState()) {
    on<CreateActivityStarted>(_onStarted);
    on<CreateActivitySubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreateActivityStarted event,
    Emitter<CreateActivityState> emit,
  ) async {
    emit(state.copyWith(status: CreateActivityStatus.loadingTypes));
    try {
      final response = await _repository.getActivityTypes();
      emit(state.copyWith(
        status: CreateActivityStatus.typesLoaded,
        activityTypes: response.data,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateActivityStatus.typesLoaded,
        activityTypes: const [],
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitted(
    CreateActivitySubmitted event,
    Emitter<CreateActivityState> emit,
  ) async {
    emit(state.copyWith(status: CreateActivityStatus.submitting));
    try {
      final response = await _repository.createActivity(
        activityTypeId: event.activityTypeId,
        latitude: event.latitude,
        longitude: event.longitude,
        locationName: event.locationName,
        locationAddress: event.locationAddress,
        description: event.description,
        status: 'ongoing',
        file: event.file,
      );
      final activityItem = response.toActivityItem(isMyActivity: true);
      emit(state.copyWith(
        status: CreateActivityStatus.success,
        createdActivity: activityItem,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateActivityStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
