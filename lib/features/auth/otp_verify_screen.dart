import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'auth_provider.dart';
import '../profile/profile_provider.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String flow;
  const OtpVerifyScreen({super.key, required this.flow});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpController = TextEditingController();

  void _handleVerify() async {
    final is2FA = widget.flow == '2fa';

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(
          _otpController.text.trim(),
          is2FA: is2FA,
        );

    if (success && mounted) {
      if (widget.flow == 'reset') {
        CustomSnackbar.show(context: context, message: "OTP verified!");
        context.push('/auth/new-password');
      } else {
        ref.invalidate(profileControllerProvider);
        CustomSnackbar.show(
          context: context,
          message: is2FA ? "Login Successful!" : "Email verified successfully!",
        );
        context.go('/dashboard');
      }
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error;
      CustomSnackbar.show(
        context: context,
        message: error ?? "Verification failed",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final email =
        authState.pendingEmail ?? "your email";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Verify OTP",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter the 6-digit code sent to $email.",
              style: const TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              hintText: "OTP Code",
              controller: _otpController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              text: "Verify",
              isLoading: authState.isLoading,
              onPressed: authState.isLoading ? () {} : _handleVerify,
            ),
          ],
        ),
      ),
    );
  }
}
