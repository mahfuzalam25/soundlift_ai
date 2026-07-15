import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SettingDropdownTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String currentValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const SettingDropdownTile({
    super.key,
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: DropdownButton<String>(
        value: currentValue,
        dropdownColor: AppColors.cards,
        borderRadius: BorderRadius.circular(12),
        underline: const SizedBox(),
        icon: const Icon(Icons.unfold_more, color: AppColors.textGrey, size: 20),
        style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}