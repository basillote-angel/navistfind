import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/core/secure_storage.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  Future<String?> login(String email, String password) async {
    try {
      final response = await ApiClient.client.post(
        '/api/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        if (token != null) {
          await SecureStorage.storeToken(token);
          return null;
        } else {
          return 'Token not found in response';
        }
      } else {
        // Try to extract message from response
        return response.data['message'] ?? 'Login failed';
      }
    } on DioException catch (e) {
      // Try to extract error message from Dio error response
      final errorResponse = e.response;
      if (errorResponse != null && errorResponse.data != null) {
        final message = errorResponse.data['message'];
        if (message != null && message is String) {
          return message;
        }
      }
      return 'Login failed: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final response = await ApiClient.client.post(
        '/api/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        if (token != null) {
          await SecureStorage.storeToken(token);
          return null;
        } else {
          return 'Token not found in response';
        }
      } else {
        return response.data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> logout() async {
    try {
      final response = await ApiClient.client.post('/api/logout');

      if (response.statusCode == 200) {
        final container = ProviderContainer();
        container.refresh(profileInfoProvider);
        container.dispose(); // Important to dispose to prevent memory leaks

        await SecureStorage.clearToken();

        return null;
      } else {
        return response.data['message'] ?? 'Logout failed';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
