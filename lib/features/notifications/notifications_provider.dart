import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';


class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}


class NotificationsState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final String? error;

  NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  List<NotificationModel> get unread =>
      notifications.where((n) => !n.isRead).toList();
  List<NotificationModel> get read =>
      notifications.where((n) => n.isRead).toList();
  int get unreadCount => unread.length;

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }
}

// Repository
class NotificationsRepository {
  final Dio _dio;
  NotificationsRepository(this._dio);

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _dio.get('/api/notifications/');
    return (response.data as List)
        .map((x) => NotificationModel.fromJson(x))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('/api/notifications/$id/');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/api/notifications/mark-all-read/');
  }
}

final notificationsRepositoryProvider = Provider(
  (ref) => NotificationsRepository(ref.watch(dioProvider)),
);

// Controller
class NotificationsController extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;
  Timer? _pollingTimer;

  NotificationsController(this._repository) : super(NotificationsState()) {
    loadNotifications();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _silentFetch();
    });
  }

  Future<void> _silentFetch() async {
    try {
      final freshNotifications = await _repository.fetchNotifications();
      state = state.copyWith(notifications: freshNotifications);
    } catch (e) {
      // Ignore errors during silent polling so we don't spam the user with snackbars
    }
  }

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh && state.notifications.isNotEmpty) return;

    if (state.notifications.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final notifications = await _repository.fetchNotifications();
      state = state.copyWith(isLoading: false, notifications: notifications);
    } catch (e) {
      String errorMessage = "Failed to load notifications";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message'] ?? e.message ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> markAsRead(String id) async {
    final idx = state.notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || state.notifications[idx].isRead) return;

    final previousNotifications = List<NotificationModel>.from(
      state.notifications,
    );
    final updatedList = List<NotificationModel>.from(state.notifications);
    updatedList[idx] = updatedList[idx].copyWith(isRead: true);

    state = state.copyWith(notifications: updatedList);

    try {
      await _repository.markAsRead(id);
    } catch (e) {
      state = state.copyWith(notifications: previousNotifications);
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;

    final previousNotifications = List<NotificationModel>.from(
      state.notifications,
    );
    final updatedList = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    state = state.copyWith(notifications: updatedList);

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      state = state.copyWith(notifications: previousNotifications);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
      return NotificationsController(
        ref.watch(notificationsRepositoryProvider),
      );
    });
