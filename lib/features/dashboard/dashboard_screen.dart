import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/action_card.dart';
import '../../shared/widgets/project_list_tile.dart';
import '../profile/profile_provider.dart';
import '../notifications/notifications_provider.dart';
import '../projects/providers/project_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    if (hour < 21) return "Good Evening,";
    return "Good Night,";
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Unknown date";
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) hour = 12;
      if (hour > 12) hour -= 12;
      return "$month $day, $hour:$minute $ampm";
    } catch (e) {
      return "Unknown date";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final user = profileState.profile;

    final projectListAsync = ref.watch(projectListProvider);

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
                    Consumer(
                      builder: (context, ref, child) {
                        final unreadCount = ref
                            .watch(notificationsControllerProvider)
                            .unreadCount;
                        return IconButton(
                          icon: Badge(
                            isLabelVisible: unreadCount > 0,
                            backgroundColor: AppColors.accent,
                            child: const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => context.push('/notifications'),
                        );
                      },
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
                  onTap: () => context.push('/upload?type=audio_enhancement'),
                ),
                ActionCard(
                  title: "Enhance\nVideo",
                  icon: Icons.video_settings,
                  onTap: () => context.push('/upload?type=video_enhancement'),
                ),
                ActionCard(
                  title: "Replace\nAudio",
                  icon: Icons.mic_external_on,
                  onTap: () => context.push('/upload/replace-audio'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Projects Header
            const Text(
              "Recent Projects",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Recent Projects List
            projectListAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  "Error: $err",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (projects) {
                final recentCompleted = projects
                    .where((p) => p['status'] == 'completed')
                    .take(5)
                    .toList();

                if (recentCompleted.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      "No recent completed projects.",
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  );
                }

                return Column(
                  children: recentCompleted.map((project) {
                    final format =
                        project['media_file']?['format']
                            ?.toString()
                            .toLowerCase() ??
                        'mp4';
                    final isVideo = [
                      'mp4',
                      'mov',
                      'avi',
                      'mkv',
                    ].contains(format);
                    final projectName =
                        project['project_name'] ?? 'Untitled Project';

                    return GestureDetector(
                      onTap: () {
                        context.push('/project/${project['id']}');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ProjectListTile(
                          projectName: projectName,
                          status: "Completed",
                          date: _formatDate(project['created_at']),
                          typeIcon: isVideo
                              ? Icons.video_file
                              : Icons.audio_file,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
