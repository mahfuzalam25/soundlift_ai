import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/setting_toggle_tile.dart';
import '../../shared/widgets/setting_dropdown_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for settings
  String _appearance = 'System';
  String _language = 'English';
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _autoSave = true;
  String _defaultQuality = 'Full HD';

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
          "Settings",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance & Language Group
            const Text("Preferences", style: TextStyle(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                SettingDropdownTile(
                  title: "Appearance",
                  icon: Icons.palette_outlined,
                  currentValue: _appearance,
                  options: const ['Dark Mode', 'Light Mode', 'System'],
                  onChanged: (val) => setState(() => _appearance = val!),
                ),
                _buildDivider(),
                SettingDropdownTile(
                  title: "Language",
                  icon: Icons.language,
                  currentValue: _language,
                  options: const ['English', 'বাংলা', 'Arabic', 'Spanish'],
                  onChanged: (val) => setState(() => _language = val!),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Notifications Group
            const Text("Notifications", style: TextStyle(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildSettingsCard(
              children: [
                SettingToggleTile(
                  title: "Email Notifications",
                  icon: Icons.email_outlined,
                  value: _emailNotifications,
                  onChanged: (val) => setState(() => _emailNotifications = val),
                ),
                _buildDivider(),
                SettingToggleTile(
                  title: "Push Notifications",
                  icon: Icons.notifications_active_outlined,
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Download Settings Group
            const Text("Download & Export", style: TextStyle(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w600)),
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
      child: Column(
        children: children,
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