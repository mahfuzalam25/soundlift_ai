import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/setting_toggle_tile.dart';
import '../../shared/widgets/setting_dropdown_tile.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import '../profile/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appearance = 'System';
  String _language = 'English';
  bool _autoSave = true;
  String _defaultQuality = 'Full HD';

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    final pushEnabled = profile?.pushNotifications ?? false;
    final emailEnabled = profile?.emailNotifications ?? false;

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
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Preferences",
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                SettingDropdownTile(
                  title: "Appearance",
                  icon: Icons.palette_outlined,
                  currentValue: _appearance,
                  options: const ['System', 'Dark', 'Light'],
                  onChanged: (val) => setState(() => _appearance = val!),
                ),
                _buildDivider(),
                SettingDropdownTile(
                  title: "Language",
                  icon: Icons.language,
                  currentValue: _language,
                  options: const ['English', 'Spanish', 'French', 'Bengali'],
                  onChanged: (val) => setState(() => _language = val!),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              "Notifications",
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                SettingToggleTile(
                  title: "Push Notifications",
                  icon: Icons.notifications_active_outlined,
                  value: pushEnabled,
                  onChanged: (val) async {
                    final success = await ref
                        .read(profileControllerProvider.notifier)
                        .updateNotificationPreferences(val, emailEnabled);
                    if (mounted && !success) {
                      final error = ref.read(profileControllerProvider).error;
                      CustomSnackbar.show(
                        context: context,
                        message: error ?? "Failed to update",
                        isError: true,
                      );
                    }
                  },
                ),
                _buildDivider(),
                SettingToggleTile(
                  title: "Email Updates",
                  icon: Icons.email_outlined,
                  value: emailEnabled,
                  onChanged: (val) async {
                    final success = await ref
                        .read(profileControllerProvider.notifier)
                        .updateNotificationPreferences(pushEnabled, val);
                    if (mounted && !success) {
                      final error = ref.read(profileControllerProvider).error;
                      CustomSnackbar.show(
                        context: context,
                        message: error ?? "Failed to update",
                        isError: true,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              "Processing & Export",
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                SettingToggleTile(
                  title: "Auto Save to Device",
                  icon: Icons.save_alt,
                  value: _autoSave,
                  onChanged: (val) => setState(() => _autoSave = val),
                ),
                _buildDivider(),
                SettingDropdownTile(
                  title: "Default Quality",
                  icon: Icons.high_quality,
                  currentValue: _defaultQuality,
                  options: const ['Standard', 'HD', 'Full HD', '4K'],
                  onChanged: (val) => setState(() => _defaultQuality = val!),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Divider(color: AppColors.textGrey.withOpacity(0.1), height: 1),
    );
  }
}
