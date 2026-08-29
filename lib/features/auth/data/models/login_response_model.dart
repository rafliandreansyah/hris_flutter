/// Model data objek token dari response Login sukses.
class LoginResponseData {
  final String token;

  const LoginResponseData({required this.token});

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}
