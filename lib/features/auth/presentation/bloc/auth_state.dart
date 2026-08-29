import 'package:equatable/equatable.dart';

/// State dasar untuk Auth BLoC
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum aksi autentikasi dilakukan
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State ketika proses login/autentikasi sedang berlangsung di backend
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State ketika login berhasil dan menerima token
class AuthSuccess extends AuthState {
  final String token;
  final String message;

  const AuthSuccess({
    required this.token,
    this.message = 'Login berhasil! Mengalihkan...',
  });

  @override
  List<Object?> get props => [token, message];
}

/// State ketika login gagal (kredensial salah, koneksi timeout, device mismatch, dll)
class AuthFailure extends AuthState {
  final String message;
  final int? statusCode;

  const AuthFailure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
