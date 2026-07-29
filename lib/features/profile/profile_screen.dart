import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/profile_menu_tile.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import '../auth/auth_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    CustomSnackbar.show(context: context, message: "Logging out...");

    await ref.read(authControllerProvider.notifier).logout();

    ref.read(profileControllerProvider.notifier).clearProfile();

    if (context.mounted) {
      context.go('/auth/login');
    }
  }

  // Byte formatter
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 MB";
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (bytes >= gb) {
      return "${(bytes / gb).toStringAsFixed(1)} GB";
    } else {
      return "${(bytes / mb).toStringAsFixed(1)} MB";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final user = profileState.profile;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // User Information
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.cards,
                      backgroundImage: user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!)
                          : null,
                      child: user?.profilePicture == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  profileState.isLoading && user == null
                      ? const CircularProgressIndicator()
                      : Text(
                          user?.name ?? "Unknown User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                  const SizedBox(height: 4),

                  // Bio
                  Text(
                    user != null && user.bio.isNotEmpty
                        ? user.bio
                        : "No bio added yet",
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${user?.currentPlan ?? 'Free'} Plan",
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Projects",
                      user?.totalProjects.toString() ?? "0",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Minutes",
                      user?.totalMinutesUsed
                              .toStringAsFixed(1)
                              .replaceAll(RegExp(r'\.0$'), '') ??
                          "0",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Storage",
                      user != null
                          ? _formatBytes(user.totalStorageUsed)
                          : "0 MB",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Access Menu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ProfileMenuTile(
                    title: "Edit Profile",
                    icon: Icons.person_outline,
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _buildDivider(),
                  ProfileMenuTile(
                    title: "Subscription",
                    icon: Icons.star_outline,
                    onTap: () => context.push('/subscription/billing'),
                  ),
                  _buildDivider(),
                  ProfileMenuTile(
                    title: "Account Security",
                    icon: Icons.shield_outlined,
                    onTap: () => context.push('/profile/security'),
                  ),
                  _buildDivider(),
                  ProfileMenuTile(
                    title: "Settings",
                    icon: Icons.settings_outlined,
                    onTap: () => context.push('/settings'),
                  ),
                  _buildDivider(),
                  ProfileMenuTile(
                    title: "Support",
                    icon: Icons.help_outline,
                    onTap: () => context.push('/help'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ProfileMenuTile(
                    title: "Logout",
                    icon: Icons.logout,
                    isDestructive: true,
                    onTap: () => _handleLogout(context, ref),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Divider(color: AppColors.textGrey.withOpacity(0.1), height: 1),
    );
  }
}
