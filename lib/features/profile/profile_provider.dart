import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class UserProfile {
  final String name;
  final String email;
  final String? profilePicture;
  final String bio;
  final String country;
  final String timezone;
  final bool is2faEnabled;
  final bool isGoogleAuth;

  final int totalProjects;
  final double totalMinutesUsed;
  final int totalStorageUsed;

  final bool pushNotifications;
  final bool emailNotifications;

  UserProfile({
    required this.name,
    required this.email,
    this.profilePicture,
    required this.bio,
    required this.country,
    required this.timezone,
    this.is2faEnabled = false,
    this.isGoogleAuth = false,
    this.totalProjects = 0,
    this.totalMinutesUsed = 0.0,
    this.totalStorageUsed = 0,
    this.pushNotifications = false,
    this.emailNotifications = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      profilePicture: json['profile_picture'],
      bio: json['bio'] ?? '',
      country: json['country'] ?? '',
      timezone: json['timezone'] ?? '',
      is2faEnabled: json['is_2fa_enabled'] ?? false,
      isGoogleAuth: json['is_google_auth'] ?? false,
      totalProjects: json['total_projects'] ?? 0,
      totalMinutesUsed: (json['total_minutes_used'] ?? 0).toDouble(),
      totalStorageUsed: json['total_storage_used'] ?? 0,
      pushNotifications: json['push_notifications'] ?? false,
      emailNotifications: json['email_notifications'] ?? false,
    );
  }
}

class ProfileState {
  final bool isLoading;
  final UserProfile? profile;
  final String? error;

  ProfileState({this.isLoading = false, this.profile, this.error});

  ProfileState copyWith({
    bool? isLoading,
    UserProfile? profile,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

// Repository
class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  Future<UserProfile> fetchProfile() async {
    final response = await _dio.get('/api/accounts/profile/');
    return UserProfile.fromJson(response.data);
  }

  Future<UserProfile> updateProfile(FormData data) async {
    final response = await _dio.patch('/api/accounts/profile/', data: data);
    return UserProfile.fromJson(response.data);
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    await _dio.patch('/api/accounts/profile/', data: data);
  }

  Future<void> toggle2FA(bool isEnabled) async {
    await _dio.patch(
      '/api/accounts/toggle-2fa/',
      data: {"is_2fa_enabled": isEnabled},
    );
  }
}

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

// Controller
class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileController(this._repository) : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && state.profile != null) return;

    if (state.profile == null) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final profile = await _repository.fetchProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      String errorMessage = "Failed to load profile";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message'] ?? e.message ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<bool> updateProfile({
    required String bio,
    required String country,
    required String timezone,
    String? profilePicturePath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final Map<String, dynamic> dataMap = {
        "bio": bio,
        "country": country,
        "timezone": timezone,
      };

      if (profilePicturePath != null) {
        dataMap["profile_picture"] = await MultipartFile.fromFile(
          profilePicturePath,
        );
      }

      final formData = FormData.fromMap(dataMap);
      await _repository.updateProfile(formData);

      await loadProfile(forceRefresh: true);
      return true;
    } catch (e) {
      String errorMessage = "Failed to update profile";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> updateNotificationPreferences(bool push, bool email) async {
    final previousProfile = state.profile;

    if (previousProfile != null) {
      state = state.copyWith(
        profile: UserProfile(
          name: previousProfile.name,
          email: previousProfile.email,
          profilePicture: previousProfile.profilePicture,
          bio: previousProfile.bio,
          country: previousProfile.country,
          timezone: previousProfile.timezone,
          isGoogleAuth: previousProfile.isGoogleAuth,
          totalProjects: previousProfile.totalProjects,
          totalMinutesUsed: previousProfile.totalMinutesUsed,
          totalStorageUsed: previousProfile.totalStorageUsed,
          is2faEnabled: previousProfile.is2faEnabled,
          pushNotifications: push, 
          emailNotifications: email,
        ),
      );
    }

    try {
      await _repository.updatePreferences({
        "push_notifications": push,
        "email_notifications": email,
      });

      await loadProfile(forceRefresh: true);
      return true;
    } catch (e) {
      if (previousProfile != null) {
        state = state.copyWith(profile: previousProfile);
      }
      String errorMessage = "Failed to update notifications";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            errorMessage;
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> toggle2FA(bool isEnabled) async {
    final previousProfile = state.profile;

    if (previousProfile != null) {
      state = state.copyWith(
        profile: UserProfile(
          name: previousProfile.name,
          email: previousProfile.email,
          profilePicture: previousProfile.profilePicture,
          bio: previousProfile.bio,
          country: previousProfile.country,
          timezone: previousProfile.timezone,
          isGoogleAuth: previousProfile.isGoogleAuth,
          totalProjects: previousProfile.totalProjects,
          totalMinutesUsed: previousProfile.totalMinutesUsed,
          totalStorageUsed: previousProfile.totalStorageUsed,
          pushNotifications: previousProfile.pushNotifications,
          emailNotifications: previousProfile.emailNotifications,
          is2faEnabled: isEnabled,
        ),
      );
    }

    try {
      await _repository.toggle2FA(isEnabled);
      await loadProfile(forceRefresh: true);
      return true;
    } catch (e) {
      if (previousProfile != null) {
        state = state.copyWith(profile: previousProfile);
      }
      String errorMessage = "Failed to update 2FA status";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            errorMessage;
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  void clearProfile() {
    state = ProfileState();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(ref.watch(profileRepositoryProvider));
    });
