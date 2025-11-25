import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:navistfind/core/constants.dart';
import 'package:navistfind/core/secure_storage.dart';

class ApiClient {
  static Dio _createClient(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kDebugMode) {
            debugPrint(
              '[API] ${options.method} ${options.baseUrl}${options.path}',
            );
          }

          final token = await SecureStorage.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // If FormData is being sent, Dio will automatically set Content-Type to multipart/form-data
          // Remove the default application/json header to let Dio handle it
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }

          handler.next(options); // Continue with the request
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API] ${response.statusCode} ${response.requestOptions.path}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('[API][Error] ${error.type} ${error.message}');
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static final Dio backend = _createClient(Constants.backendBaseUrl);
  static final Dio fastApi = _createClient(Constants.apiBaseUrl);

  /// Default client targeting the Laravel backend.
  static Dio get client => backend;
}
