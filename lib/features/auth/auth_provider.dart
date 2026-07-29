import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/network/api_client.dart';

enum LoginResult { success, requires2FA, error }

class AuthState {
  final bool isLoading;
  final String? error;
  final String? pendingEmail;

  AuthState({this.isLoading = false, this.error, this.pendingEmail});

  AuthState copyWith({bool? isLoading, String? error, String? pendingEmail}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingEmail: pendingEmail ?? this.pendingEmail,
    );
  }
}

// Repository
class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<String> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/accounts/register/', data: data);
    return response.data['message'] ?? "Registration successful";
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await _dio.post(
      '/api/accounts/verify-otp/',
      data: {"email": email, "otp": otp},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/api/accounts/login/',
      data: {"email": email, "password": password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verify2fa(String email, String otp) async {
    final response = await _dio.post(
      '/api/accounts/verify-2fa/',
      data: {"email": email, "otp": otp},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> googleAuth(String idToken) async {
    final response = await _dio.post(
      '/api/accounts/google/',
      data: {"id_token": idToken},
    );
    return response.data;
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post('/api/accounts/logout/', data: {"refresh": refreshToken});
  }
}

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

// Controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthState());

  String _extractError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        return error.response?.data['message'] ??
            error.response?.data['error'] ??
            "An API error occurred.";
      }
      return error.message ?? "A network error occurred.";
    }
    return error.toString();
  }

  Future<void> _saveTokens(Map<String, dynamic> responseData) async {
    if (responseData['tokens'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', responseData['tokens']['access']);
      await prefs.setString('refresh_token', responseData['tokens']['refresh']);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register({
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "confirm_password": confirmPassword,
      });
      state = state.copyWith(isLoading: false, pendingEmail: email);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> verifyOtp(String otp, {bool is2FA = false}) async {
    if (state.pendingEmail == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = is2FA
          ? await _repository.verify2fa(state.pendingEmail!, otp)
          : await _repository.verifyOtp(state.pendingEmail!, otp);

      await _saveTokens(response);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<LoginResult> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(email, password);

      if (response['requires_2fa'] == true) {
        state = state.copyWith(isLoading: false, pendingEmail: email);
        return LoginResult.requires2FA;
      }

      await _saveTokens(response);
      state = state.copyWith(isLoading: false);
      return LoginResult.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return LoginResult.error;
    }
  }

  Future<bool> handleGoogleAuth() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      await signIn.initialize(serverClientId: dotenv.env['GOOGLE_CLIENT_ID']);

      final GoogleSignInAccount account = await signIn.authenticate();

      final GoogleSignInAuthentication auth = await account.authentication;

      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception("Failed to retrieve Google ID Token.");
      }

      final response = await _repository.googleAuth(idToken);

      await _saveTokens(response);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken != null) {
        await _repository.logout(refreshToken);
      }

      await prefs.remove('access_token');
      await prefs.remove('refresh_token');

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');

      state = state.copyWith(isLoading: false, error: _extractError(e));
      return true;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);
