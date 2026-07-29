import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/notification_tile.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  NotificationType _getNotificationType(String title, String message) {
    final combined = '$title $message'.toLowerCase();
    if (combined.contains('failed') || combined.contains('error'))
      return NotificationType.warning;
    if (combined.contains('success') || combined.contains('completed'))
      return NotificationType.success;
    return NotificationType.info;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cards,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref
                    .read(notificationsControllerProvider.notifier)
                    .markAllAsRead();
              },
              child: const Text(
                "Mark all read",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
      // Pull-to-refresh logic
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cards,
        onRefresh: () async {
          await ref
              .read(notificationsControllerProvider.notifier)
              .loadNotifications(forceRefresh: true);
        },
        child: state.isLoading && state.notifications.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  if (state.unread.isEmpty && state.read.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Text(
                          "You have no notifications.",
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                    ),

                  // RECENT / UNREAD NOTIFICATIONS
                  if (state.unread.isNotEmpty) ...[
                    const Text(
                      "Recent",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.unread.map(
                      (notif) => NotificationTile(
                        title: notif.title,
                        message: notif.message,
                        time: _getTimeAgo(notif.createdAt),
                        type: _getNotificationType(notif.title, notif.message),
                        isUnread: true,
                        onTap: () {
                          ref
                              .read(notificationsControllerProvider.notifier)
                              .markAsRead(notif.id);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // EARLIER / READ NOTIFICATIONS
                  if (state.read.isNotEmpty) ...[
                    const Text(
                      "Earlier",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.read.map(
                      (notif) => NotificationTile(
                        title: notif.title,
                        message: notif.message,
                        time: _getTimeAgo(notif.createdAt),
                        type: _getNotificationType(notif.title, notif.message),
                        isUnread: false,
                        onTap: () {
                          // Do nothing, already read
                        },
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
