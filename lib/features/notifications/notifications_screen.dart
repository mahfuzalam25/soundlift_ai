import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Logic to mark all as read
            },
            child: const Text("Mark all read", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            "Recent",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          NotificationTile(
            title: "Project Completed",
            message: "Your video 'Vlog_Windy_Day.mp4' has been successfully enhanced and is ready to download.",
            time: "2m ago",
            type: NotificationType.success,
            isUnread: true,
            onTap: () {},
          ),
          NotificationTile(
            title: "Payment Success",
            message: "Your payment of \$19.99 for the Pro Tier was successful. Thank you for your purchase.",
            time: "1h ago",
            type: NotificationType.success,
            isUnread: true,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            "Earlier",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          NotificationTile(
            title: "Subscription Renewal",
            message: "Your Pro Tier subscription will automatically renew on Dec 12, 2026.",
            time: "2d ago",
            type: NotificationType.info,
            isUnread: false,
            onTap: () {},
          ),
          NotificationTile(
            title: "System Update",
            message: "We have added new AI models for faster audio processing. Check out the create tab!",
            time: "5d ago",
            type: NotificationType.info,
            isUnread: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}