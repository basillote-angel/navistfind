import 'package:navistfind/core/secure_storage.dart';

class AuthStore {
  static Future<void> setToken(String token) {
    return SecureStorage.storeToken(token);
  }

  static Future<String?> getToken() {
    return SecureStorage.getToken();
  }

  static Future<void> clearToken() {
    return SecureStorage.clearToken();
  }
}
