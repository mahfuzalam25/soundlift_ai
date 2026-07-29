import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'security_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Please fill in all fields",
        isError: true,
      );
      return;
    }

    if (newPass != confirmPass) {
      CustomSnackbar.show(
        context: context,
        message: "New passwords do not match",
        isError: true,
      );
      return;
    }

    final success = await ref
        .read(changePasswordControllerProvider.notifier)
        .changePassword(oldPass, newPass, confirmPass);

    if (success && mounted) {
      CustomSnackbar.show(
        context: context,
        message: "Password changed successfully!",
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(changePasswordControllerProvider).error;
      CustomSnackbar.show(
        context: context,
        message: error ?? "An error occurred",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final passState = ref.watch(changePasswordControllerProvider);

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
          "Change Password",
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
              "Update your password",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Ensure your account stays secure by using a strong password.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            CustomTextField(
              hintText: "Current Password",
              controller: _oldPasswordController,
              isPassword: true,
            ),
            CustomTextField(
              hintText: "New Password",
              controller: _newPasswordController,
              isPassword: true,
            ),
            CustomTextField(
              hintText: "Confirm New Password",
              controller: _confirmPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              text: "Update Password",
              isLoading: passState.isLoading,
              onPressed: passState.isLoading ? () {} : _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
