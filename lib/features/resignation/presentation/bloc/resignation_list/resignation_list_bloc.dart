import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/core/network/api_exception.dart';
import 'package:hris_flutter/core/utils/bloc_transformers.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/resignation/data/repositories/resignation_repository_impl.dart';
import 'package:hris_flutter/features/resignation/domain/repositories/resignation_repository.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_event.dart';
import 'package:hris_flutter/features/resignation/presentation/bloc/resignation_list/resignation_list_state.dart';

class ResignationListBloc
    extends Bloc<ResignationListEvent, ResignationListState> {
  final ResignationRepository _repository;

  static const int defaultPageSize = 10;

  ResignationListBloc({ResignationRepository? repository})
      : _repository = repository ?? ResignationRepositoryImpl(),
        super(const ResignationListState()) {
    on<ResignationListStarted>(_onStarted);
    on<ResignationListTabChanged>(_onTabChanged);
    on<ResignationListMyStatusRequested>(_onMyStatusRequested);
    on<ResignationListSubordinatesRequested>(_onSubordinatesRequested);
    on<ResignationListSubordinatesLoadMore>(_onSubordinatesLoadMore);
    on<ResignationListSearchChanged>(
      _onSearchChanged,
      transformer: debounceRestartable(),
    );
    on<ResignationListFilterApplied>(_onFilterApplied);
    on<ResignationListFilterReset>(_onFilterReset);
    on<ResignationListCancelRequested>(_onCancelRequested);
  }

  void _onStarted(
    ResignationListStarted event,
    Emitter<ResignationListState> emit,
  ) {
    add(const ResignationListMyStatusRequested());
    add(const ResignationListSubordinatesRequested());
  }

  void _onTabChanged(
    ResignationListTabChanged event,
    Emitter<ResignationListState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  Future<void> _onMyStatusRequested(
    ResignationListMyStatusRequested event,
    Emitter<ResignationListState> emit,
  ) async {
    emit(state.copyWith(isMyStatusLoading: true, clearErrorMessage: true));
    try {
      final result = await _repository.getMyResignationStatus();
      emit(state.copyWith(
        isMyStatusLoading: false,
        myStatus: result,
      ));
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      emit(state.copyWith(
        isMyStatusLoading: false,
        errorMessage: msg,
      ));
    }
  }

  Future<void> _onSubordinatesRequested(
    ResignationListSubordinatesRequested event,
    Emitter<ResignationListState> emit,
  ) async {
    final statusFilter =
        event.statusFilter ?? state.subordinatesStatusFilter;

    emit(state.copyWith(
      isSubordinatesLoading: true,
      subordinatesStatusFilter: statusFilter,
      clearErrorMessage: true,
    ));

    try {
      final result = await _repository.getSubordinateResignations(
        status: statusFilter,
        page: 1,
        size: defaultPageSize,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        companyId: state.filterData.companyId,
        departmentId: state.filterData.departmentId,
        positionId: state.filterData.positionId,
        startDate: state.filterData.startDateParam,
        endDate: state.filterData.endDateParam,
      );

      emit(state.copyWith(
        isSubordinatesLoading: false,
        subordinates: result.data,
        subordinatesPage: result.meta.page,
        subordinatesTotalPages: result.meta.totalPages,
        subordinatesTotal: result.meta.total,
      ));
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      emit(state.copyWith(
        isSubordinatesLoading: false,
        errorMessage: msg,
      ));
    }
  }

  Future<void> _onSubordinatesLoadMore(
    ResignationListSubordinatesLoadMore event,
    Emitter<ResignationListState> emit,
  ) async {
    if (!state.canLoadMoreSubordinates) return;

    emit(state.copyWith(isSubordinatesLoadingMore: true));
    final nextPage = state.subordinatesPage + 1;

    try {
      final result = await _repository.getSubordinateResignations(
        status: state.subordinatesStatusFilter,
        page: nextPage,
        size: defaultPageSize,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        companyId: state.filterData.companyId,
        departmentId: state.filterData.departmentId,
        positionId: state.filterData.positionId,
        startDate: state.filterData.startDateParam,
        endDate: state.filterData.endDateParam,
      );

      emit(state.copyWith(
        isSubordinatesLoadingMore: false,
        subordinates: [...state.subordinates, ...result.data],
        subordinatesPage: result.meta.page,
        subordinatesTotalPages: result.meta.totalPages,
        subordinatesTotal: result.meta.total,
      ));
    } catch (_) {
      emit(state.copyWith(isSubordinatesLoadingMore: false));
    }
  }

  void _onSearchChanged(
    ResignationListSearchChanged event,
    Emitter<ResignationListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    add(const ResignationListSubordinatesRequested());
  }

  void _onFilterApplied(
    ResignationListFilterApplied event,
    Emitter<ResignationListState> emit,
  ) {
    emit(state.copyWith(filterData: event.filterData));
    add(const ResignationListSubordinatesRequested());
  }

  void _onFilterReset(
    ResignationListFilterReset event,
    Emitter<ResignationListState> emit,
  ) {
    emit(state.copyWith(filterData: const AppRequestFilterData()));
    add(const ResignationListSubordinatesRequested());
  }

  Future<void> _onCancelRequested(
    ResignationListCancelRequested event,
    Emitter<ResignationListState> emit,
  ) async {
    emit(state.copyWith(
      isCancelling: true,
      cancelSuccess: false,
      clearErrorMessage: true,
    ));

    try {
      await _repository.cancelMyResignation();
      emit(state.copyWith(isCancelling: false, cancelSuccess: true));
      add(const ResignationListMyStatusRequested(isRefresh: true));
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      emit(state.copyWith(
        isCancelling: false,
        errorMessage: msg,
      ));
    }
  }
}
