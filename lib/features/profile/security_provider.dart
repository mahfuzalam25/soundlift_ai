import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class LoginSession {
  final int id;
  final String ipAddress;
  final String userAgent;
  final DateTime loginDatetime;
  final bool isActive;

  LoginSession({
    required this.id,
    required this.ipAddress,
    required this.userAgent,
    required this.loginDatetime,
    required this.isActive,
  });

  factory LoginSession.fromJson(Map<String, dynamic> json) {
    return LoginSession(
      id: json['id'],
      ipAddress: json['ip_address'] ?? 'Unknown IP',
      userAgent: json['user_agent'] ?? 'Unknown Device',
      loginDatetime: DateTime.parse(json['login_datetime']).toLocal(),
      isActive: json['is_active'] ?? false,
    );
  }
}

// Repository
class SecurityRepository {
  final Dio _dio;
  SecurityRepository(this._dio);

  Future<void> changePassword(
    String oldPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    await _dio.post(
      '/api/accounts/change-password/',
      data: {
        "old_password": oldPassword,
        "new_password": newPassword,
        "confirm_new_password": confirmNewPassword,
      },
    );
  }

  Future<List<LoginSession>> fetchSessions() async {
    final response = await _dio.get('/api/accounts/sessions/');
    return (response.data as List)
        .map((x) => LoginSession.fromJson(x))
        .toList();
  }
}

final securityRepositoryProvider = Provider(
  (ref) => SecurityRepository(ref.watch(dioProvider)),
);

// Providers

final sessionsProvider = FutureProvider.autoDispose<List<LoginSession>>((
  ref,
) async {
  return ref.watch(securityRepositoryProvider).fetchSessions();
});

class ChangePasswordState {
  final bool isLoading;
  final String? error;
  ChangePasswordState({this.isLoading = false, this.error});
}

class ChangePasswordController extends StateNotifier<ChangePasswordState> {
  final SecurityRepository _repository;

  ChangePasswordController(this._repository) : super(ChangePasswordState());

  Future<bool> changePassword(
    String old,
    String newPass,
    String confirm,
  ) async {
    state = ChangePasswordState(isLoading: true);
    try {
      await _repository.changePassword(old, newPass, confirm);
      state = ChangePasswordState(isLoading: false);
      return true;
    } catch (e) {
      String errorMessage = "Failed to change password";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            errorMessage;
      }
      state = ChangePasswordState(isLoading: false, error: errorMessage);
      return false;
    }
  }
}

final changePasswordControllerProvider =
    StateNotifierProvider<ChangePasswordController, ChangePasswordState>((ref) {
      return ChangePasswordController(ref.watch(securityRepositoryProvider));
    });
