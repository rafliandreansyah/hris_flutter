import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';

enum CoworkerListStatus { initial, loading, success, failure }

class CoworkerListState extends Equatable {
  final CoworkerListStatus status;
  final List<EmployeeDirectoryItem> coworkers;
  final List<EmployeeDirectoryItem> filteredCoworkers;
  final String searchQuery;
  final String? errorMessage;

  const CoworkerListState({
    this.status = CoworkerListStatus.initial,
    this.coworkers = const [],
    this.filteredCoworkers = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == CoworkerListStatus.loading;

  CoworkerListState copyWith({
    CoworkerListStatus? status,
    List<EmployeeDirectoryItem>? coworkers,
    List<EmployeeDirectoryItem>? filteredCoworkers,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CoworkerListState(
      status: status ?? this.status,
      coworkers: coworkers ?? this.coworkers,
      filteredCoworkers: filteredCoworkers ?? this.filteredCoworkers,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        coworkers,
        filteredCoworkers,
        searchQuery,
        errorMessage,
      ];
}
