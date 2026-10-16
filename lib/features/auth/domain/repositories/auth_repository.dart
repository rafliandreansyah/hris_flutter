import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';
import 'package:hris_flutter/features/auth/data/models/user_profile_response_model.dart';

abstract class AuthRepository {
  Future<LoginResponseData> login(LoginRequestModel request);
  Future<String?> getSavedToken();
  Future<bool> hasActiveSession();
  /// Keluar dari sesi. [notifyServer] = `true` (logout oleh pengguna) memanggil `POST /auth/logout`
  /// secara best-effort agar refresh token dicabut & perangkat dilepas dari akun.
  /// Gunakan `false` untuk pembersihan paksa (mis. sesi kedaluwarsa / perangkat tidak cocok).
  Future<void> logout({bool notifyServer = false});

  /// Memperbarui access token memakai refresh token tersimpan.
  /// Mengembalikan access token baru, atau `null` bila gagal / tidak ada refresh token.
  Future<String?> refreshSession();
  Future<UserProfileData> getProfile();
  Future<String> updateLanguage(String language);
}
