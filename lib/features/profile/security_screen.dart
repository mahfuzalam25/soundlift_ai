import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/settings_tile.dart';
import '../../shared/dialogs/custom_snackbar.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isGoogleConnected = true;
  bool _is2FAEnabled = false;

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
          "Account Security",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
              child: Text("Account Settings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    subtitle: "hello@meetsfixer.com",
                    icon: Icons.mark_email_read_outlined,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Verified", style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    title: "Change Password",
                    subtitle: "Last changed 3 months ago",
                    icon: Icons.lock_outline,
                    onTap: () {
                      CustomSnackbar.show(context: context, message: "Navigate to Password Change");
                    },
                  ),
                  _buildDivider(),
                  SettingsTile(
                    title: "Google Connected",
                    icon: Icons.g_mobiledata,
                    trailing: Switch(
                      value: _isGoogleConnected,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isGoogleConnected = val;
                        });
                        CustomSnackbar.show(context: context, message: val ? "Google account linked" : "Google account unlinked");
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Security Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text("Advanced Security", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      value: _is2FAEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _is2FAEnabled = val;
                        });
                        CustomSnackbar.show(context: context, message: val ? "2FA Enabled" : "2FA Disabled");
                      },
                    ),
                  ),
                  _buildDivider(),
                  SettingsTile(
                    title: "Active Sessions",
                    subtitle: "Manage devices logged into your account",
                    icon: Icons.devices,
                    onTap: () {
                      CustomSnackbar.show(context: context, message: "Navigate to Active Sessions");
                    },
                  ),
                  _buildDivider(),
                  SettingsTile(
                    title: "Login History",
                    subtitle: "Review your recent sign-ins",
                    icon: Icons.history,
                    onTap: () {
                      CustomSnackbar.show(context: context, message: "Navigate to Login History");
                    },
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