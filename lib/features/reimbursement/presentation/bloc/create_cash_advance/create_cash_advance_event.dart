import 'package:equatable/equatable.dart';

abstract class CreateCashAdvanceEvent extends Equatable {
  const CreateCashAdvanceEvent();

  @override
  List<Object?> get props => [];
}

class CreateCashAdvanceStarted extends CreateCashAdvanceEvent {
  const CreateCashAdvanceStarted();
}

class CreateCashAdvanceSubmitted extends CreateCashAdvanceEvent {
  final String title;
  final String purpose;
  final double requestedAmount;
  final String? settlementDeadline;

  const CreateCashAdvanceSubmitted({
    required this.title,
    required this.purpose,
    required this.requestedAmount,
    this.settlementDeadline,
  });

  @override
  List<Object?> get props => [
        title,
        purpose,
        requestedAmount,
        settlementDeadline,
      ];
}
