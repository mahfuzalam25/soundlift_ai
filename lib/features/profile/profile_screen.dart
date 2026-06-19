import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/profile_menu_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // 1. User Information Area
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.cards,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Md Mahfuz Alam Chowdhury",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "hello@meetsfixer.com",
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
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
                    child: const Text(
                      "Pro Plan",
                      style: TextStyle(
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

            // 2. Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard("Projects", "12")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard("Minutes", "124")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard("Storage", "4.2 GB")),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Quick Access Menu
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
                    title: "Security",
                    icon: Icons.shield_outlined,
                    onTap: () => context.push('/profile/security'),
                  ),

                  _buildDivider(),
                  ProfileMenuTile(
                    title: "Billing & Invoices",
                    icon: Icons.receipt_long,
                    onTap: () => context.push('/subscription/billing'),
                  ),
                  _buildDivider(),
                  ProfileMenuTile(
                    title: "Settings",
                    icon: Icons.settings_outlined,
                    onTap: () => context.push('/settings'), // Placeholder route
                  ),
                  _buildDivider(),
                  ProfileMenuTile(
                    title: "Support",
                    icon: Icons.help_outline,
                    onTap: () => context.push('/help'), // Placeholder route
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Logout Button (Separated for emphasis)
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
                    onTap: () {
                      // Clears session and routes back to login
                      context.go('/auth/login');
                    },
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

  // Helper widget for the three stat boxes
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

  // Helper widget for subtle dividers between list items
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Divider(color: AppColors.textGrey.withOpacity(0.1), height: 1),
    );
  }
}
