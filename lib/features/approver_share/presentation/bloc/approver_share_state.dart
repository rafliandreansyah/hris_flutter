import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/approver_share/data/models/approver_model.dart';

abstract class ApproverShareState extends Equatable {
  const ApproverShareState();

  @override
  List<Object?> get props => [];
}

class ApproverShareInitial extends ApproverShareState {
  const ApproverShareInitial();
}

class ApproverShareLoading extends ApproverShareState {
  const ApproverShareLoading();
}

class ApproverShareLoaded extends ApproverShareState {
  final List<ApproverModel> approvers;

  const ApproverShareLoaded(this.approvers);

  @override
  List<Object?> get props => [approvers];
}

class ApproverShareError extends ApproverShareState {
  final String message;
  final int? statusCode;

  const ApproverShareError({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}
