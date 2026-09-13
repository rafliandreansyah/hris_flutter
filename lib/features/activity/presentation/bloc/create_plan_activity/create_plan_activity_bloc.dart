import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart';
import 'package:hris_flutter/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:hris_flutter/features/activity/domain/repositories/activity_repository.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_plan_activity/create_plan_activity_event.dart';
import 'package:hris_flutter/features/activity/presentation/bloc/create_plan_activity/create_plan_activity_state.dart';
import 'package:hris_flutter/features/employee/data/models/employee_api_models.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';

export 'create_plan_activity_event.dart';
export 'create_plan_activity_state.dart';

class CreatePlanActivityBloc
    extends Bloc<CreatePlanActivityEvent, CreatePlanActivityState> {
  final ActivityRepository _activityRepository;
  final EmployeeRepository _employeeRepository;

  CreatePlanActivityBloc({
    ActivityRepository? activityRepository,
    EmployeeRepository? employeeRepository,
  }) : _activityRepository = activityRepository ?? ActivityRepositoryImpl(),
       _employeeRepository = employeeRepository ?? EmployeeRepositoryImpl(),
       super(const CreatePlanActivityState()) {
    on<CreatePlanActivityStarted>(_onStarted);
    on<CreatePlanActivityEmployeeSelected>(_onEmployeeSelected);
    on<CreatePlanActivityTypeSelected>(_onTypeSelected);
    on<CreatePlanActivitySubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    CreatePlanActivityStarted event,
    Emitter<CreatePlanActivityState> emit,
  ) async {
    emit(state.copyWith(status: CreatePlanActivityStatus.loadingData));
    try {
      final results = await Future.wait([
        _activityRepository.getActivityTypes(),
        _employeeRepository.getEmployees(page: 1, size: 50),
      ]);

      final typesRes = results[0] as ActivityTypesResponse;
      final empRes = results[1] as EmployeeListResponse;

      emit(
        state.copyWith(
          status: CreatePlanActivityStatus.dataLoaded,
          activityTypes: typesRes.data,
          employees: empRes.data,
        ),
      );
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : e.toString();
      emit(
        state.copyWith(
          status: CreatePlanActivityStatus.failure,
          errorMessage: errorMsg,
        ),
      );
    }
  }

  void _onEmployeeSelected(
    CreatePlanActivityEmployeeSelected event,
    Emitter<CreatePlanActivityState> emit,
  ) {
    emit(state.copyWith(selectedEmployee: event.employee));
  }

  void _onTypeSelected(
    CreatePlanActivityTypeSelected event,
    Emitter<CreatePlanActivityState> emit,
  ) {
    emit(state.copyWith(selectedActivityType: event.activityType));
  }

  Future<void> _onSubmitted(
    CreatePlanActivitySubmitted event,
    Emitter<CreatePlanActivityState> emit,
  ) async {
    emit(state.copyWith(status: CreatePlanActivityStatus.submitting));
    try {
      final response = await _activityRepository.createPlanActivity(
        employeeId: event.employeeId,
        activityTypeId: event.activityTypeId,
        startTime: event.startTime,
        locationName: event.locationName,
        locationAddress: event.locationAddress,
        description: event.description,
        latitude: event.latitude,
        longitude: event.longitude,
        file: event.file,
      );

      final activityItem = response.toActivityItem(isMyActivity: false);
      emit(
        state.copyWith(
          status: CreatePlanActivityStatus.success,
          createdActivity: activityItem,
        ),
      );
    } catch (e) {
      final errorMsg = e is ApiException ? e.message : e.toString();
      emit(
        state.copyWith(
          status: CreatePlanActivityStatus.failure,
          errorMessage: errorMsg,
        ),
      );
    }
  }
}
