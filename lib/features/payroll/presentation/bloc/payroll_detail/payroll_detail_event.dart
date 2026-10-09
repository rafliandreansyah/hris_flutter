import 'package:equatable/equatable.dart';

abstract class PayrollDetailEvent extends Equatable {
  const PayrollDetailEvent();

  @override
  List<Object?> get props => [];
}

class PayrollDetailFetched extends PayrollDetailEvent {
  final String id;

  const PayrollDetailFetched(this.id);

  @override
  List<Object?> get props => [id];
}

class PayrollDetailDownloadRequested extends PayrollDetailEvent {
  final bool force;

  const PayrollDetailDownloadRequested({this.force = false});

  @override
  List<Object?> get props => [force];
}

class PayrollDetailPrivacyToggled extends PayrollDetailEvent {
  const PayrollDetailPrivacyToggled();
}
