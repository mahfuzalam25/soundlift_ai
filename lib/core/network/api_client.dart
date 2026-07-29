import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_router.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8001',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final publicEndpoints = [
          '/api/accounts/login/',
          '/api/accounts/register/',
          '/api/accounts/verify-otp/',
          '/api/accounts/verify-2fa/',
          '/api/accounts/google/',
          '/api/accounts/token/refresh/',
        ];

        final isPublicEndpoint = publicEndpoints.any(
          (endpoint) => options.path.contains(endpoint),
        );

        if (!isPublicEndpoint) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        return handler.next(options);
      },

      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');

          // If there is no refresh token at all, force logout immediately
          if (refreshToken == null) {
            if (rootNavigatorKey.currentContext != null) {
              GoRouter.of(rootNavigatorKey.currentContext!).go('/auth/login');
            }
            return handler.next(e);
          }

          try {
            final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));

            final response = await refreshDio.post(
              '/api/accounts/token/refresh/',
              data: {'refresh': refreshToken},
            );

            final newAccessToken = response.data['access'];
            final newRefreshToken = response.data['refresh'] ?? refreshToken;

            await prefs.setString('access_token', newAccessToken);
            await prefs.setString('refresh_token', newRefreshToken);

            e.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(e.requestOptions);
            return handler.resolve(retryResponse);
          } catch (refreshError) {
            // NEW: If the 7-day refresh token fails, clear data and kick them out!
            await prefs.remove('access_token');
            await prefs.remove('refresh_token');

            if (rootNavigatorKey.currentContext != null) {
              GoRouter.of(rootNavigatorKey.currentContext!).go('/auth/login');
            }
          }
        }

        return handler.next(e);
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true, error: true),
  );

  return dio;
});
