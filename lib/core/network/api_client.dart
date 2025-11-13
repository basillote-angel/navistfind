import 'package:navistfind/core/constants.dart';
import 'package:navistfind/core/secure_storage.dart';
import 'package:dio/dio.dart';

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
          print(
            '[API Client] Request: ${options.method} ${options.baseUrl}${options.path}',
          );
          print('[API Client] Headers: ${options.headers}');
          print('[API Client] Data: ${options.data}');

          final token = await SecureStorage.getToken();
          print('[API Client] Token: ${token != null ? "exists" : "null"}');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options); // Continue with the request
        },
        onResponse: (response, handler) {
          print(
            '[API Client] Response: ${response.statusCode} ${response.statusMessage}',
          );
          print('[API Client] Response data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('[API Client] Error: ${error.type}');
          print('[API Client] Error message: ${error.message}');
          if (error.response != null) {
            print('[API Client] Error response: ${error.response?.statusCode}');
            print('[API Client] Error response data: ${error.response?.data}');
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
