import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  // Auth token
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Remember Me preference
  static Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: 'remember_me', value: remember.toString());
  }

  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: 'remember_me');
    return value == 'true';
  }

  static Future<void> clearRememberMe() async {
    await _storage.delete(key: 'remember_me');
  }

  // User email for Remember Me (optional, for auto-fill)
  static Future<void> saveEmail(String email) async {
    await _storage.write(key: 'saved_email', value: email);
  }

  static Future<String?> getSavedEmail() async {
    return await _storage.read(key: 'saved_email');
  }

  static Future<void> clearSavedEmail() async {
    await _storage.delete(key: 'saved_email');
  }

  // Clear all auth data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
