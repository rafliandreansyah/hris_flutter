import 'package:equatable/equatable.dart';

abstract class WarningLetterDetailEvent extends Equatable {
  const WarningLetterDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchWarningLetterDetail extends WarningLetterDetailEvent {
  final String id;

  const FetchWarningLetterDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshWarningLetterDetail extends WarningLetterDetailEvent {
  const RefreshWarningLetterDetail();
}
