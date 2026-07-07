import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/settings_tile.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'profile_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

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
          "Account Security",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Settings Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Account Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  SettingsTile(
                    title: "Email Verification",
                    subtitle: profile?.email ?? "Loading...",
                    icon: Icons.mark_email_read_outlined,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Verified",
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Hide Password Change if logged in exclusively with Google
                  if (!(profile?.isGoogleAuth ?? false)) ...[
                    _buildDivider(),
                    SettingsTile(
                      title: "Change Password",
                      subtitle: "Update your security credentials",
                      icon: Icons.lock_outline,
                      onTap: () => context.push('/profile/change-password'),
                    ),
                  ],

                  // Conditional Google Connected Toggle
                  if (profile?.isGoogleAuth == true) ...[
                    _buildDivider(),
                    SettingsTile(
                      title: "Google Connected",
                      icon: Icons.g_mobiledata,
                      trailing: Switch(
                        value: true,
                        onChanged: null,
                        activeColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Security Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Advanced Security",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  SettingsTile(
                    title: "Two-Factor Authentication",
                    subtitle: "Secure your account with 2FA",
                    icon: Icons.security,
                    trailing: Switch(
                      value: profile?.is2faEnabled ?? false,
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.5),
                      inactiveThumbColor: AppColors.textGrey,
                      inactiveTrackColor: AppColors.background,
                      onChanged: (val) async {
                        final success = await ref
                            .read(profileControllerProvider.notifier)
                            .toggle2FA(val);
                        if (mounted) {
                          if (success) {
                            CustomSnackbar.show(
                              context: context,
                              message: val
                                  ? "2FA Enabled successfully"
                                  : "2FA Disabled successfully",
                            );
                          } else {
                            final error = ref
                                .read(profileControllerProvider)
                                .error;
                            CustomSnackbar.show(
                              context: context,
                              message: error ?? "Failed to update 2FA",
                              isError: true,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    title: "Active Sessions",
                    subtitle: "Manage devices logged into your account",
                    icon: Icons.devices,
                    onTap: () => context.push('/profile/sessions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
