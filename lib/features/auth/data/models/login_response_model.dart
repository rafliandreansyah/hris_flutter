/// Model data objek token dari response Login sukses.
class LoginResponseData {
  final String token;

  /// Refresh token untuk memperbarui [token] tanpa login ulang; `null` bila server belum mendukung.
  final String? refreshToken;

  const LoginResponseData({required this.token, this.refreshToken});

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
  }
}
