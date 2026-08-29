import 'package:equatable/equatable.dart';

/// Event dasar untuk Auth BLoC
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event ketika aplikasi pertama kali dibuka (memeriksa token tersimpan)
class AuthCheckSessionRequested extends AuthEvent {
  const AuthCheckSessionRequested();
}

/// Event ketika user menekan tombol login
class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event ketika user melakukan logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
