import 'package:equatable/equatable.dart';

abstract class ApproverShareEvent extends Equatable {
  const ApproverShareEvent();

  @override
  List<Object?> get props => [];
}

class FetchApprovers extends ApproverShareEvent {
  final String module;
  final String requestId;

  const FetchApprovers({required this.module, required this.requestId});

  @override
  List<Object?> get props => [module, requestId];
}

/// Pull-to-refresh: muat ulang tanpa shimmer.
class RefreshApprovers extends ApproverShareEvent {
  const RefreshApprovers();
}
