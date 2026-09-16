import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/coworker_list/coworker_list_event.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/coworker_list/coworker_list_state.dart';

export 'coworker_list_event.dart';
export 'coworker_list_state.dart';

class CoworkerListBloc extends Bloc<CoworkerListEvent, CoworkerListState> {
  final EmployeeRepository _repository;

  CoworkerListBloc({
    EmployeeRepository? repository,
    List<EmployeeDirectoryItem>? initialCoworkers,
  })  : _repository = repository ?? EmployeeRepositoryImpl(),
        super(CoworkerListState(
          coworkers: initialCoworkers ?? const [],
          filteredCoworkers: initialCoworkers ?? const [],
          status: (initialCoworkers != null && initialCoworkers.isNotEmpty)
              ? CoworkerListStatus.success
              : CoworkerListStatus.initial,
        )) {
    on<CoworkerListStarted>(_onStarted);
    on<CoworkerListSearchChanged>(_onSearchChanged);
    on<CoworkerListRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    CoworkerListStarted event,
    Emitter<CoworkerListState> emit,
  ) async {
    if (event.initialCoworkers != null && event.initialCoworkers!.isNotEmpty) {
      emit(state.copyWith(
        status: CoworkerListStatus.success,
        coworkers: event.initialCoworkers,
        filteredCoworkers: _filterList(event.initialCoworkers!, state.searchQuery),
        clearError: true,
      ));
      return;
    }

    await _fetchCoworkers(emit);
  }

  Future<void> _onRefreshed(
    CoworkerListRefreshed event,
    Emitter<CoworkerListState> emit,
  ) async {
    await _fetchCoworkers(emit);
  }

  void _onSearchChanged(
    CoworkerListSearchChanged event,
    Emitter<CoworkerListState> emit,
  ) {
    final query = event.query;
    final filtered = _filterList(state.coworkers, query);
    emit(state.copyWith(
      searchQuery: query,
      filteredCoworkers: filtered,
    ));
  }

  Future<void> _fetchCoworkers(Emitter<CoworkerListState> emit) async {
    emit(state.copyWith(
      status: CoworkerListStatus.loading,
      clearError: true,
    ));

    try {
      final items = await _repository.getCoworkers();
      emit(state.copyWith(
        status: CoworkerListStatus.success,
        coworkers: items,
        filteredCoworkers: _filterList(items, state.searchQuery),
        clearError: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CoworkerListStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CoworkerListStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  List<EmployeeDirectoryItem> _filterList(
    List<EmployeeDirectoryItem> source,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;

    return source.where((item) {
      final nameMatches = item.name.toLowerCase().contains(q);
      final roleMatches = item.role.toLowerCase().contains(q);
      final deptMatches = item.department.toLowerCase().contains(q);
      final emailMatches = item.email.toLowerCase().contains(q);
      final idMatches = item.displayId.toLowerCase().contains(q);
      final phoneMatches = item.phone?.toLowerCase().contains(q) ?? false;

      return nameMatches ||
          roleMatches ||
          deptMatches ||
          emailMatches ||
          idMatches ||
          phoneMatches;
    }).toList();
  }
}
