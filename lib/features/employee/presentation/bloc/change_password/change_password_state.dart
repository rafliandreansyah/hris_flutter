import 'package:equatable/equatable.dart';

enum ChangePasswordStatus { initial, loading, success, failure }

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;
  final String? errorMessage;
  final String? successMessage;

  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == ChangePasswordStatus.loading;
  bool get isSuccess => status == ChangePasswordStatus.success;
  bool get isFailure => status == ChangePasswordStatus.failure;

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return ChangePasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage];
}
