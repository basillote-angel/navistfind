import 'package:navistfind/core/constants.dart';
import 'package:navistfind/core/secure_storage.dart';
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(baseUrl: Constants.baseUrl))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        print("Adding token to request: $token");

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options); // Continue with the request
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
    ));

  static Dio get client => _dio;
}
