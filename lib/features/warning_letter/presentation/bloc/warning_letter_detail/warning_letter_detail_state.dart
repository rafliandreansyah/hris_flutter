import 'package:equatable/equatable.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';

abstract class WarningLetterDetailState extends Equatable {
  const WarningLetterDetailState();

  @override
  List<Object?> get props => [];
}

class WarningLetterDetailInitial extends WarningLetterDetailState {
  const WarningLetterDetailInitial();
}

class WarningLetterDetailLoading extends WarningLetterDetailState {
  const WarningLetterDetailLoading();
}

class WarningLetterDetailLoaded extends WarningLetterDetailState {
  final WarningLetterDetail detail;

  const WarningLetterDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class WarningLetterDetailError extends WarningLetterDetailState {
  final String message;
  final int? statusCode;

  const WarningLetterDetailError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
