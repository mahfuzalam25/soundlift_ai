import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8001',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptor to attach JWT Token smartly
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 1. Define public endpoints that NEVER need an access token attached
        final publicEndpoints = [
          '/api/accounts/login/',
          '/api/accounts/register/',
          '/api/accounts/verify-otp/',
          '/api/accounts/verify-2fa/',
          '/api/accounts/google/',
        ];

        // 2. Check if the current request is for a public endpoint
        final isPublicEndpoint = publicEndpoints.any(
          (endpoint) => options.path.contains(endpoint),
        );

        // 3. Only attach the token if it is NOT a public endpoint
        if (!isPublicEndpoint) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        return handler.next(options);
      },
    ),
  );

  // Logs requests and responses to the console for easy debugging
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true, error: true),
  );

  return dio;
});
