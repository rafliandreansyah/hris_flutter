import 'package:hris_flutter/features/auth/data/models/login_request_model.dart';
import 'package:hris_flutter/features/auth/data/models/login_response_model.dart';

abstract class AuthRepository {
  Future<LoginResponseData> login(LoginRequestModel request);
  Future<String?> getSavedToken();
  Future<bool> hasActiveSession();
  Future<void> logout();
}
