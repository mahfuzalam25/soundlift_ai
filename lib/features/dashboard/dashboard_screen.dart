import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/action_card.dart';
import '../../shared/widgets/project_list_tile.dart';
import '../profile/profile_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    if (hour < 21) return "Good Evening,";
    return "Good Night,";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final user = profileState.profile;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    profileState.isLoading && user == null
                        ? Container(
                            height: 20,
                            width: 150,
                            color: AppColors.cards,
                          )
                        : Text(
                            user?.name ?? "Guest User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
                // Notification Bell & Avatar
                Row(
                  children: [
                    IconButton(
                      icon: const Badge(
                        backgroundColor: AppColors.accent,
                        child: Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.cards,
                      backgroundImage: user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!)
                          : null,
                      child: user?.profilePicture == null
                          ? const Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Credit/Plan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Current Plan",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        "Pro Tier",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "124 / 500",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Minutes Remaining",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 124 / 500,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Renews on Dec 12, 2026",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              "Quick Actions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                ActionCard(
                  title: "Enhance\nAudio",
                  icon: Icons.multitrack_audio,
                  onTap: () {},
                ),
                ActionCard(
                  title: "Enhance\nVideo",
                  icon: Icons.video_settings,
                  onTap: () {},
                ),
                ActionCard(
                  title: "Replace\nAudio",
                  icon: Icons.mic_external_on,
                  onTap: () {},
                ),
                ActionCard(
                  title: "View\nProjects",
                  icon: Icons.folder_special,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Projects
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Projects",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {}, // Will link to Projects tab
                  child: const Text(
                    "See All",
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ProjectListTile(
              projectName: "Podcast_Ep4_Raw.wav",
              status: "Processing",
              date: "Today, 10:30 AM",
              typeIcon: Icons.audio_file,
            ),
            const ProjectListTile(
              projectName: "Vlog_Windy_Day.mp4",
              status: "Completed",
              date: "Yesterday, 04:15 PM",
              typeIcon: Icons.video_file,
            ),
            const ProjectListTile(
              projectName: "Interview_Backup.mp3",
              status: "Completed",
              date: "Oct 12, 09:00 AM",
              typeIcon: Icons.audio_file,
            ),
          ],
        ),
      ),
    );
  }
}
