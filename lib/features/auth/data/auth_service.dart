import 'package:google_sign_in/google_sign_in.dart';
import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/core/secure_storage.dart';
import 'package:navistfind/core/constants.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  static const String _googleServerClientId =
      '1027515736857-55oieakvfs2b0l2elmlstdfpkgm3vkpn.apps.googleusercontent.com';

  GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: _googleServerClientId,
    );
  }

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
        // Handle validation errors (422 status)
        if (errorResponse.statusCode == 422) {
          if (errorResponse.data is Map) {
            final data = errorResponse.data as Map;
            // Laravel validation errors structure: {errors: {field: [messages]}}
            if (data.containsKey('errors')) {
              final errors = data['errors'];
              if (errors is Map && errors.isNotEmpty) {
                // Collect all validation errors
                final errorMessages = <String>[];
                errors.forEach((key, value) {
                  if (value is List && value.isNotEmpty) {
                    errorMessages.add(value.first as String);
                  } else if (value is String) {
                    errorMessages.add(value);
                  }
                });
                if (errorMessages.isNotEmpty) {
                  return errorMessages.join('\n');
                }
              }
            }
            // Fallback: check for message field
            if (data['message'] is String) {
              return data['message'] as String;
            }
          }
          return 'Validation failed. Please check your input.';
        }
        // Handle other error responses (401, 500, etc.)
        if (errorResponse.data is Map) {
          final data = errorResponse.data as Map;
          if (data['message'] is String) {
            return data['message'] as String;
          }
        }
      }
      // Network errors (no response)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Please check your connection and ensure the server is running.';
      }
      return 'Login failed: ${e.message ?? 'Network error'}';
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['access_token'];
        if (token != null) {
          await SecureStorage.storeToken(token);
          return null;
        } else {
          return 'Token not found in response';
        }
      } else {
        // Try to extract message from response
        return response.data['message'] ?? 'Registration failed';
      }
    } on DioException catch (e) {
      // Try to extract error message from Dio error response
      final errorResponse = e.response;
      if (errorResponse != null && errorResponse.data != null) {
        // Handle validation errors (422 status)
        if (errorResponse.statusCode == 422) {
          if (errorResponse.data is Map) {
            final data = errorResponse.data as Map;
            // Laravel validation errors structure: {errors: {field: [messages]}}
            if (data.containsKey('errors')) {
              final errors = data['errors'];
              if (errors is Map && errors.isNotEmpty) {
                // Collect all validation errors
                final errorMessages = <String>[];
                errors.forEach((key, value) {
                  if (value is List && value.isNotEmpty) {
                    errorMessages.add(value.first as String);
                  } else if (value is String) {
                    errorMessages.add(value);
                  }
                });
                if (errorMessages.isNotEmpty) {
                  return errorMessages.join('\n');
                }
              }
            }
            // Fallback: check for message field
            if (data['message'] is String) {
              return data['message'] as String;
            }
          }
          return 'Validation failed. Please check your input.';
        }
        // Handle other error responses
        if (errorResponse.data is Map) {
          final data = errorResponse.data as Map;
          if (data['message'] is String) {
            return data['message'] as String;
          }
        }
      }
      // Network errors (no response)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Please check your connection and ensure the server is running.';
      }
      return 'Registration failed: ${e.message ?? 'Network error'}';
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

        try {
          final googleSignIn = _createGoogleSignIn();
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
            await googleSignIn.disconnect();
          }
        } catch (_) {
          // Ignore Google sign-out failures; backend logout succeeded.
        }

        return null;
      } else {
        return response.data['message'] ?? 'Logout failed';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      final response = await ApiClient.client.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return response.data['message'] ?? 'Failed to send reset email';
      }
    } on DioException catch (e) {
      final errorResponse = e.response;
      if (errorResponse != null && errorResponse.data != null) {
        // Handle validation errors
        if (errorResponse.data is Map) {
          final data = errorResponse.data as Map;
          if (data['message'] is String) {
            return data['message'] as String;
          }
          // Laravel validation errors structure
          if (data.containsKey('errors')) {
            final errors = data['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                return firstError.first as String;
              }
            }
          }
        }
      }
      // Network errors (no response)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Please check your connection and ensure the server is running.';
      }
      return 'Failed to send reset email: ${e.message ?? 'Network error'}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await ApiClient.client.post(
        '/api/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return response.data['message'] ?? 'Failed to reset password';
      }
    } on DioException catch (e) {
      final errorResponse = e.response;
      if (errorResponse != null && errorResponse.data != null) {
        // Handle validation errors
        if (errorResponse.data is Map) {
          final data = errorResponse.data as Map;
          if (data['message'] is String) {
            return data['message'] as String;
          }
          // Laravel validation errors structure
          if (data.containsKey('errors')) {
            final errors = data['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                return firstError.first as String;
              }
            }
          }
        }
      }
      // Network errors (no response)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Please check your connection and ensure the server is running.';
      }
      return 'Failed to reset password: ${e.message ?? 'Network error'}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      print('[Google Sign-In] Initializing Google Sign-In...');

      // Initialize Google Sign-In
      // Note: Using Web Client ID to bypass SHA-1 fingerprint issues
      // The serverClientId helps retrieve ID tokens reliably
      final GoogleSignIn googleSignIn = _createGoogleSignIn();

      print('[Google Sign-In] Starting sign-in process...');

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('[Google Sign-In] User canceled sign-in');
        // User canceled the sign-in
        return 'Sign-in was canceled';
      }

      print('[Google Sign-In] User signed in: ${googleUser.email}');
      print('[Google Sign-In] Getting authentication details...');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('[Google Sign-In] Authentication retrieved');
      print(
        '[Google Sign-In] Access token: ${googleAuth.accessToken != null ? "exists" : "null"}',
      );
      print(
        '[Google Sign-In] ID token: ${googleAuth.idToken != null ? "exists" : "null"}',
      );

      // Get the ID token
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        print('[Google Sign-In] ERROR: ID token is null');
        print('[Google Sign-In] This usually means:');
        print(
          '[Google Sign-In] 1. App status is "Testing" but test user not added',
        );
        print(
          '[Google Sign-In] 2. Android OAuth client not configured correctly',
        );
        print('[Google Sign-In] 3. Package name or SHA-1 mismatch');
        // Provide more detailed error message
        return 'Failed to get Google authentication token. Please ensure:\n'
            '1. Android OAuth client is created in Google Cloud Console\n'
            '2. Package name matches: com.navistfind.app\n'
            '3. SHA-1 fingerprint is configured correctly\n'
            '4. If app status is "Testing", your email is added as a test user\n'
            '5. OAuth consent screen is configured';
      }

      print('[Google Sign-In] ID token retrieved successfully');
      print(
        '[Google Sign-In] Sending token to backend: ${Constants.backendBaseUrl}/api/auth/google',
      );

      // Send ID token to backend
      try {
        print('[Google Sign-In] Posting to backend API...');
        final response = await ApiClient.client.post(
          '/api/auth/google',
          data: {'id_token': idToken},
        );

        print(
          '[Google Sign-In] Backend response status: ${response.statusCode}',
        );

        if (response.statusCode == 200) {
          print('[Google Sign-In] Backend authentication successful');
          final token = response.data['access_token'];
          if (token != null) {
            print('[Google Sign-In] Storing authentication token...');
            await SecureStorage.storeToken(token);
            print('[Google Sign-In] ✅ Google Sign-In completed successfully');
            return null; // Success
          } else {
            print('[Google Sign-In] ERROR: Token not found in response');
            print('[Google Sign-In] Response data: ${response.data}');
            return 'Token not found in response';
          }
        } else {
          print(
            '[Google Sign-In] ERROR: Backend returned status ${response.statusCode}',
          );
          print('[Google Sign-In] Response data: ${response.data}');
          return response.data['message'] ?? 'Google sign-in failed';
        }
      } catch (e) {
        print('[Google Sign-In] ERROR sending to backend: $e');
        rethrow;
      }
    } on DioException catch (e) {
      print('[Google Sign-In] DioException caught: ${e.type}');
      print('[Google Sign-In] Error message: ${e.message}');
      final errorResponse = e.response;
      if (errorResponse != null) {
        print('[Google Sign-In] Response status: ${errorResponse.statusCode}');
        print('[Google Sign-In] Response data: ${errorResponse.data}');
        if (errorResponse.data != null) {
          if (errorResponse.data is Map) {
            final data = errorResponse.data as Map;
            if (data['message'] is String) {
              return data['message'] as String;
            }
          }
        }
      }
      // Network errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        print('[Google Sign-In] Network error: Cannot connect to server');
        return 'Cannot connect to server. Please check your connection and ensure the server is running at ${Constants.backendBaseUrl}';
      }
      return 'Google sign-in failed: ${e.message ?? 'Network error'}';
    } catch (e) {
      print('[Google Sign-In] General exception: $e');
      print('[Google Sign-In] Stack trace: ${StackTrace.current}');
      return 'Error: ${e.toString()}';
    }
  }
}
